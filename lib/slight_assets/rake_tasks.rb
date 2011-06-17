namespace :asset do
  namespace :compress do
    task :pre => :environment do
      require "slight_assets"
      class AssetWriter
        include ::SlightAssets::Util
        attr_reader :image_report
        def initialize
          @image_report = {}
        end
        def write_compressed_file(file)
          write_static_compressed_file(file)
        end
      end
    end

    desc "Compress all JS files from your Rails application"
    task :js => :pre do
      if SlightAssets::Util.js_compressor.nil?
        puts "WARN: No JS compressor was found"
        exit 1
      end
      jslist = FileList[File.join(Rails.root, *%w(public javascripts ** *.js))].select{|file| ! ( file =~ /\.min\.js$/ || File.exists?(file.gsub(/\.js$/, '.min.js')) ) }
      writer = AssetWriter.new
      originalsize, compressedsize = 0, 0
      jslist.each do |jsfile|
        puts "Compressing #{jsfile[(Rails.root.to_s.size+1)..-1]}"
        minfile = writer.write_compressed_file(jsfile).chomp(".gz")
        originalsize += jssize = File.size(jsfile)
        compressedsize += minsize = File.size(minfile)
        percent = jssize.zero? ? 100 : (100.0 * minsize / jssize).round
        puts "  -> #{jssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      if jslist.any?
        puts "Total #{jslist.size} JS files were compressed"
        percent = originalsize.zero? ? 100 : (100.0 * compressedsize / originalsize).round
        puts "  -> reduced from #{originalsize} bytes to #{compressedsize} bytes (#{percent}% size total, #{originalsize - compressedsize} bytes saved)"
      end
    end

    desc "Compress all CSS files from your Rails application"
    task :css => :pre do
      if SlightAssets::Util.css_compressor.nil?
        puts "WARN: No CSS compressor was found"
        exit 1
      end
      writer = AssetWriter.new
      csslist = FileList[File.join(Rails.root, *%w(public stylesheets ** *.css))].select{|file| ! ( file =~ /\.min\.css$/ || File.exists?(file.gsub(/\.css$/, '.min.css')) ) }
      csslist.each do |cssfile|
        puts "Compressing #{cssfile[(Rails.root.to_s.size+1)..-1]}"
        minfile = writer.write_compressed_file(cssfile).chomp(".gz")
        csssize = File.size(cssfile)
        minsize = File.size(minfile)
        percent = csssize.zero? ? 100 : (100.0 * minsize / csssize).round
        puts "  -> #{csssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      puts "Total: #{csslist.size} CSS files were compressed" if csslist.any?
      if writer.image_report.any?
        puts "=" * 80
        writer.image_report.each_pair do |image_file, report|
          refs = report[:found_in].size
          puts "Image: #{image_file[(Rails.public_path.size)..-1]} (#{"\033[1;31m" unless refs == 1}#{refs} occurrence#{"s" unless refs == 1}\033[0m)"
          report[:found_in].each_pair do |css_file, count|
            mode = report[:exists] ? (report[:embeddable] && count == 1 ? "embedded" : "\033[0;33mnot embedded\033[0m") : "\033[0;31mnot found\033[0m"
            puts "  found in #{css_file[(Rails.public_path.size)..-1]} (#{count} ref#{"s" unless count == 1}, #{mode})"
          end
        end
      end
    end
  end

  desc "Compress all JS and CSS files from your Rails application"
  task :compress => ["compress:js", "compress:css"]
end
