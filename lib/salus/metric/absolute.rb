module Salus
  class Absolute < Metric
    def calc
      super
      @last_calced_value = nil

      if @values.length < STORAGE_DEPTH
        return
      elsif @values[0].expired?(@values[1].timestamp)
        return
      elsif !@values[1].value.is_a?(Numeric)
        return
      end

      @last_calced_value = begin
        dt = (@values[1].timestamp - @values[0].timestamp)
        (dt == 0) ? nil : (@values[1].value / dt)
      end
    end
  end
end
