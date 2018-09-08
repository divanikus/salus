module Salus
  class ZabbixSenderRenderer < BaseRenderer
    def render(data)
      # Top level groups are considered hostnames
      result = {}
      data.each do |hostname, group|
        iterate(group) do |name, metric|
          unless metric.timestamp.nil?
            timestamp = metric.timestamp.to_i
            name  = name.gsub(/\.\[/, '[')
            name  = name.to_json if (name.match(/\s/))
            value = metric.value
            value = '""' if value.nil?
            value = value.to_json if (!value.nil? && metric.is_a?(Salus::Text))

            result[timestamp] = [] unless result.key?(timestamp)
            result[timestamp] << "#{hostname.dump} #{name} #{timestamp} #{value}"
          end
        end
      end
      # Zabbix requires timestamps to be sorted
      result.keys.sort.each { |k| STDOUT.puts result[k] }
    end
  end
end
