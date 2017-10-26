module Salus
  # Based on code from https://github.com/ruby-concurrency/concurrent-ruby/
  module Lockable
    def synchronize
      if __lock.owned?
        yield
      else
        __lock.synchronize { yield }
      end
    end

    def signal
      __condition.signal
      self
    end

    def broadcast
      __condition.broadcast
      self
    end

    def wait_until(timeout=nil, &condition)
      if timeout
        wait_until = MonotonicTime.get + timeout
        loop do
          now = MonotonicTime.get
          res = condition.call
          return res if now >= wait_until || res
          __wait(wait_until - now)
        end
      else
        __wait(timeout) until condition.call
        true
      end
    end

    def wait(timeout)
      __wait(timeout)
    end

    protected
    def __lock
      @__lock__ = ::Mutex.new unless defined? @__lock__
      @__lock__
    end

    def __condition
      @__condition__ = ::ConditionVariable.new unless defined? @__condition__
      @__condition__
    end

    def __wait(timeout=nil)
      __condition.wait __lock, timeout
    end
  end
end
