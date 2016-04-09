#!/usr/bin/env ruby

require 'yaml'

def available_food_for_occasion(food_thing, occasion)
  occasion_name = occasion.keys[0]
  participants = occasion[occasion_name]
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
    occasions = restrictions['occasions'] || []

    unless occasions.empty?
      next unless occasions.include?(occasion_name)
    end

    next if not_cooking.include?(cook)

    non_eating_participants_count = (participants & not_eating).size
    next if non_eating_participants_count > 0

    available_food << course
  end

  return available_food
end

def plan_food_for_occasion(food_thing, occasion)
  available_food = available_food_for_occasion(food_thing, occasion)

  if available_food.empty?
    occasion_name = occasion.keys[0]
    $stderr.puts "ERROR: Can't plan for #{occasion_name}, menu exhausted"
    $stderr.puts
    $stderr.puts 'Please add more courses to the menu or remove some restrictions'
    exit 1
  end

  # ... and pick a course from that list
  return available_food.sample
end

# Find the occasion with the fewest available food options
def find_occasion_to_plan_for(food_thing, occasions)
  # Map occasion names to number of available courses
  occasions_to_course_counts = {}
  occasions.each do |occasion|
    course_count = available_food_for_occasion(food_thing, occasion).size
    occasions_to_course_counts[occasion] = course_count
  end

  # Extract the occasion names with the lowest number of courses
  lowest = occasions_to_course_counts.values.min
  candidates = []
  occasions_to_course_counts.each do |occasion, count|
    candidates << occasion if count == lowest
  end

  # Pick one occasion with the lowest count
  return candidates.sample
end

def update_tag_counts(tag_counts, course)
  return unless course

  tags = course['tags']
  return unless tags

  tags.each do |tag|
    tag_counts[tag] += 1
  end
end

# Sort the plan to match the order of the calendar_thing
def order_plan(plan, calendar_thing)
  ordered_plan = []
  calendar_thing.each do |occasion|
    occasion_name = occasion.keys[0]
    ordered_plan << { occasion_name => plan[occasion_name] }
  end

  return ordered_plan
end

def restrictions_contain_tag?(restrictions, tag)
  tags = restrictions['tags'] || []
  return tags.include?(tag)
end

# Look for at-limit <= constraints and remove all other food with the
# constraint's tag
def eval_constraints(constraints, tag_counts, food_thing)
  constraints.each do |constraint|
    raise "Unsupported operation '#{constraint.op}'" unless constraint.op == '<='

    tag_counts.each_pair do |tag, count|
      next unless constraint.tag == tag
      next if count < constraint.number

      # We've reached the maximum number of [tag] courses, drop any remaining
      # ones from the menu
      food_thing.delete_if do |_course, restrictions|
        restrictions && restrictions_contain_tag?(restrictions, tag)
      end
    end
  end
end

def extract_constraints(calendar_thing)
  # This method will modify calendar_thing!! If constraints are found, that
  # array entry will be removed.
  #
  # Constraints are returned in an array. Each constraint has methods for:
  # * .tag: What tag the constraint operates on
  # * .op: The operation, can be '<=' for example
  # * .number: The limit, can be 1 for example
  constraints_index = calendar_thing.index { |entry| entry.keys[0] == 'constraints' }
  return [] if constraints_index.nil?

  constraints_yaml = calendar_thing[constraints_index].values[0]
  calendar_thing.delete_at(constraints_index)

  constraints = []
  constraints_yaml.each do |constraint_string|
    split = constraint_string.split
    if split.size < 3
      raise "Constraint should be on the form: '<tag name> <op> <number>': <#{constraint_string}>"
    end

    # FIXME: Print the full constraint if the number conversion fails
    number = split[-1].to_i
    op = split[-2]
    tag = split[0..-3].join(' ')

    constraints << Struct.new(:tag, :op, :number).new(tag, op, number)
  end

  return constraints
end

def plan_food(food_thing, calendar_thing)
  plan = {}
  tag_counts = Hash.new(0)

  constraints = extract_constraints(calendar_thing)

  remaining_occasions = calendar_thing.clone

  until remaining_occasions.empty?
    # Find the occasion that has the lowest number of available courses
    occasion = find_occasion_to_plan_for(food_thing, remaining_occasions)
    occasion_name = occasion.keys[0]

    course = plan_food_for_occasion(food_thing, occasion)
    plan[occasion_name] = course
    update_tag_counts(tag_counts, food_thing[course])
    eval_constraints(constraints, tag_counts, food_thing)
    food_thing.delete(course)
    remaining_occasions.delete(occasion)
  end

  tag_counts.each_pair do |tag, value|
    puts "#{tag}: #{value}"
  end

  return order_plan(plan, calendar_thing)
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
