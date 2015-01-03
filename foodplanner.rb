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
plan = []
calendar_thing.each do |occation|
  occation_name = occation.keys[0]
  participants = occation[occation_name]
  cook = participants[0]

  # ... make a list of all possible foods given the participants
  available_food = []

  food_thing.each_pair do |course, restrictions|
    if restrictions.nil?
      available_food << course
      next
    end

    not_eating = restrictions['not eating'] || []
    not_cooking = restrictions['not cooking'] || []

    next if not_cooking.include?(cook)
    next if (participants & not_eating).size > 0

    available_food << course
  end

  # ... and pick a course from that list
  plan << { occation_name => available_food.sample }
  # FIXME: ... then don't forget to remove the course from the complete list
end

# Print menu to stdout
puts YAML.dump(plan)
