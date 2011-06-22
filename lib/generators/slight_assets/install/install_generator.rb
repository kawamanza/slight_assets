require 'rbconfig'

module SlightAssets
  class InstallGenerator < ::Rails::Generators::Base

    def generate
      copy_file "config/assets.yml", "config/assets.yml"
      copy_file "config/initializers/assets.rb", "config/initializers/assets.rb"
    end

    def self.gem_root
      File.expand_path("../../../../../", __FILE__)
    end

    def self.source_root
      File.join(gem_root, 'templates/install')
    end

  end
end
