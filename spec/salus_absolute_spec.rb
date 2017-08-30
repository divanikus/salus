require "spec_helper"

RSpec.describe Salus::Absolute do
  context "without ttl" do
    let(:metric) { Salus::Absolute.new }

    it "counts rates" do
      metric.push value: 10, timestamp: 0
      expect(metric.value).to eq(nil)
      metric.push value: 20, timestamp: 10
      expect(metric.value).to eq(2.0)
      metric.push value: 100, timestamp: 20
      expect(metric.value).to eq(10.0)
    end

    it "returns nil rate for dt == 0" do
      metric.push value: 10, timestamp: 10
      metric.push value: 20, timestamp: 10
      expect(metric.value).to eq(nil)
    end

    it "returns nil if last value is nil" do
      metric.push value: 10, timestamp: 0
      metric.push value: nil, timestamp: 10
      expect(metric.value).to eq(nil)
    end
  end

  context "with ttl" do
    let(:metric) { Salus::Absolute.new }

    it "returns nil if previous value is expired" do
      metric.push value: 0, timestamp: 0, ttl: 10
      metric.push value: 5, timestamp: 5, ttl: 10
      expect(metric.value).to eq(1.0)
      metric.push value: 100, timestamp: 100, ttl: 10
      expect(metric.value).to eq(nil)
    end
  end
end
