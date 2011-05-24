module SlightAssets
  module Util
    begin
      require "zlib"
      def write_static_gzipped_file(file_path)
        # TODO: put the code here
      end
    rescue LoadError
      STDERR.puts "WARN: Couldn't load zlib Gem"
      def write_static_gzipped_file(file_path, *args)
      end
    end
    module_function :write_static_gzipped_file

    def async_write_static_gzipped_file(file_path)
      Thread.new { write_static_gzipped_file(file_path) }
    end
    module_function :async_write_static_gzipped_file
  end
end
