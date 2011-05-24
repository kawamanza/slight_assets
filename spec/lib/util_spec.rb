require "spec_helper"

describe "SlightAssets::Util" do
  it "should respond to methods" do
    SlightAssets::Util.should respond_to(:write_static_gzipped_file)
    SlightAssets::Util.should respond_to(:async_write_static_gzipped_file)
  end
end
