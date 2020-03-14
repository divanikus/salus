module Salus
  class Accumulator < Metric
    STORAGE_DEPTH = 1

    def push(opts={}, &block)
      opts = {} unless opts.is_a?(Hash)

      synchronize do
        opts.each do |k, v|
          validate(k, v)
          @opts[k] = v unless [:value, :ttl, :timestamp].include?(k)
        end

        if block_given?
          v = begin
            yield
          rescue Exception => e
            log DEBUG, e
            nil
          end
          validate(:value, v)
          opts[:value] = v
        end

        prev  = @values.empty? ? 0 : (@values.last.value || 0)
        curr  = opts[:value] || 0
        
        @values << Value.new(prev+curr, opts[:timestamp] || Time.now.to_f, opts[:ttl] || @opts[:ttl])
        @needs_update = true
      end
    end
  end
end
  