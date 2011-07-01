require "base64"
require "zlib"

module SlightAssets
  module Util
    def write_static_gzipped_file(file_path, content = nil)
      return file_path if file_path.nil? || file_path.end_with?(".gz") || ! File.exists?(file_path)
      zip_path = "#{file_path}.gz"
      return zip_path if File.exists?(zip_path)
      content = File.read(file_path) if content.nil?
      Zlib::GzipWriter.open(zip_path, Zlib::BEST_COMPRESSION) {|f| f.write(content) }
      # Set mtime to the latest of the file to allow for
      # consistent ETag without a shared filesystem.
      mt = File.mtime(file_path)
      File.utime(mt, mt, zip_path)
      zip_path
    end
    module_function :write_static_gzipped_file

    def write_static_minified_asset(file_path)
      return file_path if file_path.nil? || file_path =~ /\.min\./ || file_path !~ /\.(?:js|css)\z/ || ! File.exists?(file_path)
      min_path = file_path.gsub(/\.(js|css)\z/, '.min.\1')
      compressor = nil
      case extension = $1
      when "css"
        compressor = css_compressor
      when "js"
        compressor = js_compressor
      end
      return file_path if compressor.nil?
      content = File.read(file_path)
      c = compressor.compress(content)
      content = c if c.bytesize < content.bytesize
      content = embed_images(content, min_path) if extension == "css"
      reduced_content = content
      if extension == "js"
        reduced_content = js_reduce(content)
        reduced_content = content if reduced_content.bytesize > content.bytesize
      end
      File.open(min_path, "w") { |f| f.write(reduced_content) }
      mt = File.mtime(file_path)
      File.utime(mt, mt, min_path)
      [min_path, content]
    end
    module_function :write_static_minified_asset

    def js_reduce(content)
      unless (Cfg.js_reducer? == "rake" && is_rake?) || Cfg.js_reducer? == true
        content
      else
        JsReducer.new.compress(content)
      end
    end
    module_function :js_reduce

    def embed_images(content, file_path)
      return content if file_path =~ /\A(?:\w+:)?\/\//
      images = extract_images(content, file_path)
      file_url = asset_url(file_path)
      image_contents = {}
      multipart = ["/*\r\nContent-Type: multipart/related; boundary=\"MHTML_IMAGES\"\r\n"]
      replace_imports = Cfg.replace_css_imports?
      content = content.gsub(Cfg.url_matcher) do |url_match|
        image_path = $1
        quot = (url_match =~ /"/ ? "\"" : "")
        if image_path =~ /\A(?:[\\\/]|\w+:)/
          url_match
        elsif image_path =~ /(\.min)?\.css\z/ && replace_imports
          if $1
            url_match
          elsif File.exists?(asset_expand_path(image_path, file_path))
            "url(#{quot}#{image_path.gsub(/\.css\z/, ".min.css")}#{quot})"
          else
            url_match
          end
        else
          image_file_path = asset_expand_path(image_path, file_path)
          if (mt = image_mime_type(image_path) || file_url.nil? && font_mime_type(image_path)) &&
             (encode64 = encoded_file_contents(image_file_path, file_path))
            if image_contents[image_file_path].nil?
              part_name = "img#{multipart.size}_#{File.basename(image_file_path)}"
              image_contents[image_file_path] = [part_name, encode64]
            else
              part_name = image_contents[image_file_path].first
            end
            if images[image_file_path] > 1
              if file_url
                multipart << [
                  "\r\n--MHTML_IMAGES",
                  "\r\nContent-Location: ",
                  part_name,
                  "\r\nContent-Type: ",
                  mt,
                  "\r\nContent-Transfer-Encoding: base64\r\n\r\n",
                  encode64
                ]
                "url(#{quot}mhtml:#{file_url}!#{part_name}#{quot})"
              else
                url_match
              end
            else
              "url(#{quot}data:#{mt};base64,#{encode64}#{quot})"
            end
          else
            url_match
          end
        end
      end
      if multipart.size > 1
        content = content.gsub(/(\*?)(background-image:[^;\}]*?url\("?mhtml)/, '*\2')
        (multipart + ["\r\n--MHTML_IMAGES--\r\n*/\r\n", content]).flatten.join("")
      else
        content
      end
    end
    module_function :embed_images

    def asset_url(file_path)
      if defined?(::Rails) && file_path.start_with?(::Rails.public_path) && Cfg.mhtml_base_href?
        URI.join(Cfg.mhtml_base_href, file_path[(::Rails.public_path.size)..-1])
      end
    end
    module_function :asset_url

    def extract_images(content, file_path)
      images = {}
      content.scan(Cfg.url_matcher).flatten.each do |image_path|
        image_file_path = asset_expand_path(image_path, file_path)
        images[image_file_path] = (images[image_file_path] || 0) + 1
      end
      images
    end
    module_function :extract_images

    def asset_expand_path(relative_asset_path, absolute_source_file_path)
      File.expand_path(File.join("..", relative_asset_path), absolute_source_file_path)
    end
    module_function :asset_expand_path

    def image_mime_type(path)
      return if path !~ /\.([^\.]+)$/
      case $1.downcase.to_sym
      when :jpg, :jpeg
        "image/jpeg"
      when :png
        "image/png"
      when :gif
        "image/gif"
      when :tif, :tiff
        "image/tiff"
      end
    end
    module_function :image_mime_type

    def font_mime_type(path)
      return if path !~ /\.([^\.]+)$/
      case $1.downcase.to_sym
      when :ttf
        "font/truetype"
      when :otf
        "font/opentype"
      when :woff
        "font/woff"
      end
    end
    module_function :font_mime_type

    def encoded_file_contents(file_path, css_file_path = nil)
      if css_file_path && is_rake?
        @image_report[file_path] ||= {:found_in => {}}
        @image_report[file_path][:found_in][css_file_path] =
          (@image_report[file_path][:found_in][css_file_path] || 0) + 1
        if @image_report[file_path][:exists] = File.exists?(file_path)
          @image_report[file_path][:embeddable] =
            File.size(file_path) <= Cfg.maximum_embedded_file_size
        end
      end
      if File.exists?(file_path) && File.size(file_path) <= Cfg.maximum_embedded_file_size
        Base64.encode64(File.read(file_path)).gsub(/\n/, "")
      end
    end
    module_function :encoded_file_contents

    def is_runtime?
      ! is_rake?
    end
    module_function :is_runtime?

    def is_rake?
      defined?(@image_report) && @image_report.is_a?(Hash)
    end
    module_function :is_rake?

    def async_write_static_compressed_file(file_path, &block)
      lock_file_path = "#{file_path}.locked"
      return if File.exists?(lock_file_path) && File.mtime(lock_file_path) > (Time.now - 120)
      File.open(lock_file_path, "w"){}  # touch
      Thread.new do
        begin
          file_path = write_static_compressed_file(file_path)
        ensure
          File.delete(lock_file_path)
        end
      end
    end
    module_function :async_write_static_compressed_file

    def write_static_compressed_file(file_path)
      file_path, content = write_static_minified_asset(file_path)
      file_path = write_static_gzipped_file(file_path, content)
    end
    module_function :write_static_compressed_file

    def js_compressor
      closure_compiler_js_compressor || yui_js_compressor
    end
    module_function :js_compressor

    def css_compressor
      yui_css_compressor
    end
    module_function :css_compressor

    protected

    begin
      require "closure-compiler"
      def closure_compiler_js_compressor
        Closure::Compiler.new
      end
    rescue LoadError => e
      STDERR.puts "WARN: #{e.message}"
      def closure_compiler_js_compressor
      end
    end
    module_function :closure_compiler_js_compressor

    begin
      require "yui/compressor"
      def yui_js_compressor
        YUI::JavaScriptCompressor.new
      end
      def yui_css_compressor
        YUI::CssCompressor.new
      end
    rescue LoadError => e
      STDERR.puts "WARN: #{e.message}"
      def yui_js_compressor
      end
      def yui_css_compressor
      end
    end
    module_function :yui_js_compressor
    module_function :yui_css_compressor
  end
end
