require "spec_helper"

RSpec.describe Salus::Gauge do
  context "without ttl" do
    let(:metric) { Salus::Gauge.new }

    it "returns values as pushed" do
      metric.push value: 10.0
      expect(metric.value).to eq(10.0)
      metric.push value: 20.0
      expect(metric.value).to eq(20.0)
      metric.push value: 30.0
      expect(metric.value).to eq(30.0)
    end
  end
end
