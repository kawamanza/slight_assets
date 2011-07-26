# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'slight_assets'
require "step-up"

Gem::Specification.new do |s|
  s.name        = "slight_assets"
  s.version     = SlightAssets::VERSION
  s.authors     = ["Marcelo Manzan"]
  s.email       = ["manzan@gmail.com"]
  s.homepage    = "http://kawamanza.github.com/slight_assets"
  s.summary     = %q{All you need to make your rails application more fast.}
  s.description = %q{Optimize the assets of your Rails application without change any line of code.}

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "slight_assets"

  s.add_dependency "yui-compressor", ">= 0.9.6"

  s.add_development_dependency "step-up", "0.6.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "closure-compiler"

  s.files              = `git ls-files -- {generators,lib,templates}/*`.split("\n")
  s.test_files         = []
  s.executables        = %w[slight]
  s.require_paths      = ["lib"]
end
