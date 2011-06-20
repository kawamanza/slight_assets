require "spec_helper"

describe "SlightAssets::JsReducer" do
  it "should reduce JS" do
    from = "function callback1(){var tcallback=function(){return true};return tcallback}"
    from.size.should be == 76
    to   = "function callback1(){var t`" + [31+8, 32, 32+17-8].pack("ccc") +
                                             "=`" + [31+8, 32, 32+35-8].pack("ccc") +
                                                      "(){return true};`" + [31+8, 32, 32+13-8].pack("ccc") +
                                                                              "`" + [31+8, 32, 32+41-8].pack("ccc") +
                                                                                      "}"
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.should be == to
    tr.size.should be == 60
  end
  it "should crop 96 characters from '96 chars * n'" do
    str = SlightAssets::JsReducer::BYTE_RANGE.inject(""){ |s, i| i != 96 ? (s << i) : s }
    n = 200
    from = (str + "j") * n
    from.size.should be == 96 * n
    to   = (str + "j") + ([96, 31+96, 32, 32].pack("cccc") * (n-1))
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.size.should be == 96 + 4 * (n - 1)
    tr.should be == to
  end
end
