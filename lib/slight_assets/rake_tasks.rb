namespace :asset do
  namespace :compress do
    task :pre => :environment do
      require "slight_assets"
    end

    desc "Compress all JS files from your Rails application"
    task :js => :pre do
      if SlightAssets::Util.js_compressor.nil?
        puts "WARN: No JS compressor was found"
        exit 1
      end
      jslist = FileList[File.join(Rails.root, *%w(public javascripts ** *.js))].select{|file| ! ( file =~ /\.min\.js$/ || File.exists?(file.gsub(/\.js$/, '.min.js')) ) }
      jslist.each do |jsfile|
        puts "Compressing #{jsfile[(Rails.root.to_s.size+1)..-1]}"
        minfile = SlightAssets::Util.write_static_compressed_file(jsfile).chomp(".gz")
        jssize = File.size(jsfile)
        minsize = File.size(minfile)
        percent = jssize.zero? ? 100 : (100.0 * minsize / jssize).round
        puts "  -> #{jssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      puts "Total: #{jslist.size} JS files were compressed" if jslist.any?
    end

    desc "Compress all CSS files from your Rails application"
    task :css => :pre do
      if SlightAssets::Util.css_compressor.nil?
        puts "WARN: No CSS compressor was found"
        exit 1
      end
      csslist = FileList[File.join(Rails.root, *%w(public stylesheets ** *.css))].select{|file| ! ( file =~ /\.min\.css$/ || File.exists?(file.gsub(/\.css$/, '.min.css')) ) }
      csslist.each do |cssfile|
        puts "Compressing #{cssfile[(Rails.root.to_s.size+1)..-1]}"
        minfile = SlightAssets::Util.write_static_compressed_file(cssfile).chomp(".gz")
        csssize = File.size(cssfile)
        minsize = File.size(minfile)
        percent = csssize.zero? ? 100 : (100.0 * minsize / csssize).round
        puts "  -> #{csssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      puts "Total: #{csslist.size} CSS files were compressed" if csslist.any?
    end
  end

  desc "Compress all JS and CSS files from your Rails application"
  task :compress => ["compress:js", "compress:css"]
end
