module Salus
  class ZabbixBulkRenderer < BaseRenderer
    def initialize(opts={})
      super(opts)
      @group = opts.fetch(:group, nil)
    end

    def render(data)
      # Zabbix 3.4+ with preprocessor
      root = @group.nil? ? data : data.fetch(@group, nil)
      return if root.nil?
      
      iterate(root) do |name, metric|
        name  = name.gsub(/\.\[/, '[')
        value = metric.value
        STDOUT.puts "#{name}\t#{value}" unless metric.timestamp.nil?
      end
    end
  end
end
