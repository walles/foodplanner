#!/usr/bin/env ruby

require 'yaml'

# Parse arguments
if ARGV.length != 2
  $stderr.puts 'ERROR: Expected two arguments'
  $stderr.puts
  $stderr.puts 'Syntax: foodplanner.rb <food YAML> <calendar YAML>'
  exit 1
end
food_yaml = ARGV[0]
calendar_yaml = ARGV[1]

# FIXME: Parse the food YAML file
# FIXME: Verify it against a schema
food_thing = YAML.load_file(food_yaml)

# FIXME: Parse the calendar YAML file
# FIXME: Verify it against a schema
calendar_thing = YAML.load_file(calendar_yaml)

# FIXME: Make a menu
calendar_thing.each do |occation|
  occation_name = occation.keys[0]
  occation_participants = occation[occation_name]

  # FIXME: ... make a list of all possible foods given the participants
  # FIXME: ... and pick a course from that list
  # FIXME: ... then don't forget to remove the course from the complete list
end

# FIXME: Print menu to stdout
