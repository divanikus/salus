require "spec_helper"

RSpec.describe Salus::Delta do
  context "without ttl" do
    let(:metric) { Salus::Delta.new }

    it "validates types" do
      expect{metric.push minimum: "just a test"}.to raise_error(ArgumentError)
    end

    it "counts deltas" do
      metric.push value: 10, timestamp: 0
      expect(metric.value).to eq(nil)
      metric.push value: 20, timestamp: 10
      expect(metric.value).to eq(10)
      metric.push value: 100, timestamp: 20
      expect(metric.value).to eq(80)
    end

    it "returns nil rate for dt == 0" do
      metric.push value: 10, timestamp: 10
      metric.push value: 20, timestamp: 10
      expect(metric.value).to eq(nil)
    end

    it "returns nil if one value is nil" do
      metric.push value: 10, timestamp: 0
      metric.push value: nil, timestamp: 10
      expect(metric.value).to eq(nil)
    end

    it "returns nil if delta is less than minimum" do
      metric.push value: 200, timestamp: 0, minimum: 0
      metric.push value: 1000, timestamp: 10
      expect(metric.value).to eq(800)
      metric.push value: 1, timestamp: 20
      expect(metric.value).to eq(nil)
    end
  end

  context "with ttl" do
    let(:metric) { Salus::Delta.new }

    it "returns nil if previous value is expired" do
      metric.push value: 0, timestamp: 0, ttl: 10
      metric.push value: 5, timestamp: 5, ttl: 10
      expect(metric.value).to eq(5)
      metric.push value: 100, timestamp: 100, ttl: 10
      expect(metric.value).to eq(nil)
    end
  end
end
