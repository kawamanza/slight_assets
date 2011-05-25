require "spec_helper"

describe "SlightAssets::Util" do
  it "should respond to methods" do
    SlightAssets::Util.should respond_to(:write_static_gzipped_file)
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
  end
end
