require "action_view"

module ActionView
  module Helpers
    module AssetTagHelper
    private
      def write_asset_file_contents_with_static_gzipped_file(joined_asset_path, asset_paths)
        r = write_asset_file_contents_without_static_gzipped_file(joined_asset_path, asset_paths)
        SlighAssets::Util.async_write_static_gzipped_file(asset_file_path(joined_asset_path))
        r
      end
      alias_method_chain :write_asset_file_contents, :static_gzipped_file
    end
  end
end
