module Salus
  class BlockRenderer < BaseRenderer
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
