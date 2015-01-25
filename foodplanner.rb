#!/usr/bin/env ruby

require 'yaml'

# Make a menu
def plan_food_for_occation(food_thing, occation)
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
  return available_food.sample
end

def plan_food(food_thing, calendar_thing)
  plan = []
  calendar_thing.each do |occation|
    course = plan_food_for_occation(food_thing, occation)

    occation_name = occation.keys[0]
    plan << { occation_name => course }
    food_thing.delete(course)
  end

  return plan
end

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

# FIXME: Accept arguments in any order and use schemas to identify
# them
food_yaml = ARGV[0]
calendar_yaml = ARGV[1]

# FIXME: Verify YAML against a schema
food_thing = YAML.load_file(food_yaml)

# FIXME: Verify YAML against a schema
calendar_thing = YAML.load_file(calendar_yaml)

# Print menu to stdout
puts YAML.dump(plan_food(food_thing, calendar_thing))
