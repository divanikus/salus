module Salus
  class Text < Metric
    STORAGE_DEPTH = 1
    def initialize(defaults={})
      super(defaults)
      option :value, Symbol, String
    end
  end
end
