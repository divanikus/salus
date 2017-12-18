module Salus
  class ZabbixBulkRenderer < BaseRenderer
    def initialize(opts={})
      super(opts)
      @group = opts.fetch(:group, nil)
    end

    def render(data)
      # Zabbix 3.4+ with preprocessor
      result = {}
      re = @group.nil? ? // : /^#{Regexp.escape(@group)}\./
      iterate(data) do |name, metric|
        next unless name.match(re)
        name  = name.sub(re, '')
        name  = name.gsub(/\.\[/, '[')

        unless metric.timestamp.nil?
          parts = name.split(/\./)
          node  = result
          parts[0...-1].each do |part|
            node[part] = {} unless node.key?(part)
            node = node[part]
          end
          node[parts.last] = metric.value
        end
      end
      STDOUT.puts result.to_json
    end
  end
end
