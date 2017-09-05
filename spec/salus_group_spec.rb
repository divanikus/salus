require "spec_helper"

RSpec.describe Salus::Group do
  it "honors mute" do
    g = Salus::Group.new "test" do
      gauge "test1", value: 10
      gauge "test2", value: 10
      gauge "test3", value: 30, mute: true
      gauge "test4", value: 30, mute: true
    end
    g.tick
    expect(g.keys).to eq(["test1", "test2"])
    expect(g.values.length).to eq(2)
    expect { |b| g.each &b }.to yield_control.exactly(2).times
  end

  it "allows to get mutes" do
    g = Salus::Group.new "test" do
      gauge "test1", value: 10
      gauge "test2", value: 10
      gauge "test3", value: 30, mute: true
      gauge "test4", value: 30, mute: true
    end
    g.tick
    expect(g.keys(true)).to eq(["test1", "test2", "test3", "test4"])
    expect(g.values(true).length).to eq(4)
    expect { |b| g.each(true, &b) }.to yield_control.exactly(4).times
  end

  it "fetchs values" do
    g = Salus::Group.new "test" do
      gauge "test1", value: 10
      gauge "test2", value: 20
    end
    g.tick
    expect(g["test1"]).to eq(10)
    expect(g.value("test2")).to eq(20)
    expect(g["test3"]).to eq(nil)
    expect(g.value("test4")).to eq(nil)
  end

  it "does calc" do
    a = 0
    g = Salus::Group.new "test" do
      counter "test1", value: a * 10, timestamp: a
      counter "test2", value: a * 20, timestamp: a
    end
    g.tick
    a += 10
    g.tick
    expect(g["test1"]).to eq(10.0)
    expect(g["test2"]).to eq(20.0)
  end

  it "has metric delegates" do
    g = Salus::Group.new "test" do end
    expect(g.class.instance_methods).to include(:absolute, :counter, :derive, :gauge, :text)
  end

  it "brings exception without name" do
    expect{Salus::Group.new}.to raise_error(ArgumentError)
  end
end
