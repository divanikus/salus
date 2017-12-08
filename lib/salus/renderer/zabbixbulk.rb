module Salus
  class ZabbixBulkRenderer < BaseRenderer
    def initialize(opts={})
      super(opts)
      @group = opts.fetch(:group, nil)
    end

    def render(data)
      # Zabbix 3.4+ with preprocessor
      iterate(data) do |name, metric|
        next unless name.match(/^#{@group}\./)
        name  = name.sub(/^#{@group}\./, '')
        name  = name.gsub(/\.\[/, '[')
        value = metric.value
        STDOUT.puts "#{name}\t#{value}" unless metric.timestamp.nil?
      end
    end
  end
end
