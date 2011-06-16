require "spec_helper"

describe "SlightAssets::JsReducer" do
  it "should reduce JS" do
    from = "function callback1(){var tcallback=function(){return true};return tcallback}"
    from.size.should be == 76
    to   = "function callback1(){var t`" + [28+8, 32, 32+17-8].pack("ccc") +
                                             "=`" + [28+8, 32, 32+35-8].pack("ccc") +
                                                      "(){return true};`" + [28+8, 32, 32+13-8].pack("ccc") +
                                                                              "`" + [28+8, 32, 32+41-8].pack("ccc") +
                                                                                      "}"
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.should be == to
    tr.size.should be == 60
  end
  it "should crop 99 characters from '99 chars * n'" do
    str = SlightAssets::JsReducer::BYTE_RANGE.inject(""){ |s, i| i != 96 ? (s << i) : s }
    n = 200
    from = (str + "jspk") * n
    from.size.should be == 99 * n
    to   = (str + "jspk") + ([96, 28+99, 32, 32].pack("cccc") * (n-1))
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.size.should be == 99 + 4 * (n - 1)
    tr.should be == to
  end
  it "should crop 99 characters from '100 chars * n'" do
    str = SlightAssets::JsReducer::BYTE_RANGE.inject(""){ |s, i| i != 96 ? (s << i) : s }
    n = 200
    from = (str + "jspk1") * n
    from.size.should be == 100 * n
    to   = (str + "jspk1") + ([96, 28+99, 32, 32+1].pack("cccc") * (n+1)) + "1"
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.size.should be == 100 + 4 * (n + 1) + 1
    tr.should be == to
  end
  it "should crop 99 characters from '101 chars * n'" do
    str = SlightAssets::JsReducer::BYTE_RANGE.inject(""){ |s, i| i != 96 ? (s << i) : s }
    n = 200
    from = (str + "jspk13") * n
    from.size.should be == 101 * n
    to   = (str + "jspk13") + ([96, 28+99, 32, 32+2].pack("cccc") * (n+3)) + "13"
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.size.should be == 101 + 4 * (n + 3) + 2
    tr.should be == to
  end
  it "should crop 99 characters from '102 chars * n'" do
    str = SlightAssets::JsReducer::BYTE_RANGE.inject(""){ |s, i| i != 96 ? (s << i) : s }
    n = 200
    from = (str + "jspk135") * n
    from.size.should be == 102 * n
    to   = (str + "jspk135") + ([96, 28+99, 32, 32+3].pack("cccc") * (n+5)) + "135"
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.size.should be == 102 + 4 * (n + 5) + 3
    tr.should be == to
  end
  it "should crop 99 characters from '103 chars * n'" do
    str = SlightAssets::JsReducer::BYTE_RANGE.inject(""){ |s, i| i != 96 ? (s << i) : s }
    n = 200
    from = (str + "jspk1357") * n
    from.size.should be == 103 * n
    to   = (str + "jspk1357") + ([96, 28+99, 32, 32+4].pack("cccc") * (n+7)) + "1357"
    tr = SlightAssets::JsReducer.new.reduce(from)
    tr.size.should be == 103 + 4 * (n + 7) + 4
    tr.should be == to
  end
end
