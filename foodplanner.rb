#!/usr/bin/env ruby

require 'yaml'

def available_food_for_occation(food_thing, occation)
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

  return available_food
end

def plan_food_for_occation(food_thing, occation)
  available_food = available_food_for_occation(food_thing, occation)

  if available_food.empty?
    occation_name = occation.keys[0]
    $stderr.puts "ERROR: Can't plan for #{occation_name}, menu exhausted"
    $stderr.puts
    $stderr.puts 'Please add more courses to the menu or remove some restrictions'
    exit 1
  end

  # ... and pick a course from that list
  return available_food.sample
end

# Find the occation with the fewest available food options
def find_occation_to_plan_for(food_thing, occations)
  # Map occation names to number of available courses
  occations_to_course_counts = {}
  occations.each do |occation|
    course_count = available_food_for_occation(food_thing, occation).size
    occations_to_course_counts[occation] = course_count
  end

  # Extract the occation names with the lowest number of courses
  lowest = occations_to_course_counts.values.min
  candidates = []
  occations_to_course_counts.each do |occation, count|
    candidates << occation if count == lowest
  end

  # Pick one occation with the lowest count
  return candidates.sample
end

def plan_food(food_thing, calendar_thing)
  plan = {}
  remaining_occations = calendar_thing.clone

  until remaining_occations.empty?
    # Find the occation that with the lowest number of available courses
    occation = find_occation_to_plan_for(food_thing, remaining_occations)
    occation_name = occation.keys[0]

    course = plan_food_for_occation(food_thing, occation)
    plan[occation_name] = course
    food_thing.delete(course)
    remaining_occations.delete(occation)
  end

  # Sort the plan to match the order of the calendar_thing
  ordered_plan = []
  calendar_thing.each do |occation|
    occation_name = occation.keys[0]
    ordered_plan << { occation_name => plan[occation_name] }
  end

  return ordered_plan
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
