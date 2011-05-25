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

    begin
      require "yui/compressor"
      def write_static_minified_asset(file_path)
        return file_path if file_path.nil? || file_path =~ /\.min\./ || file_path !~ /\.(?:js|css)\z/ || ! File.exists?(file_path)
        min_path = file_path.gsub(/\.(js|css)\z/, '.min.\1')
        case extension = $1
        when "css"
          compressor = YUI::CssCompressor.new
        when "js"
          compressor = YUI::JavaScriptCompressor.new
        else
          return file_path
        end
        content = File.read(file_path)
        content = compressor.compress(content)
        File.open(min_path, "w") { |f| f.write(content) }
        mt = File.mtime(file_path)
        File.utime(mt, mt, min_path)
        min_path
      end
    rescue LoadError => e
      STDERR.puts "WARN: #{e.message}"
      def write_static_minified_asset(file_path)
        file_path
      end
    end
    module_function :write_static_minified_asset

    def async_write_static_compressed_file(file_path)
      Thread.new do
        file_path = write_static_gzipped_file(file_path)
      end
    end
    module_function :async_write_static_compressed_file
  end
end
