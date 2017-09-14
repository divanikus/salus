require "spec_helper"

RSpec.describe Salus::Group do
  it "honors mute" do
    g = Salus::Group.new do
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
    g = Salus::Group.new do
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
    g = Salus::Group.new do
      gauge "test1", value: 10
      gauge "test2", value: 20
    end
    g.tick
    expect(g["test1"].value).to eq(10)
    expect(g.value("test2")).to eq(20)
    expect(g["test3"]).to eq(nil)
    expect(g.value("test4")).to eq(nil)
  end

  it "does calc" do
    a = 0
    g = Salus::Group.new do
      counter "test1", value: a * 10, timestamp: a
      counter "test2", value: a * 20, timestamp: a
    end
    g.tick
    a += 10
    g.tick
    expect(g["test1"].value).to eq(10.0)
    expect(g["test2"].value).to eq(20.0)
  end

  it "has metric delegates" do
    g = Salus::Group.new do end
    types = Salus::Metric.descendants.map { |x| x.name.split('::').last.downcase.to_sym }
    expect(types.count).to be >= 5
    expect(g.class.instance_methods).to include(*types)
  end

  it "saves" do
    data = {
      :metrics => {
        "test1" => {
          :type => "Counter",
          :mute => false,
          :values => [
            {:value => 0,   :timestamp => 0,  :ttl => nil},
            {:value => 100, :timestamp => 10, :ttl => nil}
          ]
        },
        "test2" => {
          :type => "Gauge",
          :mute => false,
          :values => [
            {:value => 200, :timestamp => 10, :ttl => nil}
          ]
        }
      },
      :groups => {
        "test"=> {
          :metrics => {
            "test3" => {
              :type => "Counter",
              :mute => false,
              :values => [
                {:value => 200, :timestamp => 0,  :ttl => nil},
                {:value => 400, :timestamp => 10, :ttl => nil}
              ]
            }
          }
        }
      }
    }

    a = 0
    b = 10
    g = Salus::Group.new do
      counter "test1", value: a * 10, timestamp: a
      gauge "test2", value: a * 20, timestamp: a

      group "test" do
        counter "test3", value: b * 20, timestamp: a
      end
    end
    g.tick
    a += 10
    b += 10
    g.tick

    expect(g.save).to eq(data)
    expect(g.to_h).to eq(data)
  end

  it "loads" do
    data = {
      :metrics => {
        "test1" => {
          :type => "Counter",
          :mute => false,
          :values => [
            {:value => 0,   :timestamp => 0,  :ttl => nil},
            {:value => 100, :timestamp => 10, :ttl => nil}
          ]
        },
        "test2" => {
          :type => "Gauge",
          :mute => false,
          :values => [
            {:value => 200, :timestamp => 10, :ttl => nil}
          ]
        }
      },
      :groups => {
        "test"=> {
          :metrics => {
            "test3" => {
              :type => "Counter",
              :mute => false,
              :values => [
                {:value => 200, :timestamp => 0,  :ttl => nil},
                {:value => 400, :timestamp => 10, :ttl => nil}
              ]
            }
          }
        }
      }
    }

    a = 100
    b = 200
    g = Salus::Group.new do
      counter "test1", value: a * 10, timestamp: a
      gauge "test2", value: a * 20, timestamp: a

      group "test" do
        counter "test3", value: b * 20, timestamp: a
      end
    end
    g.load(data)
    expect(g["test1"].value).to eq(10.0)
    expect(g["test2"].value).to eq(200.0)
    g.tick
    expect(g["test1"].value).to eq(10.0)
    expect(g["test2"].value).to eq(2000.0)
    expect(g.groups["test"]["test3"].value).to eq(40.0)
  end
end
