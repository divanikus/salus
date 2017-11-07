module Salus
  class Derive < Metric
    def initialize(defaults={})
      super(defaults)
      option :minimum, Numeric
      validate(:minimum, @opts[:minimum]) if @opts.key?(:minimum)
    end

    protected
    def calc
      super
      @last_calced_value = nil

      if @values.length < STORAGE_DEPTH
        return
      elsif @values[0].expired?(@values[1].timestamp)
        return
      elsif !@values[0].value.is_a?(Numeric)
        return
      elsif !@values[1].value.is_a?(Numeric)
        return
      end

      @last_calced_value = begin
        dt = (@values[1].timestamp - @values[0].timestamp)
        dv = (@values[1].value - @values[0].value)
        r = (dt == 0) ? nil : (dv / dt)
        if @opts.key?(:minimum) && !r.nil? && r < @opts[:minimum]
          nil
        else
          r
        end
      end
    end
  end
end
