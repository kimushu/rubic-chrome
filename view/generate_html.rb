#!/usr/bin/env ruby
require "optparse"
opt = {:dep => nil, :verbose => false, :started => false}

OptionParser.new do |o|
  o.on('-d DEP') {|v| opt[:dep] = open(v, "w") }
  o.on('-v') { opt[:verbose] = true }
  o.on('-s') { opt[:started] = true }
  o.parse!(ARGV)
end

abort "usage: #$0 [-d DEP] [-v] [-s] <infile> <outfile>" if ARGV.size != 2

def process(opt, out, infile, started = false)
  opt[:dep].print("\\\n\t#{infile}") if opt[:dep]
  last = false
  ln = 0
  open(infile).each_line do |line|
    ln += 1
    case(line)
    when /<!--begin-->/
      started = true
      next
    when /<!--end-->/
      started = false
    when /<!--include\(([^\)]+)\)-->/
      process(opt, out, $1) if started
      last = false
      next
    end
    if started
      indent = ""
      line.sub(/^\s+/) { |v| indent = v }
      out.puts("#{indent}<!--#{infile}:#{ln}-->") if opt[:verbose] and !last
      out.puts(line)
    end
    last = started
  end
end

opt[:dep].print("#{ARGV[1]}:") if opt[:dep]
process(opt, open(ARGV[1], "w"), ARGV[0], opt[:started])
opt[:dep].puts if opt[:dep]

