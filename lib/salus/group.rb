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
    def_delegators :@metrics, :key?, :values_at, :fetch, :length, :delete, :empty?
    attr_reader :title

    def initialize(title, &block)
      @title   = title
      @metrics = {}
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

    def [](key)
      value(key)
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

    def tick
      instance_eval(&@proc)
    end
  end
end
