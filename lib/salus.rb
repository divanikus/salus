require "salus/version"
require "salus/group"

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
