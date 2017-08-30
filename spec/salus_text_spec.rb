require "spec_helper"

RSpec.describe Salus::Text do
  context "without ttl" do
    let(:metric) { Salus::Text.new }

    it "validates types" do
      expect{metric.push value: 10.0}.to raise_error(ArgumentError)
      expect{metric.push value: true}.to raise_error(ArgumentError)
    end

    it "returns values as pushed" do
      metric.push value: "just"
      expect(metric.value).to eq("just")
      metric.push value: "a"
      expect(metric.value).to eq("a")
      metric.push value: :test
      expect(metric.value).to eq(:test)
    end
  end
end
