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
    METRIC_TYPES = [:absolute, :counter, :derive, :gauge, :text]
    def_delegators :@metrics, :[], :keys, :key?, :values, :value_at, :fetch, :length, :delete, :each, :empty?

    def initialize(title, &block)
      @title   = title
      @metrics = {}
      @proc    = block
    end

    def method_missing(m, *args, &block)
      raise "Unknown method" unless METRIC_TYPES.include?(m)

      title = args.select { |x| x.is_a?(String) }.first
      raise "Metric needs a name!" if title.nil?

      unless @metrics.key?(title)
        @metrics[title] = Object.const_get(m.capitalize).new
      end

      @metrics[title].push(*args, &block)
    end

    def value(title)
      @metrics.key?(title) ? @metrics[title].value : nil
    end

    def tick
      instance_eval(&@proc)
    end

    def run(&block)
      tick
      @metrics.each do |k, m|
        v = m.value
        t = m.timestamp
        yield(@title, k, t, v) unless m.mute?
      end
    end
  end
end
