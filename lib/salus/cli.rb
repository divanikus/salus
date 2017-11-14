require "thor"
require "yaml"
require "salus/cli/baseutils"
require "salus/cli/zabbix"

module Salus
  class CLI < Thor
    include BaseCliUtils
    include Thor::Actions

    register Salus::ZabbixCli, :zabbix, "zabbix", "Zabbix specific actions"

    desc "once", "Run check once"
    method_option :file,  aliases: "-f", :type => :array,  desc: "File(s) with metrics' definition"
    method_option :state, aliases: "-s", :type => :string, desc: "State file location"
    method_option :debug, aliases: "-d", :type => :boolean, :default => false
    method_option :renderer, aliases: "-r", :type => :array, desc: "Append predefined renderers"
    def once
      Salus.logger.level = options[:debug] ? Logger::DEBUG : Logger::WARN
      load_files(get_files(options))
      state_file = get_state_file(options)
      load_state(state_file)
      append_renderers(options)
      Salus.tick
      save_state(state_file)
    end

    desc "loop", "Run check loop"
    method_option :file,  aliases: "-f", :type => :array,  desc: "File(s) with metrics' definition"
    method_option :debug, aliases: "-d", :type => :boolean, :default => false
    method_option :renderer, aliases: "-r", :type => :array, desc: "Append predefined renderers"
    def loop
      Salus.logger.level = options[:debug] ? Logger::DEBUG : Logger::WARN
      load_files(get_files(options))
      append_renderers(options)
      Salus.run
    end

    default_task :once

    private
    def append_renderers(options={})
      renderers = options.fetch(:renderer, Salus.renders.empty? ? ["stdout"] : [])

      BaseRenderer.descendants.each do |m|
        sym = m.name.split('::').last.downcase.sub(/renderer$/, '')
        if renderers.include?(sym)
          Salus.render(m.new)
        end
      end
    end
  end
end
