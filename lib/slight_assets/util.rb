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
      content = yield(extension, content) || content if block_given?
      File.open(min_path, "w") { |f| f.write(content) }
      mt = File.mtime(file_path)
      File.utime(mt, mt, min_path)
      min_path
    end
    module_function :write_static_minified_asset

    def async_write_static_compressed_file(file_path, &block)
      lock_file_path = "#{file_path}.locked"
      return if File.exists?(lock_file_path) && File.mtime(lock_file_path) > (Time.now - 120)
      File.open(lock_file_path, "w"){}  # touch
      Thread.new do
        begin
          file_path = write_static_compressed_file(file_path) { |extension, content| content }
        ensure
          File.delete(lock_file_path)
        end
      end
    end
    module_function :async_write_static_compressed_file

    def write_static_compressed_file(file_path, &block)
      file_path = write_static_minified_asset(file_path, &block)
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
