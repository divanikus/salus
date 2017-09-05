module Salus
  class Fifo
    extend Forwardable
    def_delegators :@data, :[], :each, :length, :empty?, :clear, :last, :first, :hash

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

    def initialize
      @values = Fifo.new(STORAGE_DEPTH)
      @opts   = {}
      @attributes = {}
      @last_calced_value = nil
      @last_calced_ts    = nil
      @needs_update      = true

      option :mute, TrueClass, FalseClass
      option :value, Numeric
      option :timestamp, Numeric
      option :ttl, Numeric
    end

    def mute?
      @opts[:mute] || false
    end

    def push(*args, &block)
      opts   = args.select { |x| x.is_a?(Hash) }.first
      opts ||= {}

      opts.each do |k, v|
        validate(k, v)
        @opts[k] = v unless [:value, :ttl, :timestamp].include?(k)
      end

      if block_given?
        v = begin
          yield
        rescue
          nil
        end
        validate(:value, v)
        opts[:value] = v
      end

      @values << Value.new(opts[:value], opts[:timestamp] || Time.now.to_f, opts[:ttl])
      @needs_update = true
    end

    def timestamp
      calc if needs_update?
      @last_calced_ts
    end

    def value
      calc if needs_update?
      @last_calced_value
    end

    def expired?(ts=nil)
      if @values.empty?
        true
      else
        @values.last.expired?(ts)
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

    def needs_update?
      @needs_update
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
