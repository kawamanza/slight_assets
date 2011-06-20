# Slight Assets

The best way to optimize the assets of your Rails application without change any line of code.

## Usage

Put the lines below into your application's Gemfile:

    gem "closure-compiler" # optional, but recommended
    gem "slight_assets"
    gem "utf8" if RUBY_VERSION.to_f < 1.9

Creates an initializer with the following lines:

    # config/initializers/assets.rb
    require "slight_assets"

    SlightAssets::Rails.init!

Now you can enjoy the benefits of your faster Rails application.

## Benefits

  - CSS compression (with YUI::CssCompressor)
  - CSS compression and concatenation (with the normal view-helper `stylesheet_link_tag`)
  - CSS auto-embedding existing relative images
  - JavaScript compression (with Closure::Compiler or YUI::JavaScriptCompressor)
  - JavaScript obfuscation and reduction (with internal reductor algorithm)
  - JavaScript compression and concatenation (with the normal view-helper `javascript_include_tag`)

The list above has all benefits at runtime in your Rails application.

## Pre-generating compressed content

You can further improve the performance of your application by pre-generating compressed content
with the use of rake tasks.

Put the following line into your application's Rakefile:

    require 'slight_assets/rake_tasks'

Now you can pre-generate the compressed content by using the following tasks:

    rake asset:compress:css  # Compress all CSS files from your Rails application
    rake asset:compress:js   # Compress all JS files from your Rails application
    rake asset:compress      # Compress all JS and CSS files from your Rails application
