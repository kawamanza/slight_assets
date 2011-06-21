require "yaml"

module SlightAssets
  class Config
    attr_reader :config
    def initialize
      @config = {}
    end

    def method_missing(name, *args)
      sname = name.to_s
      case sname
      when /\?$/
        @config[$`]
      when /\=$/
        @config[$`] = args.first
      else
        return @config[sname] if @config.has_key?(sname)
        super
      end
    end

    def load_config(path)
      return @config unless File.exists? path
      hash = YAML.load_file(path)
      hash = hash[::Rails.env] || hash if defined?(::Rails)
      @config.merge! hash["slight_asset"] if hash.has_key?("slight_asset")
    rescue TypeError => e
      puts "could not load #{path}: #{e.inspect}"
    end

    def maximum_embedded_file_size
      unless defined?(@maximum_embedded_file_size)
        c = @config["maximum_embedded_file_size"]
        if c.is_a?(Fixnum)
          @maximum_embedded_file_size = c
        elsif c =~ /\A(\d+)\s*(\w+)\z/
          c = $1.to_i
          case $2
          when "kB", "kb"
            c = c * 1_024
          end
          @maximum_embedded_file_size = [c, 32 * 1_024].min
        end
      end
      @maximum_embedded_file_size
    end

    def url_matcher
      /url\(['"]?(.*?)(?:\?\d+)?['"]?\)/
    end
  end

  Cfg = Config.new
  Cfg.load_config File.expand_path(File.join(*%w[.. .. .. templates install config assets.yml]), __FILE__)
  Cfg.load_config ::Rails.root.join(*%w[config assets.yml]) if defined?(::Rails)
end
