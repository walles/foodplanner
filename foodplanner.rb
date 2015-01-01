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
food_thing = YAML.load_file(food_yaml)

# FIXME: Parse the calendar YAML file
calendar_thing = YAML.load_file(calendar_yaml)

# FIXME: Make a menu

# FIXME: Print menu to stdout
