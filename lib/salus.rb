require "salus/version"
require "salus/group"
require "salus/thread"

module Salus
  @groups = {}

  def self.group(title, &block)
    unless @groups.key?(title)
      @groups[title] = Group.new(&block)
    end
  end

  def self.groups
    @groups
  end
end
