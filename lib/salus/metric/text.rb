module Salus
  class Text < Metric
    STORAGE_DEPTH = 1
    def initialize
      super
      option :value, Symbol, String
    end
  end
end
