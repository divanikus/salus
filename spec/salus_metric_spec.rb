require "spec_helper"

RSpec.describe Salus::Metric do
  context "without ttl" do
    let(:metric) { Salus::Metric.new }

    it "validates types" do
      expect{metric.push value: "just a test"}.to raise_error(ArgumentError)
      expect{metric.push timestamp: "just a test"}.to raise_error(ArgumentError)
      expect{metric.push ttl: true}.to raise_error(ArgumentError)
      expect{metric.push mute: 10}.to raise_error(ArgumentError)
    end

    it "stores value" do
      metric.push value: 10
      expect(metric.value).to eq(10)
    end

    it "stores timestamp" do
      metric.push timestamp: 1000
      expect(metric.timestamp).to eq(1000)
    end

    it "sets timestamp" do
      metric.push value: 10
      expect(metric.timestamp.to_i).to eq(Time.now.to_i)
    end

    it "uses mute flag" do
      expect(metric.mute?).to eq(false)
      metric.push mute: true
      expect(metric.mute?).to eq(true)
    end

    it "never expires" do
      metric.push timestamp: 1000
      expect(metric.expired?).to eq(false)
    end

    it "pushes values" do
      metric.push value: 10
      expect(metric.value).to eq(10)
      metric.push value: 20
      expect(metric.value).to eq(20)
      metric.push value: 30
      expect(metric.value).to eq(30)
    end

    it "takes block" do
      metric.push do
        100 / 10
      end
      expect(metric.value).to eq(10)
    end

    it "mutes block errors" do
      metric.push do
        10 / nil
      end
      expect(metric.value).to eq(nil)
    end
  end

  context "with ttl" do
    let(:metric) { Salus::Metric.new }

    it "expires" do
      metric.push timestamp: 1000, ttl: 10
      expect(metric.expired?).to eq(true)
    end
  end
end
