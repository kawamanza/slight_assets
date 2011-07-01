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
        def js_list
          unless defined?(@js_list)
            @js_list = []
            (SlightAssets::Cfg.minify_assets? || []).each do |mask|
              if mask =~ /\A([+-])?\s*(.*\.js)\z/
                oper = $1 || "+"
                files_mask = [::Rails.root, "public", "javascripts", $2]
                @js_list = @js_list.send(oper, FileList[File.join(*files_mask)])
              end
            end
            files_mask = [::Rails.root, "public", "javascripts", "**", "*.min.js"]
            @js_list = (@js_list - FileList[File.join(*files_mask)]).uniq.sort
          end
          @js_list
        end
        def css_list
          unless defined?(@css_list)
            @css_list = []
            (SlightAssets::Cfg.minify_assets? || []).each do |mask|
              if mask =~ /\A([+-])?\s*(.*\.css)\z/
                oper = $1 || "+"
                files_mask = [::Rails.root, "public", "stylesheets", $2]
                @css_list = @css_list.send(oper, FileList[File.join(*files_mask)])
              end
            end
            files_mask = [::Rails.root, "public", "stylesheets", "**", "*.min.css"]
            @css_list = (@css_list - FileList[File.join(*files_mask)]).uniq.sort
          end
          @css_list
        end
        def mime_type_title_of(path)
          if image_mime_type(path)
            "Image"
          elsif font_mime_type(path)
            "Font"
          else
            "Media"
          end
        end
      end
    end

    desc "Compress all JS files from your Rails application"
    task :js => :pre do
      puts "=" * 80
      if SlightAssets::Util.js_compressor.nil?
        puts "WARN: No JS compressor was found"
        exit 1
      end
      writer = AssetWriter.new
      jslist = writer.js_list
      originalsize, compressedsize = 0, 0
      start_time = Time.now
      jslist.each do |jsfile|
        print "Compressing #{jsfile[(Rails.root.to_s.size+1)..-1]}"
        time = Time.now
        minfile = writer.write_compressed_file(jsfile).chomp(".gz")
        originalsize += jssize = File.size(jsfile)
        compressedsize += minsize = File.size(minfile)
        percent = jssize.zero? ? 100 : (100.0 * minsize / jssize).round
        puts " (#{Time.now - time}s)\n  -> #{jssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      if jslist.any?
        puts "Total #{jslist.size} JS files were compressed"
        percent = originalsize.zero? ? 100 : (100.0 * compressedsize / originalsize).round
        puts "  -> reduced from #{originalsize} bytes to #{compressedsize} bytes (#{percent}% size total, #{originalsize - compressedsize} bytes saved)"
      end
      puts "Elapsed time: #{Time.now - start_time}s"
    end

    desc "Compress all CSS files from your Rails application"
    task :css => :pre do
      puts "=" * 80
      if SlightAssets::Util.css_compressor.nil?
        puts "WARN: No CSS compressor was found"
        exit 1
      end
      writer = AssetWriter.new
      csslist = writer.css_list
      start_time = Time.now
      csslist.each do |cssfile|
        print "Compressing #{cssfile[(Rails.root.to_s.size+1)..-1]}"
        time = Time.now
        minfile = writer.write_compressed_file(cssfile).chomp(".gz")
        csssize = File.size(cssfile)
        minsize = File.size(minfile)
        percent = csssize.zero? ? 100 : (100.0 * minsize / csssize).round
        puts " (#{Time.now - time}s)\n  -> #{csssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      puts "Total: #{csslist.size} CSS files were compressed" if csslist.any?
      puts "Elapsed time: #{Time.now - start_time}s"
      if writer.image_report.any?
        puts "=" * 80
        writer.image_report.each_pair do |image_file, report|
          refs = report[:found_in].size
          puts "#{writer.mime_type_title_of(image_file)}: #{image_file[(Rails.public_path.size)..-1]} (#{"\033[1;31m" unless refs == 1}#{refs} occurrence#{"s" unless refs == 1}\033[0m)"
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
