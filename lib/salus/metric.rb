module Salus
  class Fifo
    extend Forwardable
    def_delegators :@data, :[], :each, :length, :empty?, :clear, :last, :first, :hash, :map

    def initialize(maxlen)
      @maxlen = maxlen
      @data   = []
    end

    def <<(value)
      @data << value
      @data.shift if @data.length > @maxlen
      self
    end
  end

  class Metric
    include Logging
    include Lockable
    STORAGE_DEPTH = 2

    Value = Struct.new(:value, :timestamp, :ttl) do
      def expired?(ts=nil)
        return false if ttl.nil?
        ts ||= Time.now.to_f
        ts > (timestamp + ttl)
      end
    end

    def self.inherited(subclass)
      @@descendants ||= []
      @@descendants << subclass
    end

    def self.descendants
      @@descendants || []
    end

    def initialize(defaults={})
      @values = Fifo.new(self.class::STORAGE_DEPTH)
      @opts   = defaults.clone
      @attributes = {}
      @last_calced_value = nil
      @last_calced_ts    = nil
      @needs_update      = true

      option :mute, TrueClass, FalseClass
      option :value, Numeric
      option :timestamp, Numeric
      option :ttl, Numeric

      @opts.each do |k, v|
        validate(k, v)
      end
    end

    def mute?
      synchronize { @opts[:mute] || false }
    end

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

        @values << Value.new(opts[:value], opts[:timestamp] || Time.now.to_f, opts[:ttl] || @opts[:ttl])
        @needs_update = true
      end
    end

    def timestamp
      synchronize do
        calc if @needs_update
        @last_calced_ts
      end
    end

    def value
      synchronize do
        calc if @needs_update
        @last_calced_value
      end
    end

    def ttl
      synchronize do
        @values.empty? ? nil : @values.last.ttl
      end
    end

    def expired?(ts=nil)
      synchronize do
        if @values.empty?
          true
        else
          @values.last.expired?(ts)
        end
      end
    end

    def load(data)
      return if data.nil?
      return if data.empty?
      return unless data.key?(:values)
      synchronize do
        if data.key?(:mute)
          @opts[:mute] = data[:mute]
        end
        data[:values].each do |v|
          @values << Value.new(v[:value], v[:timestamp], v[:ttl])
        end
        @needs_update  = true
      end
    end

    def save
      to_h
    end

    def to_h
      return {} if @values.empty?
      synchronize do
        {
          type: self.class.name.split('::').last,
          mute: mute?,
          values: @values.map { |x| x.to_h }
        }
      end
    end

    protected
    def option(key, *types)
      @attributes[key] = types
    end

    def validate(key, value)
      return if value.nil?
      return unless @attributes.key?(key)
      unless @attributes[key].any? { |t| value.is_a?(t) }
        raise ArgumentError, "Option #{key} should be #{@attributes[key].join(" or ")}"
      end
      value
    end

    def calc
      if @values.empty?
        @last_calced_ts    = nil
        @last_calced_value = nil
        @needs_update      = true
      else
        @last_calced_ts    = @values.last.timestamp
        @last_calced_value = @values.last.value
        @needs_update      = false
      end
    end
  end
end
