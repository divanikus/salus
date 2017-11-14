require "json"

module Salus
  class << self
    @@discovers = {}

    def discover(name, &block)
      raise ArgumentError, "Block should be given" unless block_given?
      @@discovers[name] = block
    end

    def discovers
      @@discovers
    end

    def discovery(name)
      return unless @@discovers.key?(name)
      data = []
      @@discovers[name].call(data)
      {data: data}.to_json
    end

    reset = instance_method(:reset)
    define_method(:reset) do
      reset.bind(self).()
      @@discovers = {}
      nil
    end
  end
end
