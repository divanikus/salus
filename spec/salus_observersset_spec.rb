require "spec_helper"

RSpec.describe Salus::ObserversSet do
  let (:observer_set) { Salus::ObserversSet.new }
  let (:observer) { double('observer') }
  let (:another_observer) { double('another observer') }

  describe '#add' do
    context 'with arguments' do
      it 'should return the observer' do
        expect(observer_set.add(observer, :a_method)).to eq(observer)
      end
    end

    context 'with a block' do
      it 'should return the observer based on a block' do
        observer = observer_set.add { :block }
        expect(observer.call).to eq(:block)
      end
    end
  end

  describe '#notify' do
    it 'should return the observer set' do
      expect(observer_set.notify).to be(observer_set)
    end

    context 'with a single observer' do
      it 'should update a registered observer without arguments' do
        expect(observer).to receive(:update).with(no_args)

        observer_set.add(observer)

        observer_set.notify
      end

      it 'should update a registered observer with arguments' do
        expect(observer).to receive(:update).with(1, 2, 3)

        observer_set.add(observer)

        observer_set.notify(1, 2, 3)
      end

      it 'should notify an observer using the chosen method' do
        expect(observer).to receive(:another_method).with('a string arg')

        observer_set.add(observer, :another_method)

        observer_set.notify('a string arg')
      end

      it 'should notify an observer once using the last added method' do
        expect(observer).to receive(:another_method).with(any_args).never
        expect(observer).to receive(:yet_another_method).with('a string arg')

        observer_set.add(observer, :another_method)
        observer_set.add(observer, :yet_another_method)

        observer_set.notify('a string arg')
      end

      it 'should notify an observer from a block' do
        notification = double
        expect(notification).to receive(:catch)

        observer_set.add {|arg| arg.catch }
        observer_set.notify notification
      end

      it 'can be called many times' do
        expect(observer).to receive(:update).with(:an_arg).twice
        expect(observer).to receive(:update).with(no_args).once

        observer_set.add(observer)

        observer_set.notify(:an_arg)
        observer_set.notify
        observer_set.notify(:an_arg)
      end
    end

    context 'with many observers' do
      it 'should notify all observer using the chosen method' do
        expect(observer).to receive(:a_method).with(4, 'a')
        expect(another_observer).to receive(:update).with(4, 'a')

        observer_set.add(observer, :a_method)
        observer_set.add(another_observer)

        observer_set.notify(4, 'a')
      end
    end

    context 'with a block' do
      before(:each) do
        allow(observer).to receive(:update).with(any_args)
        allow(another_observer).to receive(:update).with(any_args)
      end

      it 'calls the block once for every observer' do
        counter = double('block call counter')
        expect(counter).to receive(:called).with(no_args).exactly(2).times

        observer_set.add(observer)
        observer_set.add(another_observer)

        observer_set.notify{ counter.called }
      end

      it 'passes the block return value to the update method' do
        expect(observer).to receive(:update).with(1, 2, 3, 4)
        observer_set.add(observer)
        observer_set.notify{ [1, 2, 3, 4] }
      end

      it 'accepts blocks returning a single value' do
        expect(observer).to receive(:update).with(:foo)
        observer_set.add(observer)
        observer_set.notify{ :foo }
      end

      it 'accepts block return values that include arrays' do
        expect(observer).to receive(:update).with(1, [2, 3], 4)
        observer_set.add(observer)
        observer_set.notify{ [1, [2, 3], 4] }
      end

      it 'raises an exception if given both arguments and a block' do
        observer_set.add(observer)

        expect {
          observer_set.notify(1, 2, 3, 4){ nil }
        }.to raise_error(ArgumentError)
      end
    end
  end

  context '#count' do
    it 'should be zero after initialization' do
      expect(observer_set.count).to eq 0
    end

    it 'should be 1 after the first observer is added' do
      observer_set.add(observer)
      expect(observer_set.count).to eq 1
    end

    it 'should be 1 if the same observer is added many times' do
      observer_set.add(observer)
      observer_set.add(observer, :another_method)
      observer_set.add(observer, :yet_another_method)

      expect(observer_set.count).to eq 1
    end

    it 'should be equal to the number of unique observers' do
      observer_set.add(observer)
      observer_set.add(another_observer)
      observer_set.add(double('observer 3'))
      observer_set.add(double('observer 4'))

      expect(observer_set.count).to eq 4
    end
  end

  describe '#delete' do
    it 'should not notify a deleted observer' do
      expect(observer).to receive(:update).never

      observer_set.add(observer)
      observer_set.delete(observer)

      observer_set.notify
    end

    it 'can delete a non added observer' do
      observer_set.delete(observer)
    end

    it 'should return the observer' do
      expect(observer_set.delete(observer)).to be(observer)
    end
  end

  describe '#delete_all' do
    it 'should remove all observers' do
      expect(observer).to receive(:update).never
      expect(another_observer).to receive(:update).never

      observer_set.add(observer)
      observer_set.add(another_observer)

      observer_set.delete_all

      observer_set.notify
    end

    it 'should return the observer set' do
      expect(observer_set.delete_all).to be(observer_set)
    end
  end

  describe '#notify_and_delete' do
    before(:each) do
      observer_set.add(observer, :a_method)
      observer_set.add(another_observer)

      expect(observer).to receive(:a_method).with('args').once
      expect(another_observer).to receive(:update).with('args').once
    end

    it 'should notify all observers' do
      observer_set.notify_and_delete('args')
    end

    it 'should clear observers' do
      observer_set.notify_and_delete('args')

      expect(observer_set.count).to eq(0)
    end

    it 'can be called many times without any other notification' do
      observer_set.notify_and_delete('args')
      observer_set.notify_and_delete('args')
      observer_set.notify_and_delete('args')
    end

    it 'should return the observer set' do
      expect(observer_set.notify_and_delete('args')).to be(observer_set)
    end
  end
end
