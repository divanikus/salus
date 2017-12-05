module Salus
  class ZabbixBulkRenderer < BaseRenderer
    def render(data)
      # Zabbix 3.4+ with preprocessor
      iterate(data) do |name, metric|
        name  = name.gsub(/\.\[/, '[')
        value = metric.value
        STDOUT.puts "#{name}\t#{value}" unless metric.timestamp.nil?
      end
    end
  end
end
