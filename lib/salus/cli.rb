require "tmpdir"
require "thor"
require "yaml"

module Salus
  class CLI < Thor
    include Logging
    include Thor::Actions
    SALUS_STATE_FILE = "salus.state.yml"
    SALUS_FILE = "Salusfile"
    SALUS_GLOB = "*.salus"

    desc "once", "Run check once"
    method_option :file,  aliases: "-f", :type => :array,  desc: "File(s) with metrics' definition"
    method_option :state, aliases: "-s", :type => :string, desc: "State file location"
    method_option :debug, aliases: "-d", :type => :boolean, :default => false
    method_option :renderer, aliases: "-r", :type => :array, desc: "Append predefined renderers"
    def once
      Salus.logger.level = options[:debug] ? Logger::DEBUG : Logger::WARN
      state_file = get_state_file(options)
      load_files(get_files(options))
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

      Renderer.descendants.each do |m|
        sym = m.name.split('::').last.downcase.sub(/renderer$/, '')
        if renderers.include?(sym)
          Salus.render(m.new)
        end
      end
    end

    def load_files(files)
      raise "No metric definition files found" if files.empty?
      files.each do |file|
        begin
          Salus.load(file)
        rescue Exception => e
          log ERROR, "Failed to load #{file}: " + e.message
        end
      end
    end

    def load_state(file)
      Salus.load_state do
        begin
          YAML.load_file(file) if File.exists?(file)
        rescue Exception => e
          log ERROR, "Failed to load state #{file}: " + e.message
        end
      end
    end

    def save_state(file)
      Salus.save_state do |data|
        begin
          File.write(file, data.to_yaml)
        rescue Exception => e
          log ERROR, "Failed to save state #{file}: " + e.message
        end
      end
    end

    def get_state_file(options={})
      options.fetch(:state, File.join(Dir.pwd, SALUS_STATE_FILE))
    end

    def get_files(options={})
      if options.key?(:file)
        ret = []
        options[:file].each do |file|
          next unless File.exists?(file)
          if File.directory?(file)
            ret += Dir.glob(File.join(file, SALUS_GLOB))
          else
            ret.push(file)
          end
        end
        ret
      elsif File.exists?(SALUS_FILE)
        [SALUS_FILE]
      else
        Dir.glob(SALUS_GLOB)
      end
    end
  end
end
