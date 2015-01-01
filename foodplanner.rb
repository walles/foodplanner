#!/usr/bin/env ruby

# Parse arguments
if ARGV.length != 2
  $stderr.puts 'ERROR: Expected two arguments'
  $stderr.puts
  $stderr.puts 'Syntax: foodplanner.rb <food YAML> <calendar YAML>'
  exit 1
end

food_yaml = ARGV[0]
unless File.file?(food_yaml)
  $stderr.puts "ERROR: not a file: #{food_yaml}"
  exit 1
end

calendar_yaml = ARGV[1]
unless File.file?(calendar_yaml)
  $stderr.puts "ERROR: not a file: #{calendar_yaml}"
  exit 1
end

# FIXME: Parse the food YAML file

# FIXME: Parse the calendar YAML file

# FIXME: Make a menu

# FIXME: Print menu to stdout
