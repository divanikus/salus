module Salus
  class Counter < Metric
    INT32_MAX = 2**32
    def initialize(defaults={})
      super(defaults)
      option :maximum, Numeric
      validate(:maximum, @opts[:maximum]) if @opts.key?(:maximum)
    end

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
        dv = if @values[1].value < @values[0].value
          w = @values[0].value < INT32_MAX ? 32 : 64
          (2**w - @values[0].value + @values[1].value)
        else
          (@values[1].value - @values[0].value)
        end
        r = (dt == 0) ? nil : (dv / dt)
        if @opts.key?(:maximum) && !r.nil? && r > @opts[:maximum]
          nil
        else
          r
        end
      end
    end
  end
end
