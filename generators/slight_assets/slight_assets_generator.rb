require 'rbconfig'

class SlightAssetsGenerator < ::Rails::Generator::Base
  def manifest
    record do |m|
      m.file "config/assets.yml", "config/assets.yml"
      m.file "config/initializers/assets.rb", "config/initializers/assets.rb"
    end
  end

  def self.gem_root
    File.expand_path('../../../', __FILE__)
  end

  def self.source_root
    File.join(gem_root, 'templates', 'install')
  end

  def source_root
    self.class.source_root
  end

  private

  def banner
    "Usage: #{$0} slight_assets"
  end
end
