#!/usr/bin/env ruby
require "yaml"
require "json"
data = {}
ARGV.each do |file|
  YAML::load_file(file).each do |id, text|
    data[id] = {"message" => text}
  end
end
puts JSON::generate(data, :indent => "  ", :object_nl => "\n")
