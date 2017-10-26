module Salus
  # Monotonic time if possible
  class MonotonicTime
    # Get monotonic time
    if defined?(Process::CLOCK_MONOTONIC)
      def self.get
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    else
      def self.get
        Time.now.to_f
      end
    end
  end
end
