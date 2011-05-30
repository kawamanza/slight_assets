module SlightAssets
  module Rails
    def init!
      ActionView::Helpers::AssetTagHelper.send :include, HelperMethods
    end
    module_function :init!

    module HelperMethods
      def self.included(base)
        base.class_eval do
          alias_method_chain :write_asset_file_contents, :static_compressed_file
          alias_method_chain :javascript_src_tag, :static_compressed_file
        end
      end

      private

      def write_asset_file_contents_with_static_compressed_file(joined_asset_path, asset_paths)
        already_existed = File.exists?(joined_asset_path.gsub(/\.(js|css)\z/, '.min.\1'))
        r = write_asset_file_contents_without_static_compressed_file(joined_asset_path, asset_paths)
        SlightAssets::Util.async_write_static_compressed_file(joined_asset_path) unless already_existed
        r
      end

      def javascript_src_tag_with_static_compressed_file(source, options)
        unless source =~ /\A(?:\w+:)?\/\//
          asset_path = path_to_javascript(source).split('?').first
          file_path = asset_file_path(asset_path)
          if asset_path.end_with?(".js") && asset_path !~ /\.min\./ && ::File.exists?(file_path)
            compressed_path = asset_path.gsub(/\.js\z/, '.min.js')
            if ::File.exists?(asset_file_path(compressed_path))
              source = compressed_path unless ::File.exists?("#{file_path}.locked")
            else
              SlightAssets::Util.async_write_static_compressed_file(file_path)
            end
          end
        end
        javascript_src_tag_without_static_compressed_file(source, options)
      end
    end
  end
end
