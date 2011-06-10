require "base64"

module SlightAssets
  module Util
    begin
      require "zlib"
      def write_static_gzipped_file(file_path)
        return file_path if file_path.nil? || file_path.end_with?(".gz") || ! File.exists?(file_path)
        zip_path = "#{file_path}.gz"
        return zip_path if File.exists?(zip_path)
        content = File.read(file_path)
        Zlib::GzipWriter.open(zip_path, Zlib::BEST_COMPRESSION) {|f| f.write(content) }
        # Set mtime to the latest of the file to allow for
        # consistent ETag without a shared filesystem.
        mt = File.mtime(file_path)
        File.utime(mt, mt, zip_path)
        zip_path
      end
    rescue LoadError
      STDERR.puts "WARN: Couldn't load Zlib Gem"
      def write_static_gzipped_file(file_path)
        file_path
      end
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
      content = compressor.compress(content)
      content = embed_images(content, min_path) if extension == "css"
      File.open(min_path, "w") { |f| f.write(content) }
      mt = File.mtime(file_path)
      File.utime(mt, mt, min_path)
      min_path
    end
    module_function :write_static_minified_asset

    def embed_images(content, file_path)
      return content if file_path =~ /\A(?:\w+:)?\/\//
      images = extract_images(content, file_path)
      files = {}
      content = content.gsub(Cfg.url_matcher) do |url_match|
        image_path = $1
        if image_path =~ /\A(?:[\\\/]|\w+:)/
          url_match
        else
          image_file_path = File.expand_path(File.join("..", image_path), file_path)
          encode64 = files[image_file_path]
          if (mt = image_mime_type(image_path)) &&
             (encode64 ||= encoded_file_contents(image_file_path))
            if images[image_file_path] > 1
              if files[image_file_path].nil?
                files[image_file_path] = encode64
              end
              url_match
            else
              "url(\"data:#{mt};base64,#{encode64}\")"
            end
          else
            url_match
          end
        end
      end
    end
    module_function :embed_images

    def extract_images(content, file_path)
      images = {}
      content.scan(Cfg.url_matcher).flatten.each do |image_path|
        image_file_path = File.expand_path(File.join("..", image_path), file_path)
        images[image_file_path] = (images[image_file_path] || 0) + 1
      end
      images
    end
    module_function :extract_images

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

    def encoded_file_contents(file_path)
      if File.exists?(file_path) && File.size(file_path) <= Cfg.maximum_embedded_file_size
        Base64.encode64(File.read(file_path)).gsub(/\n/, "")
      end
    end
    module_function :encoded_file_contents

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
      file_path = write_static_minified_asset(file_path)
      file_path = write_static_gzipped_file(file_path)
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
