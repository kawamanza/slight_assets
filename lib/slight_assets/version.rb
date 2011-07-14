module SlightAssets
  version = nil
  version = $1 if ::File.expand_path('../..', __FILE__) =~ /\/slight_assets-(\d[\w\.]+)/
  version = ::StepUp::Driver::Git.new.last_version_tag rescue "v0.0.0" if version.nil? && ::File.exists?(::File.expand_path('../../../.git', __FILE__))
  VERSION = version.gsub(/^v?([^\+]+)\+?\d*$/, '\1')
end
