require "spec_helper"

RSpec.describe Salus::Accumulator do
  context "without ttl" do
    let(:metric) { Salus::Accumulator.new }

    it "accumulates values as pushed" do
      metric.push value: 10.0
      expect(metric.value).to eq(10.0)
      metric.push value: 20.0
      expect(metric.value).to eq(30.0)
      metric.push value: 30.0
      expect(metric.value).to eq(60.0)
    end
  end
end
