module Salus
  class CPU
    def self.count
      @count ||= self.get_count
    end

    private
    def self.get_count
      return Java::Java.lang.Runtime.getRuntime.availableProcessors if RUBY_PLATFORM == "java"
      return File.read('/proc/cpuinfo').scan(/^processor\s*:/).size if File.exist?('/proc/cpuinfo')
      require 'win32ole'
      WIN32OLE.connect("winmgmts://").ExecQuery("select NumberOfLogicalProcessors from Win32_Processor")
        .to_enum.collect(&:NumberOfLogicalProcessors).reduce(:+)
    rescue LoadError
      Integer `sysctl -n hw.ncpu 2>/dev/null` rescue 1
    end
  end
end
