#!/usr/bin/env ruby

require 'yaml'

# FIXME: Optionally accept a third argument which is the output from a
# previous run, possibly on stdin. Given that, we should use food
# listed in that file only if no other food is available. This would
# help decrease repetetiveness between invocations.

# Parse arguments
if ARGV.length != 2
  $stderr.puts 'ERROR: Expected two arguments'
  $stderr.puts
  $stderr.puts 'Syntax: foodplanner.rb <food YAML> <calendar YAML>'
  exit 1
end
food_yaml = ARGV[0]
calendar_yaml = ARGV[1]

# FIXME: Verify YAML against a schema
food_thing = YAML.load_file(food_yaml)

# FIXME: Verify YAML against a schema
calendar_thing = YAML.load_file(calendar_yaml)

# Make a menu
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

    # FIXME: If we get unknown restrictions, report error to user
    not_eating = restrictions['not eating'] || []
    not_cooking = restrictions['not cooking'] || []

    next if not_cooking.include?(cook)
    next if (participants & not_eating).size > 0

    available_food << course
  end

  if available_food.empty?
    $stderr.puts "ERROR: Can't plan for #{occation_name}, menu exhausted"
    $stderr.puts
    $stderr.puts 'Please add more courses to the menu or remove some restrictions'
    exit 1
  end

  # ... and pick a course from that list
  food = available_food.sample
  plan << { occation_name => food }

  # ... then don't forget to remove the course from the complete list
  food_thing.delete(food)
end

# Print menu to stdout
puts YAML.dump(plan)
