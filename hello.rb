class Hello
  attr_reader :triggers

  def initialize
    @triggers = Array.new
    @triggers << [:channel, /^hello$/, Proc.new { msg channel, "Hello #{nick}!" rescue nil}]
  end
end
