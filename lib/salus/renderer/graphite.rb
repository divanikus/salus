module Salus
  class GraphiteRenderer < BaseRenderer
    def render(data)
      iterate(data) do |name, metric|
        # Text metrics are unsupported
        next if metric.is_a? Salus::Text
        # Nil value means nothing collected, so just ignore it
        unless metric.value.nil? || metric.timestamp.nil?
          STDOUT.puts "#{name} #{metric.value} #{metric.timestamp.to_i}"
        end
      end
    end
  end
end
