require 'sequel'
require 'isaac'
$modules = {'database' => nil, 'weather' => nil}

configure do |c|
  c.nick     = "rh"
  c.server   = "2001:888:0:2::2"   # efnet.ipv6.xs4all.nl
  c.port     = 6697
  c.ssl      = true
  c.realname = "rubyhugs"
  c.version  = "rubyhugs-0.1"
  c.verbose  = true
end

on :connect do 
  join "#grouphugs"
end

helpers do
  def on(event, match=//, block)
    match = match.to_s if match.is_a? Integer
    (@events[event] ||= []) << [match, block]
  end
  def remove(event, match=//, block)
    @events[event].delete([match, block])
  end
end

$modules.each_key do |k|
  load k + '.rb'
  eval "$modules[k] = #{k.capitalize}.new"
  $modules[k].triggers.each { |t| on t[0], t[1], t[2] } if defined? $modules[k].triggers
end

on :channel, /^@load (.*)/, Proc.new {
  begin
    $modules[match[0]].triggers.each { |t| remove t[0], t[1], t[2] } if defined? $modules[match[0]].triggers unless $modules[match[0]].nil?
    load match[0] + '.rb'
    eval "$modules[match[0]] = #{match[0].capitalize}.new"
    $modules[match[0]].triggers.each { |t| on t[0], t[1], t[2] } if defined? $modules[match[0]].triggers
    msg channel, "Module #{match[0]} loaded."
  rescue
    msg channel, "Unable to load module #{match[0]}."
  end
}

on :channel, /^@unload (.*)/, Proc.new {
  begin
    $modules[match[0]].triggers.each { |t| remove t[0], t[1], t[2] } if defined? $modules[match[0]].triggers
    $modules.delete(match[0])
    Object.send(:remove_const, match[0].to_s.capitalize)
    msg channel, "Module #{match[0]} unloaded."
  rescue
    msg channel, "Unable to unload module #{match[0]}."
  end
}
