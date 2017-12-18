require "forwardable"
require "salus/metric"
require "salus/metric/absolute"
require "salus/metric/counter"
require "salus/metric/derive"
require "salus/metric/gauge"
require "salus/metric/text"

module Salus
  class Group
    extend Forwardable
    include Lockable

    def_delegators :@_metrics, :[], :key?, :values_at, :fetch, :length, :delete, :empty?

    def initialize(defaults={}, &block)
      @_metrics = {}
      @_groups  = {}
      @_cache   = {}
      @_proc    = block
      @_opts    = defaults.clone
    end

    Metric.descendants.each do |m|
      sym = m.name.split('::').last.downcase.to_sym
      define_method(sym) do |title, args={}, &blk|
        raise ArgumentError, "Metric needs a name!" if title.nil? or !title.is_a?(String)

        unless @_metrics.key?(title)
          @_metrics[title] = m.new(@_opts)
        end

        @_metrics[title].push(args, &blk)
      end
    end

    def on_win?
      Salus.on_win?
    end

    def var(arg, default=nil, &block)
      Salus.var(arg, default, &block)
    end

    def default(opts)
      return unless opts.is_a?(Hash)
      opts.each do |k, v|
        next if [:value, :timestamp].include?(k)
        @_opts[k] = v
      end
    end

    def group(title, &block)
      synchronize do
        unless @_groups.key?(title)
          @_groups[title] = Group.new(@_opts, &block)
          if @_cache.key?(title)
            @_groups[title].load(@_cache[title])
            @_cache.delete(title)
          end
        end
      end
    end

    def groups
      synchronize { @_groups }
    end

    def has_subgroups?
      synchronize { !@_groups.empty? }
    end

    def value(title)
      synchronize { @_metrics.key?(title) ? @_metrics[title].value : nil }
    end

    def keys(allow_mute=false)
      synchronize do
        if allow_mute
          @_metrics.keys
        else
          @_metrics.keys.select { |x| !@_metrics[x].mute? }
        end
      end
    end

    def values(allow_mute=false)
      synchronize do
        if allow_mute
          @_metrics.values
        else
          @_metrics.values.select { |x| !x.mute? }
        end
      end
    end

    def each(allow_mute=false, &block)
      synchronize do
        if allow_mute
          @_metrics.each(&block)
        else
          @_metrics.select { |k, v| !v.mute? }.each(&block)
        end
      end
    end

    def load(data)
      return unless data
      return if data.empty?
      synchronize do
        if data.key?(:defaults)
          @_opts = data[:defaults].clone
        end
        if data.key?(:metrics)
          types = Metric.descendants.map{ |x| x.name.split("::").last }
          data[:metrics].each do |k, v|
            next unless v.key?(:type)
            next unless types.include?(v[:type])
            @_metrics[k] = Object.const_get("Salus::" + v[:type]).new(@_opts)
            @_metrics[k].load(v)
          end
        end
        if data.key?(:groups)
          @_cache = data[:groups]
        end
      end
    end

    def save
      to_h
    end

    def to_h
      ret = {}
      synchronize do
        unless @_metrics.empty?
          ret[:metrics] = {}
          @_metrics.each { |k, v| ret[:metrics][k] = v.to_h }
        end
        unless @_groups.empty?
          ret[:groups]  = {}
          @_groups.each  { |k, v| ret[:groups][k]  = v.to_h }
        end
        unless @_opts.empty?
          ret[:defaults] = @_opts
        end
        ret
      end
    end

    def tick
      instance_eval(&@_proc)
      @_groups.each do |k, v|
        v.tick
      end
      @_cache.clear unless @_cache.empty?
    end
  end
end
