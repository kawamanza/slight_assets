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
          alias_method_chain :stylesheet_tag, :static_compressed_file
        end
      end

      private

      def write_asset_file_contents_with_static_compressed_file(joined_asset_path, asset_paths)
        minify = false
        asset_paths = asset_paths.map do |asset_path|
          p = asset_path.to_s
          if p =~ /\.min\./
            asset_path
          else
            p = p.gsub(/\.(js|css)(\?\w+)?\z/, '.min.\1\2')
            if ::File.exists?(asset_file_path(p))
              p
            else
              minify = true
              asset_path
            end
          end
        end
        minified_joined_asset_path = joined_asset_path.gsub(/(?:\.min)?\.(js|css)\z/, '.min.\1')
        already_existed = File.exists?(minified_joined_asset_path)
        r = write_asset_file_contents_without_static_compressed_file(minify ? joined_asset_path : minified_joined_asset_path, asset_paths)
        if minify && ! already_existed
          SlightAssets::Util.async_write_static_compressed_file(joined_asset_path)
        else
          SlightAssets::Util.write_static_gzipped_file(minified_joined_asset_path)
        end
        r
      end

      def javascript_src_tag_with_static_compressed_file(source, options)
        unless source =~ /\A(?:\w+:)?\/\//
          asset_path = path_to_javascript(source).split('?').first
          file_path = asset_file_path(asset_path)
          if asset_path.end_with?(".js") && asset_path !~ /\.min\./
            compressed_path = asset_path.gsub(/\.js\z/, '.min.js')
            if ::File.exists?(asset_file_path(compressed_path))
              source = compressed_path unless ::File.exists?("#{file_path}.locked")
            elsif ::File.exists?(file_path)
              SlightAssets::Util.async_write_static_compressed_file(file_path)
            end
          end
        end
        javascript_src_tag_without_static_compressed_file(source, options)
      end

      def stylesheet_tag_with_static_compressed_file(source, options)
        unless source =~ /\A(?:\w+:)?\/\//
          asset_path = path_to_stylesheet(source).split('?').first
          file_path = asset_file_path(asset_path)
          if asset_path.end_with?(".css") && asset_path !~ /\.min\./
            compressed_path = asset_path.gsub(/\.css\z/, '.min.css')
            if ::File.exists?(asset_file_path(compressed_path))
              source = compressed_path unless ::File.exists?("#{file_path}.locked")
            elsif ::File.exists?(file_path)
              SlightAssets::Util.async_write_static_compressed_file(file_path)
            end
          end
        end
        stylesheet_tag_without_static_compressed_file(source, options)
      end
    end
  end
end
