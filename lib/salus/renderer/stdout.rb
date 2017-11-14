module Salus
  class StdoutRenderer < BaseRenderer
    def initialize(opts={})
      super(opts)
      @precision = opts.fetch(:precision, 2)
    end

    def render(data)
      iterate(data) do |name, metric|
        value = metric.value.nil? ? "" : "%.#{@precision}f" % metric.value
        STDOUT.puts "[#{Time.at(metric.timestamp)}] #{name} - #{value}" unless metric.timestamp.nil?
      end
    end
  end
end
