module Salus
  class ZabbixCacheRenderer < BaseRenderer
    ZABBIX_DEFAULT_TTL = 60
    attr_reader :data

    def render(data)
      @data = {}
      iterate(data) do |name, metric|
        name  = name.gsub(/\.\[/, '[')
        value = metric.value
        value = value.dump if (!value.nil? && metric.is_a?(Salus::Text))
        # Metric cache TTL is a half of real metric TTL
        ttl   = metric.ttl.nil? ? ZABBIX_DEFAULT_TTL : (metric.ttl / 2)
        @data[name] = {timestamp: metric.timestamp, cache_ttl: ttl, value: value}
      end
    end
  end

  class ZabbixCli < Thor
    include BaseCliUtils
    include Thor::Actions
    ZABBIX_CACHE_FILE  = "zabbix.cache.yml"


    desc "discover NAME", "Run discovery"
    method_option :file,  aliases: "-f", :type => :array, desc: "File(s) with metrics' definition"
    method_option :debug, aliases: "-d", :type => :boolean, :default => false
    def discover(name)
      Salus.logger.level = options[:debug] ? Logger::DEBUG : Logger::WARN
      require "salus/zabbix"
      load_files(get_files(options))
      puts Salus.discovery(name)
    end

    desc "parameter NAME", "Get a requested parameter"
    method_option :file,  aliases: "-f", :type => :array,  desc: "File(s) with metrics' definition"
    method_option :state, aliases: "-s", :type => :string, desc: "State file location"
    method_option :cache, aliases: "-c", :type => :string, desc: "Cache file location"
    method_option :cache_ttl, aliases: "-t", :type => :numeric, desc: "Force metric cache ttl"
    method_option :debug, aliases: "-d", :type => :boolean, :default => false
    def parameter(name)
      Salus.logger.level = options[:debug] ? Logger::DEBUG : Logger::WARN
      cache_file = options.fetch(:cache, File.join(Dir.pwd, ZABBIX_CACHE_FILE))
      cache  = load_cache(cache_file)

      if (cache.key?(name) && !expired?(cache[name], options))
        STDOUT.puts cache[name][:value] unless cache[name][:value].nil?
        return

      require "salus/zabbix"
      load_files(get_files(options))

      state_file = get_state_file(options)
      load_state(state_file)

      render = ZabbixCacheRenderer.new
      Salus.renders.clear
      Salus.render(render)
      Salus.tick
      cache  = render.data

      if (cache.key?(name))
        STDOUT.puts cache[name][:value]unless cache[name][:value].nil?
      end

      save_state(state_file)
      save_cache(cache_file, cache)
      raise "Unknown parameter #{name}" unless cache.key?(name)
    end

    private
    def expired?(metric, options={})
      return true if metric.nil?
      ttl = options.fetch(:cache_ttl, metric[:cache_ttl])
      ttl ||= 0
      (Time.now.to_f > metric[:timestamp] + ttl)
    end

    def load_cache(file)
      begin
        if File.exists?(file)
          YAML.load(read_file(file))
        else
          {}
        end
      rescue Exception => e
        log ERROR, "Failed to load state #{file}: " + e.message
        {}
      end
    end

    def save_cache(file, data)
      begin
        write_file(file, data.to_yaml)
      rescue Exception => e
        log ERROR, "Failed to save state #{file}: " + e.message
      end
    end
  end
end
