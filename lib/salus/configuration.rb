module Salus
  module Configuration
    # An array of valid keys in the options hash when configuring a Gitlab::API.
    VALID_OPTIONS_KEYS = %i(min_threads max_threads interval tick_timeout render_timeout logger).freeze

    # @private
    attr_accessor(*VALID_OPTIONS_KEYS)

    # Sets all configuration options to their default values
    # when this module is extended.
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block.
    def configure
      yield self
    end

    # Creates a hash of options and their values.
    def options
      VALID_OPTIONS_KEYS.inject({}) do |option, key|
        option.merge!(key => send(key))
      end
    end

    # Resets all configuration options to the defaults.
    def reset
      self.min_threads = CPU.count / 2
      self.min_threads = 1 if self.min_threads == 0
      self.max_threads = CPU.count * 2
      self.interval = 30
      self.tick_timeout   = 15
      self.render_timeout = 10
      self.logger   = Logger.new(STDERR)
    end
  end
end
