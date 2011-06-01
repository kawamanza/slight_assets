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
      jslist = FileList['public/javascripts/**/*.js'].select{|file| ! ( file =~ /\.min\.js$/ || File.exists?(file.gsub(/\.js$/, '.min.js')) ) }
      jslist.each do |jsfile|
        puts "Compressing #{jsfile}"
        minfile = SlightAssets::Util.write_static_compressed_file(jsfile).chomp(".gz")
        jssize = File.size(jsfile)
        minsize = File.size(minfile)
        percent = jssize.zero? ? 100 : (100.0 * minsize / jssize).round
        puts "  -> #{jssize} bytes to #{minsize} bytes (#{percent}% size)"
      end
      puts "Total: #{jslist.size} JS files were compressed" if jslist.any?
    end
  end
end
