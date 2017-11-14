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
    @@groups = {}
    @@renders= []
    @@opts   = {}

    def on_win?
      @@win ||= !(RUBY_PLATFORM =~ /bccwin|cygwin|djgpp|mingw|mswin|wince/i).nil?
    end

    def group(title, &block)
      unless @@groups.key?(title)
        @@groups[title] = Group.new(@@opts, &block)
      end
    end

    def groups
      @@groups
    end
    alias root groups

    def default(*args)
      opts   = args.select { |x| x.is_a?(Hash) }.first
      opts ||= {}
      opts.each do |k, v|
        next if [:value, :timestamp].include?(k)
        @@opts[k] = v
      end
    end

    def defaults
      @@opts
    end

    def render(obj=nil, &block)
      if block_given?
        @@renders << BlockRenderer.new(&block)
      else
        unless obj.is_a? Salus::BaseRenderer
          log ERROR, "#{obj.class} must be a subclass of Salus::BaseRenderer"
          return
        end
        @@renders << obj
      end
    end

    def renders
      @@renders
    end

    def reset
      @@groups  = {}
      @@renders = []
      @@opts    = {}
      if defined?(@@pool) && @@pool.is_a?(Salus::ThreadPool)
        @@pool.shutdown!
        @@pool = nil
      end
    end

    def load(file)
      instance_eval(File.read(file), File.basename(file), 0) if File.exists?(file)
    end

    def load_state(&block)
      data = block.call
      return if data.nil?
      return if data.empty?
      data.each do |k, v|
        @@groups[k].load(v) if @@groups.key?(k)
      end
    end

    def save_state(&block)
      data = {}
      @@groups.each { |k, v| data[k]  = v.to_h }
      block.call(data)
    end

    def tick
      return if @@groups.empty?
      pause = (Salus.interval - Salus.tick_timeout - Salus.render_timeout) / 2
      pause = 1 if (pause <= 0)

      latch = CountDownLatch.new(@@groups.count)
      @@groups.each do |k, v|
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

      return if @@renders.empty?
      latch = CountDownLatch.new(@@renders.count)
      @@renders.each do |v|
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
      @@pool ||= ThreadPool.new(self.min_threads, self.max_threads).auto_trim!
    end
  end
end
