# Salus

Salus is a simple DSL for writing collector agents for different monitoring systems. I'm just tired of rewriting those primitives from scratch for every new check I'm willing to add to a monitoring system.

_This is alpha quality software right now, but you might help to improve it_

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'salus'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install salus

## Usage

The gem can be used from your own script or by using CLI.

Quick sample:

```ruby
require "json"
default ttl: 60

group "cpu" do
  data = File.open("/proc/stat").read.split(/\n/).grep(/^cpu /)
  data.each do |l|
    name, user, nice, csystem, idle, iowait, irq, softirq = l.split(/\s+/)

    busy  = user.to_i + nice.to_i + csystem.to_i + iowait.to_i + irq.to_i + softirq.to_i
    total = busy + idle.to_i

    counter "busy", value: busy, mute: true
    counter "total", value: total, mute: true
    gauge "usage" do
      value("busy") / value("total") * 100
    end
  end
end

group "memory" do
  data = File.open("/proc/meminfo").read.split(/\n/).grep(/^Mem/)
  data.each do |l|
    name, value = l.match(/Mem(?<name>.+):\s+(?<value>\d+)\s/)[1,2]
    gauge name.downcase, value: value.to_i, mute: true
  end
  gauge "usage" do
    (value("total") - value("free")) / value("total").to_f * 100
  end
end

render do |data|
  iterate(data) do |name, metric|
    puts ({:name => name, :value => metric.value, :timestamp => metric.timestamp, :ttl => metric.ttl}.to_json)
  end
end
```

Save it as `sample.salus` and run `salus`.

```bash
$ salus -f sample.salus
{"name":"cpu.usage","value":6.433521607455635,"timestamp":1510699623.8592708,"ttl":60}
{"name":"memory.usage","value":25.60121068625779,"timestamp":1510699623.863265,"ttl":60}
```

Because `cpu.usage` is made of counters, you'll have to run the command at least twice. Be aware of `salus` making `salus.state.yml` for persisting it's state. You may redefine file name and location with `-s` switch.

You can also run in infinite loop mode

```bash
$ salus loop -f sample.salus
{"name":"cpu.usage","value":12.528473606797895,"timestamp":1510700076.4455612,"ttl":60}
{"name":"memory.usage","value":25.57683405209171,"timestamp":1510700076.447059,"ttl":60}
{"name":"cpu.usage","value":8.239946939924048,"timestamp":1510700106.3334389,"ttl":60}
{"name":"memory.usage","value":25.535366304014968,"timestamp":1510700106.33444,"ttl":60}
{"name":"cpu.usage","value":2.840158185017875,"timestamp":1510700136.364328,"ttl":60}
{"name":"memory.usage","value":25.537265316671707,"timestamp":1510700136.36533,"ttl":60}
^C
```

You may invoke several salus scripts at once, just specify all of them in a space delimited list. You might also specify a directory with `Salusfile` or many `*.salus` files. By default `salus` does search `*.salus` and `Salusfile` in the current directory.

### Primitives

#### Group

Group is the base unit of work. You should write your metric collecting code inside groups. Groups can be nested. Top level groups are run in separate threads. Group might include metrics. Groups must be named.

```ruby
group "test" do
  gauge "test1", value: 10
  gauge "test2", value: 30, mute: true
end
```

#### Metrics

Could be one of the following (mimicking RRDtool data sources):
 * Gauge: values stored as is
 * Derive: a rate of something per second, best suites for values that rarely overflow
 * Counter: almost same as derive, but with overflow detection for 32- and 64-bit counters
 * Absolute: a rate of a counter, which resets on reading
 * Text: just a text stored as is

A metric should have a name and a value at the very minimum. You might also specify a custom or default TTL. A metric can be also `mute`, which means it wouldn't appear in the output, unless told to do so.

An expired metric is considered invalid, so if you use counter or derive with ttl less than collecting interval, you'll always get nils.

```ruby
group "test" do
  gauge   "test1", value: 10, ttl: 50
  counter "test2", value: 10, mute: true
  derive  "test3", value: 30, timestamp: Time.now.to_f + 10
end
```

You might also use a block to calculate metrics value. In this case any exception which happened in the block would be muted, and the nil value returned instead.

