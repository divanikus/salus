module Salus
  class ZabbixBulkRenderer < BaseRenderer
    def initialize(opts={})
      super(opts)
      @group = opts.fetch(:group, nil)
    end

    def render(data)
      # Zabbix 3.4+ with preprocessor
      result = {}
      re = @group.nil? ? /^/ : /^#{Regexp.escape(@group)}\./
      iterate(data) do |name, metric|
        next unless name.match(re)
        name  = name.sub(re, '')
        name  = name.gsub(/\.\[/, '[')
        result[name] = metric.value unless metric.timestamp.nil?
      end
      STDOUT.puts result.to_json
    end
  end
end
