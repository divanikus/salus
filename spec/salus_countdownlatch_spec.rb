require "spec_helper"

RSpec.describe Salus::CountDownLatch do
  let(:latch) { Salus::CountDownLatch.new(3) }
  let(:zero_count_latch) { Salus::CountDownLatch.new(0) }

  it 'raises an exception if the initial count is less than zero' do
    expect {
      Salus::CountDownLatch.new(-1)
    }.to raise_error(ArgumentError)
  end

  it 'defaults the count to 1' do
    latch = Salus::CountDownLatch.new
    expect(latch.count).to eq 1
  end


  it 'should be the value passed to the constructor' do
    expect(latch.count).to eq 3
  end

  it 'should be decreased after every count down' do
    latch.count_down
    expect(latch.count).to eq 2
  end

  it 'should not go below zero' do
    5.times { latch.count_down }
    expect(latch.count).to eq 0
  end

  context 'count set to zero' do
    it 'should return true immediately' do
      result = zero_count_latch.wait
      expect(result).to be_truthy
    end

    it 'should return true immediately with timeout' do
      result = zero_count_latch.wait(5)
      expect(result).to be_truthy
    end
  end

  context 'non zero count' do
    it 'should block thread until counter is set to zero' do
      3.times do
        Thread.new { sleep(0.1); latch.count_down }
      end

      result = latch.wait
      expect(result).to be_truthy
      expect(latch.count).to eq 0
    end

    it 'should block until counter is set to zero with timeout' do
      3.times do
        Thread.new { sleep(0.1); latch.count_down }
      end

      result = latch.wait(1)
      expect(result).to be_truthy
      expect(latch.count).to eq 0

    end

    it 'should block until timeout and return false when counter is not set to zero' do
      result = latch.wait(0.1)
      expect(result).to be_falsey
      expect(latch.count).to eq 3
    end
  end
end
