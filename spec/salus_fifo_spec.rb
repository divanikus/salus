require "spec_helper"

RSpec.describe Salus::Fifo do
  it "has fixed length" do
    f = Salus::Fifo.new(3)
    f << 1 << 2 << 3 << 4
    expect(f.length).to eq(3)
  end

  it "removes first" do
    f = Salus::Fifo.new(2)
    f << 1 << 2 << 3
    expect(f[0]).to eq(2)
    expect(f[1]).to eq(3)
  end
end
