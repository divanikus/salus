module Salus
  class StdoutRenderer < BaseRenderer
    def initialize(opts={})
      super(opts)
      @precision = opts.fetch(:precision, 2)
    end

    def render(data)
      iterate(data) do |name, metric|
        value = metric.value
        unless metric.is_a?(Salus::Text)
          value = "%.#{@precision}f" % value unless value.nil?
        end
        STDOUT.puts "[#{Time.at(metric.timestamp)}] #{name} - #{value}" unless metric.timestamp.nil?
      end
    end
  end
end
