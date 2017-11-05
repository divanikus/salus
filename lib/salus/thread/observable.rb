module Salus
  # Loosely based on code from https://github.com/ruby-concurrency/concurrent-ruby/
  class ObserversSet
    include Lockable

    def initialize
      synchronize { @observers = {} }
    end

    def add(observer=nil, func=:update, &block)
      if observer.nil? && block.nil?
        raise ArgumentError, 'should pass observer as a first argument or block'
      elsif observer && block
        raise ArgumentError, 'cannot provide both an observer and a block'
      end

      if block
        observer = block
        func = :call
      end

      synchronize do
        new_observers = @observers.dup
        new_observers[observer] = func
        @observers = new_observers
        observer
      end
    end

    def delete(observer)
      synchronize do
        new_observers = @observers.dup
        new_observers.delete(observer)
        @observers = new_observers
        observer
      end
    end

    def delete_all
      synchronize { @observers = {} }
      self
    end

    def notify(*args, &block)
      obs = synchronize { @observers }
      notify_to(obs, *args, &block)
      self
    end

    def notify_and_delete(*args, &block)
      old = synchronize do
        old =  @observers
        @observers = {}
        old
      end
      notify_to(old, *args, &block)
      self
    end

    def count
      synchronize { @observers.count }
    end

    private
    def notify_to(obs, *args, &block)
      raise ArgumentError.new('cannot give arguments and a block') if block_given? && !args.empty?
      obs.each do |observer, function|
        args = yield if block_given?
        observer.send(function, *args)
      end
    end
  end

  module Observable
    def add_observer(observer=nil, func=:update, &block)
      observers.add(observer, func, &block)
    end

    def with_observer(observer=nil, func=:update, &block)
      observers.add(observer, func, &block)
      self
    end

    def count_observers
      observers.count
    end

    def delete_observer(observer)
      observers.delete(observer)
    end

    def delete_observers
      observers.delete_all
      self
    end

    def notify_observers(*args, &block)
      observers.notify(*args, &block)
      self
    end

    def notify_and_delete_observers(*args, &block)
      observers.notify_and_delete(*args, &block)
      self
    end

    protected
    def observers
      @__observers__ ||= ObserversSet.new
      @__observers__
    end

    def observers=(obs)
      @__observers__ = obs
    end
  end
end
