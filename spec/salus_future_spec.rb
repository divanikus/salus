require "spec_helper"

RSpec.describe Salus::Future do
  it 'delivers a value properly' do
    f = Salus::Future.new {
      sleep 0.02
      42
    }

    expect(f.value).to eq(42)
  end

  it 'properly checks if anything has been delivered' do
    f = Salus::Future.new {
      sleep 0.02

      42
    }

    expect(f.delivered?).to eq(false)
    sleep 0.03
    expect(f.delivered?).to eq(true)
  end

  it 'does not block when a timeout is passed' do
    f = Salus::Future.new {
      sleep 0.02

      42
    }

    expect(f.value(0)).to be_nil
  end
end
