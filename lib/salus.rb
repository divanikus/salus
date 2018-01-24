require "salus/version"
require "salus/logging"
require "salus/thread"
require "salus/group"
require "salus/configuration"
require "salus/renderer"

module Salus
  extend Configuration

  class << self
    include Logging
    @@_groups = {}
    @@_renders= []
    @@_opts   = {}
    @@_vars   = {}
    @@_lazy   = []

    def on_win?
      @@_win ||= !(RUBY_PLATFORM =~ /bccwin|cygwin|djgpp|mingw|mswin|wince/i).nil?
    end

    def group(title, &block)
      unless @@_groups.key?(title)
        @@_groups[title] = Group.new(@@_opts, &block)
      end
    end

    def groups
      @@_groups
    end
    alias root groups

    def default(opts)
      return unless opts.is_a?(Hash)
      opts.each do |k, v|
        next if [:value, :timestamp].include?(k)
        @@_opts[k] = v
      end
    end

    def defaults
      @@_opts
    end

    def var(arg, default=nil, &block)
      if arg.is_a?(Hash)
        arg.each {|k, v| @@_vars[k] = v}
      elsif block_given?
        @@_vars[arg.to_sym] = block
      else
        value = @@_vars.fetch(arg.to_sym, default)
        # Dumb lazy loading
        @@_vars[arg.to_sym] = if value.is_a?(Proc)
          begin
            value = value.call
          rescue Exception => e
            log DEBUG, e
            value = default
          end
        end
        value
      end
    end
    alias let var

    def vars
      @@_vars
    end

    def render(obj=nil, &block)
      if block_given?
        @@_renders << BlockRenderer.new(&block)
      else
        unless obj.is_a? Salus::BaseRenderer
          log ERROR, "#{obj.class} must be a subclass of Salus::BaseRenderer"
          return
        end
        @@_renders << obj
      end
    end

    def renders
      @@_renders
    end

    def reset
      @@_groups  = {}
      @@_renders = []
      @@_opts    = {}
      @@_vars    = {}
      @@_lazy    = []
      if defined?(@@_pool) && @@_pool.is_a?(Salus::ThreadPool)
        @@_pool.shutdown!
        @@_pool = nil
      end
    end

    def lazy(&block)
      raise ArgumentError, "Block should be given" unless block_given?
      @@_lazy << block
    end

    def lazy_eval
      # Lazy eval blocks once
      return if @@_lazy.empty?
      @@_lazy.each { |block| instance_eval(&block) }
      @@_lazy.clear
    end

    def load(file)
      instance_eval(File.read(file), File.basename(file), 0) if File.exists?(file)
    end

    def load_state(&block)
      data = block.call
      return unless data
      return if data.empty?
      lazy_eval
      data.each do |k, v|
        @@_groups[k].load(v) if @@_groups.key?(k)
      end
    end

    def save_state(&block)
      data = {}
      @@_groups.each { |k, v| data[k]  = v.to_h }
      block.call(data)
    end

    def tick
      lazy_eval
      return if @@_groups.empty?
      pause = (Salus.interval - Salus.tick_timeout - Salus.render_timeout) / 2
      pause = 1 if (pause <= 0)

      latch = CountDownLatch.new(@@_groups.count)
      @@_groups.each do |k, v|
        pool.process do
          begin
            v.tick
            latch.count_down
          rescue Exception => e
            log ERROR, e
            latch.count_down
          end
        end.timeout_after(Salus.tick_timeout)
      end
      latch.wait(Salus.tick_timeout + pause)
      log DEBUG, "Collection finished. Threads: #{pool.spawned} spawned, #{pool.waiting} waiting, #{Thread.list.count} total"

      return if @@_renders.empty?
      latch = CountDownLatch.new(@@_renders.count)
      @@_renders.each do |v|
        pool.process do
          begin
            v.render(root)
            latch.count_down
          rescue Exception => e
            log ERROR, e
            latch.count_down
          end
        end.timeout_after(Salus.render_timeout)
      end
      latch.wait(Salus.render_timeout + pause)
      log DEBUG, "Rendering finished. Threads: #{pool.spawned} spawned, #{pool.waiting} waiting, #{Thread.list.count} total"
    end

    def run
      loop do
        pool.process do
          tick
        end
        sleep Salus.interval
      end
    end

    protected
    def pool
      @@_pool ||= ThreadPool.new(self.min_threads, self.max_threads).auto_trim!
    end
  end
end