```ruby
group "test" do
  # this would always produce nil
  gauge "division by zero" do
    100 / 0
  end
end
```

#### Renderers

A renderer is a class, which is used to render the actual output, would it be just STDOUT, a file or tcp/ip service.

```ruby
render(StdoutRenderer.new(separator: "/"))
```

This code would produce something like that

```
[2017-11-15 02:25:16 +0300] cpu/usage - 4.00
[2017-11-15 02:25:16 +0300] memory/usage - 26.23
```

You may add more than one renderer at once and send your data to as many monitoring services as you want.

Check sample renderers for examples.

### Pipeline

Salus pipeline is rather straightforward and consists of two stages:
 * Collect data (execute groups' code)
 * Send data (execute renderers' code)

You might run it once by cron or in infinite loop mode. Each stage is executed using embed thread pool with pre-set timeouts.

Thread pool and timeouts could be configured using `configure`

```ruby
Salus.configure do |config|
  # Thread pool settings
  config.min_threads = (CPU.count / 2 == 0) ? 1 : CPU.count / 2
  config.max_threads = CPU.count * 2

  config.interval = 30 # Interval between runs in loop mode
  config.tick_timeout   = 15 # Data collection timeout
  config.render_timeout = 10 # Data rendering timeout
  config.logger   = Logger.new(STDERR) # Default logger
end
```

### Zabbix

Zabbix uses two stage collecting. First of all, it queries (discovers) the list of objects to be checked. Next, it would ask for exact values of specified metrics of an object one by one. Sometimes this means making a lot of requests to a monitored service. So many script writers use some kind of result caching to lower unnecessary work. Salus also writes a result cache file (`-c` flag). Cache TTL for a metric is a half of it's real TTL or 60 seconds if TTL is unspecified. Upon parameter request it is loaded from cache and if it's expired, whole cache is invalidated and recalculated using salus script.

Sample Salus script for collecting CPU usage ratio on Linux for Zabbix Agent is something like that:

```ruby
require "salus/zabbix"

default ttl: 60

discover "cpus" do |data|
  stat = File.open("/proc/stat").read.split(/\n/).grep(/^cpu\d/)
  stat.each do |l|
    name, = l.split(/\s+/)
    data << {"\#{CPUNAME}" => name}
  end
end

group "cpu" do
  stat = File.open("/proc/stat").read.split(/\n/).grep(/^cpu\d/)
  stat.each do |l|
    name, user, nice, csystem, idle, iowait, irq, softirq = l.split(/\s+/)

    busy  = user.to_i + nice.to_i + csystem.to_i + iowait.to_i + irq.to_i + softirq.to_i
    total = busy + idle.to_i

    counter "busy[#{name}]", value: busy, mute: true
    counter "total[#{name}]", value: total, mute: true
    gauge "usage[#{name}]" do
      value("busy[#{name}]") / value("total[#{name}]") * 100
    end
  end
end
```

You can run it using command `salus`.

```bash
$ salus zabbix discover cpus -f zabbix.salus
{"data":[{"#{CPUNAME}":"cpu0"},{"#{CPUNAME}":"cpu1"},{"#{CPUNAME}":"cpu2"},{"#{CPUNAME}":"cpu3"},{"#{CPUNAME}":"cpu4"},{"#{CPUNAME}":"cpu5"},{"#{CPUNAME}":"cpu6"},{"#{CPUNAME}":"cpu7"}]}
```

Later you can get a cpu usage ratio

```bash
$ salus zabbix parameter cpu.usage[cpu5] -f zabbix.salus && sleep 31 && salus zabbix parameter cpu.usage[cpu5] -f zabbix.salus
8.619550926524335
```

**NOTE!** You won't get the result on the first run, because cpu usage on Linux needs to get two points in time to be calculated. `zabbix` subcommand uses caching of the results, so you have to wait for 30 seconds to get next result. But if you'll wait for more than TTL (60 seconds), you'll get empty result again.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Special thanks
 * meh for [ruby-thread](https://github.com/meh/ruby-thread)
 * all folks of [concurrent](https://github.com/ruby-concurrency/concurrent-ruby) project
 * all folks of [thor](https://github.com/erikhuda/thor) project

Salus uses portions of code (meh's thread pool and future implementation) and concepts from both project and thor for CLI implementation.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/divanikus/salus.
