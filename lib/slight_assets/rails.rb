module ActionView
  module Helpers
    module AssetTagHelper
    private
      def write_asset_file_contents_with_static_gzipped_file(joined_asset_path, asset_paths)
        r = _write_asset_file_contents_without_static_gzipped_file(joined_asset_path, asset_paths)
        write_static_gzipped_file(joined_asset_path)
        r
      end
      alias_method_chain :write_asset_file_contents, :static_gzipped_file

      begin
        require "zlib"
        def write_static_gzipped_file(joined_asset_path)
          # TODO: put the code here
        end
      rescue LoadError
        # TODO: display warning
        def _write_static_gzipped_file(joined_asset_path)
        end
      end
    end
  end
end
