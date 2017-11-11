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

    def_delegators :@metrics, :[], :key?, :values_at, :fetch, :length, :delete, :empty?

    def initialize(defaults={}, &block)
      @metrics = {}
      @groups  = {}
      @cache   = {}
      @proc    = block
      @opts    = defaults.clone
    end

    Metric.descendants.each do |m|
      sym = m.name.split('::').last.downcase.to_sym
      define_method(sym) do |*args, &blk|
        title = args.select { |x| x.is_a?(String) }.first
        raise ArgumentError, "Metric needs a name!" if title.nil?

        unless @metrics.key?(title)
          @metrics[title] = m.new(@opts)
        end

        @metrics[title].push(*args, &blk)
      end
    end

    def on_win?
      Salus.on_win?
    end

    def default(*args)
      opts   = args.select { |x| x.is_a?(Hash) }.first
      opts ||= {}
      opts.each do |k, v|
        next if [:value, :timestamp].include?(k)
        @opts[k] = v
      end
    end

    def group(title, &block)
      synchronize do
        unless @groups.key?(title)
          @groups[title] = Group.new(@opts, &block)
          if @cache.key?(title)
            @groups[title].load(@cache[title])
            @cache.delete(title)
          end
        end
      end
    end

    def groups
      synchronize { @groups }
    end

    def has_subgroups?
      synchronize { !@groups.empty? }
    end

    def value(title)
      synchronize { @metrics.key?(title) ? @metrics[title].value : nil }
    end

    def keys(allow_mute=false)
      synchronize do
        if allow_mute
          @metrics.keys
        else
          @metrics.keys.select { |x| !@metrics[x].mute? }
        end
      end
    end

    def values(allow_mute=false)
      synchronize do
        if allow_mute
          @metrics.values
        else
          @metrics.values.select { |x| !x.mute? }
        end
      end
    end

    def each(allow_mute=false, &block)
      synchronize do
        if allow_mute
          @metrics.each(&block)
        else
          @metrics.select { |k, v| !v.mute? }.each(&block)
        end
      end
    end

    def load(data)
      return if data.nil?
      return if data.empty?
      synchronize do
        if data.key?(:defaults)
          @opts = data[:defaults].clone
        end
        if data.key?(:metrics)
          types = Metric.descendants.map{ |x| x.name.split("::").last }
          data[:metrics].each do |k, v|
            next unless v.key?(:type)
            next unless types.include?(v[:type])
            @metrics[k] = Object.const_get("Salus::" + v[:type]).new(@opts)
            @metrics[k].load(v)
          end
        end
        if data.key?(:groups)
          @cache = data[:groups]
        end
      end
    end

    def save
      to_h
    end

    def to_h
      ret = {}
      synchronize do
        unless @metrics.empty?
          ret[:metrics] = {}
          @metrics.each { |k, v| ret[:metrics][k] = v.to_h }
        end
        unless @groups.empty?
          ret[:groups]  = {}
          @groups.each  { |k, v| ret[:groups][k]  = v.to_h }
        end
        unless @opts.empty?
          ret[:defaults] = @opts
        end
        ret
      end
    end

    def tick
      instance_eval(&@proc)
      @groups.each do |k, v|
        v.tick
      end
      @cache.clear unless @cache.empty?
    end
  end
end
