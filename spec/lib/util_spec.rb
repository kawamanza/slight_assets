require "spec_helper"

describe "SlightAssets::Util" do
  it "should respond to methods" do
    SlightAssets::Util.should respond_to(:write_static_gzipped_file)
    SlightAssets::Util.should respond_to(:write_static_minified_asset)
    SlightAssets::Util.should respond_to(:async_write_static_compressed_file)
  end

  context "checking image mime types" do
    {
      ".gif" => "image/gif",
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".tif" => "image/tiff",
      ".tiff" => "image/tiff"
    }.each_pair do |extension, mime_type|
      it "should identify files ended with '#{extension}' as '#{mime_type}'" do
        SlightAssets::Util.image_mime_type("file#{extension}").should be == mime_type
      end
    end
  end

  context "converting css" do
    it "should embed images, except those that do not exist" do
      file_path = File.expand_path(File.join(*%w[.. .. fixtures rails.css]), __FILE__)
      content = File.read(file_path)
      embed_content = SlightAssets::Util.embed_images(content, file_path)
      embed_content.should_not be == content
      content.should_not =~ /url\("?data:image\/png;base64,/
      content.should =~ /url\("invalid.jpg"\)/
      embed_content.should =~ /url\("invalid.jpg"\)/
      embed_content.should =~ /url\("?data:image\/png;base64,/
    end
    it "should embed images when it was referenced once" do
      file_path = File.expand_path(File.join(*%w[.. .. fixtures once.css]), __FILE__)
      content = File.read(file_path)
      embed_content = SlightAssets::Util.embed_images(content, file_path)
      embed_content.should_not be == content
      embed_content.should =~ /url\("?data:image\/png;base64,/
    end
    it "should embed images when it was referenced twice or more" do
      file_path = File.expand_path(File.join(*%w[.. .. fixtures twice.css]), __FILE__)
      content = File.read(file_path)
      SlightAssets::Util.stubs(:asset_url).with(any_parameters).returns("http://example.com/stylesheets/twice.css")
      embed_content = SlightAssets::Util.embed_images(content, file_path)
      embed_content.should_not be == content
      embed_content.should =~ /multipart\/related/
      embed_content.should =~ /\*background-image:\s*url\("?mhtml:http:\/\/example.com/
    end
    it "should not embed images when it was referenced twice or more" do
      file_path = File.expand_path(File.join(*%w[.. .. fixtures twice.css]), __FILE__)
      content = File.read(file_path)
      embed_content = SlightAssets::Util.embed_images(content, file_path)
      embed_content.should be == content
    end
    it "should replace CSS imports" do
      file_path = File.expand_path(File.join(*%w[.. .. fixtures import_others.css]), __FILE__)
      content = "@import url(\"other.css\")"
      SlightAssets::Cfg.stubs(:replace_css_imports?).returns(true)
      SlightAssets::Util.stubs(:asset_expand_path).with("other.css", anything).returns("other.css")
      File.stubs(:exists?).with("other.css").returns(true)
      embed_content = SlightAssets::Util.embed_images(content, file_path)
      embed_content.should_not be == content
      embed_content.should =~ /url\("other.min.css"\)/
    end
  end

  context "writing" do
    before do
      @file_path = File.expand_path(File.join(*%w[.. .. fixtures fixture.js]), __FILE__)
    end
    it "a gzipped file" do
      zip_path = "#{@file_path}.gz"
      File.delete(zip_path) if File.exists?(zip_path)
      File.should_not be_exists(zip_path)
      output_path = SlightAssets::Util.write_static_gzipped_file(@file_path)
      output_path.should be == zip_path
      File.should be_exists(zip_path)
      File.delete(zip_path)
    end
    it "a minified file" do
      min_path = @file_path.gsub(/\.(js|css)\z/, '.min.\1')
      File.delete(min_path) if File.exists?(min_path)
      File.should_not be_exists(min_path)
      output_path, content = SlightAssets::Util.write_static_minified_asset(@file_path)
      output_path.should be == min_path
      File.should be_exists(min_path)
      File.delete(min_path)
    end
    it "all files synchronously" do
      min_path = @file_path.gsub(/\.(js|css)\z/, '.min.\1')
      zip_path = "#{min_path}.gz"
      lock_file_path = "#{@file_path}.locked"

      File.delete(min_path) if File.exists?(min_path)
      File.delete(zip_path) if File.exists?(zip_path)
      File.should_not be_exists(min_path)
      File.should_not be_exists(zip_path)

      SlightAssets::Util.write_static_compressed_file(@file_path)

      File.should be_exists(min_path)
      File.should be_exists(zip_path)
      File.delete(min_path)
      File.delete(zip_path)
    end
    it "all files asynchronously" do
      min_path = @file_path.gsub(/\.(js|css)\z/, '.min.\1')
      zip_path = "#{min_path}.gz"
      lock_file_path = "#{@file_path}.locked"

      File.delete(min_path) if File.exists?(min_path)
      File.delete(zip_path) if File.exists?(zip_path)
      File.should_not be_exists(min_path)
      File.should_not be_exists(zip_path)

      SlightAssets::Cfg.stubs(:runtime_compression?).returns(true)
      SlightAssets::Util.async_write_static_compressed_file(@file_path)
      while File.exists?(lock_file_path); end

      File.should be_exists(min_path)
      File.should be_exists(zip_path)
      File.delete(min_path)
      File.delete(zip_path)
    end
  end
end
