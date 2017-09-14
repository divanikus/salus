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
    def_delegators :@metrics, :[], :key?, :values_at, :fetch, :length, :delete, :empty?
    attr_reader :title

    def initialize(&block)
      @metrics = {}
      @groups  = {}
      @cache   = {}
      @proc    = block
    end

    Metric.descendants.each do |m|
      sym = m.name.split('::').last.downcase.to_sym
      define_method(sym) do |*args, &blk|
        title = args.select { |x| x.is_a?(String) }.first
        raise ArgumentError, "Metric needs a name!" if title.nil?

        unless @metrics.key?(title)
          @metrics[title] = m.new
        end

        @metrics[title].push(*args, &blk)
      end
    end

    def group(title, &block)
      unless @groups.key?(title)
        @groups[title] = Group.new(&block)
        if @cache.key?(title)
          @groups[title].load(@cache[title])
          @cache.delete(title)
        end
      end
    end

    def groups
      @groups
    end

    def has_subgroups?
      !@groups.empty?
    end

    def value(title)
      @metrics.key?(title) ? @metrics[title].value : nil
    end

    def keys(allow_mute=false)
      if allow_mute
        @metrics.keys
      else
        @metrics.keys.select { |x| !@metrics[x].mute? }
      end
    end

    def values(allow_mute=false)
      if allow_mute
        @metrics.values
      else
        @metrics.values.select { |x| !x.mute? }
      end
    end

    def each(allow_mute=false, &block)
      if allow_mute
        @metrics.each(&block)
      else
        @metrics.select { |k, v| !v.mute? }.each(&block)
      end
    end

    def load(data)
      return if data.nil?
      return if data.empty?
      if data.key?(:metrics)
        types = Metric.descendants.map{ |x| x.name.split("::").last }
        data[:metrics].each do |k, v|
          next unless v.key?(:type)
          next unless types.include?(v[:type])
          @metrics[k] = Object.const_get("Salus::" + v[:type]).new
          @metrics[k].load(v)
        end
      end
      if data.key?(:groups)
        @cache = data[:groups]
      end
    end

    def save
      to_h
    end

    def to_h
      ret = {}
      unless @metrics.empty?
        ret[:metrics] = {}
        @metrics.each { |k, v| ret[:metrics][k] = v.to_h }
      end
      unless @groups.empty?
        ret[:groups]  = {}
        @groups.each  { |k, v| ret[:groups][k]  = v.to_h }
      end
      ret
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
