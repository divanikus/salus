module Salus
  class Renderer
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

  class StdoutRenderer < Renderer
    def initialize(opts={})
      super(opts)
      @precision = opts.fetch(:precision, 2)
    end

    def render(data)
      iterate(data) do |name, metric|
        value = metric.value.nil? ? "" : "%.#{@precision}f" % metric.value
        STDOUT.puts "[#{Time.at(metric.timestamp)}] #{name} - #{value}"
      end
    end
  end

  class BlockRenderer < Renderer
    def initialize(opts={}, &block)
      super(opts)
      raise ArgumentError, "Block must be supplied" unless block_given?
      @proc = block
    end

    def render(data)
      instance_exec(data, &@proc)
    end
  end
end
