require "spec_helper"

describe "SlightAssets::Util" do
  it "should respond to methods" do
    SlightAssets::Util.should respond_to(:write_static_gzipped_file)
    SlightAssets::Util.should respond_to(:write_static_minified_asset)
    SlightAssets::Util.should respond_to(:async_write_static_compressed_file)
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
      output_path = SlightAssets::Util.write_static_minified_asset(@file_path)
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

      SlightAssets::Util.async_write_static_compressed_file(@file_path)
      while File.exists?(lock_file_path); end

      File.should be_exists(min_path)
      File.should be_exists(zip_path)
      File.delete(min_path)
      File.delete(zip_path)
    end
  end
end
