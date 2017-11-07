require "logger"

module Salus
  # Loosely based on code from https://github.com/ruby-concurrency/concurrent-ruby/
  module Logging
    include Logger::Severity

    def log(level, message = nil, progname = nil, &block)
      (@logger || Salus.logger).add level, message, progname, &block
    rescue => error
      $stderr.puts "Failed to log #{[level, progname, message, block]}\n" +
        "#{error.message} (#{error.class})\n#{error.backtrace.join "\n"}"
    end
  end
end
