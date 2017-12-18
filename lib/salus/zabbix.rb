require "json"

module Salus
  class << self
    @@_discovers = {}

    def discover(name, &block)
      raise ArgumentError, "Block should be given" unless block_given?
      @@_discovers[name] = block
    end

    def discovers
      @@_discovers
    end

    def discovery(name)
      return unless @@_discovers.key?(name)
      data = []
      @@_discovers[name].call(data)
      {data: data}.to_json
    end

    reset = instance_method(:reset)
    define_method(:reset) do
      reset.bind(self).()
      @@_discovers = {}
      nil
    end
  end
end
