module Salus
  module BaseCliUtils
    include Logging
    SALUS_STATE_FILE = "salus.state.yml"
    SALUS_FILE = "Salusfile"
    SALUS_GLOB = "*.salus"

    def read_file(file)
      ret = nil
      File.open(file, "r") do |f|
        f.flock(File::LOCK_SH)
        ret = f.read
        f.flock(File::LOCK_UN)
      end
      ret
    end

    def write_file(file, data)
      ret = nil
      File.open(file, File::RDWR|File::CREAT) do |f|
        f.flock(File::LOCK_EX)
        begin
          f.rewind
          ret = f.write(data)
          f.flush
          f.truncate(f.pos)
        ensure
          f.flock(File::LOCK_UN)
        end
      end
      ret
    end

    def load_files(files)
      raise "No metric definition files found" if files.empty?
      files.each do |file|
        begin
          Salus.load(file)
        rescue Exception => e
          log ERROR, "Failed to load #{file}: " + e.message
        end
      end
    end

    def load_state(file)
      return unless file
      Salus.load_state do
        begin
          YAML.load(read_file(file)) if File.exists?(file)
        rescue Exception => e
          log ERROR, "Failed to load state #{file}: " + e.message
        end
      end
    end

    def save_state(file)
      return unless file
      Salus.save_state do |data|
        begin
          write_file(file, data.to_yaml)
        rescue Exception => e
          log ERROR, "Failed to save state #{file}: " + e.message
        end
      end
    end

    def get_state_file(options={})
      options.fetch(:state,
        Salus.vars.fetch(:state_file,
          File.join(Dir.pwd, SALUS_STATE_FILE)))
    end

    def get_files(options={})
      if options.key?(:file)
        ret = []
        options[:file].each do |file|
          next unless File.exists?(file)
          if File.directory?(file)
            ret += Dir.glob(File.join(file, SALUS_GLOB)).sort
          else
            ret.push(file)
          end
        end
        ret
      elsif File.exists?(SALUS_FILE)
        [SALUS_FILE]
      else
        Dir.glob(SALUS_GLOB).sort
      end
    end
  end
end
