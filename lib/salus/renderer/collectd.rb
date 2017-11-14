module Salus
  class CollectdRenderer < BaseRenderer
    def initialize(opts={})
      opts[:separator] = opts.fetch(:separator, '/')
      super(opts)
    end

    def render(data)
      hostname = ENV.fetch('COLLECTD_HOSTNAME', 'localhost')
      options  = ENV.key?('COLLECTD_INTERVAL') ? "interval=#{ENV['COLLECTD_INTERVAL']} " : ''
      iterate(data) do |name, metric|
        # Text metrics are unsupported
        next if metric.is_a? Salus::Text
        unless metric.timestamp.nil?
          # Effectively all salus metrics are gauges for collectd, with exception to text
          STDOUT.puts "PUTVAL #{hostname}#{@separator}#{name} #{options}#{metric.timestamp.to_i}:#{metric.value.nil? ? 'U' : metric.value}"
        end
      end
    end
  end
end
