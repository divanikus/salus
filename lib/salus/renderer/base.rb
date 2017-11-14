module Salus
  class BaseRenderer
    include Logging
    def self.inherited(subclass)
      @@descendants ||= []
      @@descendants << subclass
    end

    def self.descendants
      @@descendants || []
    end

    def initialize(opts={})
      @separator  = opts.fetch(:separator, '.')
      @allow_mute = opts.fetch(:allow_mute, false)
    end

    def render(data)
      # Implement renderer
      raise "Unimplemented"
    end

    def iterate(node, prefix="", &block)
      case node
      when Hash
        node.each do |name, item|
          iterate(item, join_name(prefix, name), &block)
        end
      when Salus::Group
        node.each(@allow_mute) do |name, metric|
          iterate(metric, join_name(prefix, name), &block)
        end
        if node.has_subgroups?
          node.groups.each do |name, group|
            iterate(group, join_name(prefix, name), &block)
          end
        end
      when Salus::Metric
        block.call(prefix, node)
      else
        log WARN, "Unknown node type #{node.class}"
      end
    end

    protected
    def join_name(prefix, name)
      prefix + (prefix.empty? ? '' : @separator) + name
    end
  end
end
