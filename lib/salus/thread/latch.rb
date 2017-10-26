module Salus
  # Based on code from https://github.com/ruby-concurrency/concurrent-ruby/
  class CountDownLatch
    include Lockable

    def initialize(to)
      synchronize { @count = to.to_i }
      raise ArgumentError, "cannot count down from negative integer" unless @count >= 0
    end

    def count_down
      synchronize do
        @count -= 1 if @count >  0
        broadcast   if @count == 0
      end
    end

    def count
      synchronize { @count }
    end

    def wait(timeout=nil)
      synchronize do
        wait_until(timeout) { @count == 0 }
      end
    end
  end
end
