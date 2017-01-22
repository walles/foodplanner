#!/usr/bin/env ruby

require 'yaml'

# Keeps track of and evaluates constraints on the generated menu
class Constraints
  def initialize(calendar_thing)
    # This method will modify calendar_thing!! If constraints are found, that
    # array entry will be removed.
    #
    # Constraints are returned in an array.

    @at_most = []
    @at_least = []

    constraints_index = calendar_thing.index { |entry| entry.keys[0] == 'constraints' }
    return if constraints_index.nil?

    _parse_constraint_strings(calendar_thing[constraints_index].values[0])
    calendar_thing.delete_at(constraints_index)
  end

  def _parse_constraint_strings(constraint_strings)
    constraint_strings.each do |cs|
      constraint = _parse_constraint_string(cs)
      case constraint.op
      when '>='
        @at_least << constraint
      when '<='
        @at_most << constraint
      else
        raise "Unknown operation '#{constraint.op}', must be '>=' or '<=': <#{cs}>"
      end
    end
  end

  def _parse_constraint_string(constraint_string)
    # A constraint string should be on the form: "sausage <= 1".
    #
    # Each parsed constraint has methods for:
    # * .tag: What tag the constraint operates on
    # * .op: The operation, can be '<=' for example
    # * .number: The limit, can be 1 for example
    split = constraint_string.split
    if split.size < 3
      raise "Constraint should be on the form: '<tag name> <op> <number>': <#{constraint_string}>"
    end

    number_s = split[-1]
    number = number_s.to_i
    if number.to_s != number_s
      raise "Last word should be numeric in constraint: <#{constraint_string}>"
    end

    op = split[-2]
    tag = split[0..-3].join(' ')

    return Struct.new(:tag, :op, :number).new(tag, op, number)
  end

  # Look for at-limit <= constraints and remove all other food with the
  # constraint's tag
  def enforce_at_most(tag_counts, food_thing)
    @at_most.each do |constraint|
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

  def get_unfulfilled_tags(tag_counts)
    unfulfilled = []
    @at_least.each do |at_least|
      if tag_counts[at_least.tag] < at_least.number
        unfulfilled << at_least.tag
      end
    end
    return unfulfilled
  end

  # If we have any unfulfilled at-least constraints, return only food with the
  # tags we need more of. Otherwise just return all food.
  def filter_available_food(food_thing, tag_counts)
    unfulfilled_tags = get_unfulfilled_tags(tag_counts)
    return food_thing if unfulfilled_tags.empty?

    filtered = {}
    food_thing.each_pair do |name, restrictions|
      next if restrictions.nil?

      tags = restrictions['tags']
      next if tags.nil?

      helps_constraint = !(tags & unfulfilled_tags).empty?
      filtered[name] = restrictions if helps_constraint
    end

    return filtered
  end
end

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
    # FIXME: List unfulfilled constraints if we have any
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

def plan_food(food_thing, calendar_thing)
  plan = {}
  tag_counts = Hash.new(0)

  constraints = Constraints.new(calendar_thing)

  remaining_occasions = calendar_thing.clone

  until remaining_occasions.empty?
    # Start out with planning only food where we haven't yet reached the
    # at-least limit
    available_food = constraints.filter_available_food(food_thing, tag_counts)

    # Find the occasion that has the lowest number of available courses
    occasion = find_occasion_to_plan_for(available_food, remaining_occasions)
    occasion_name = occasion.keys[0]

    course = plan_food_for_occasion(available_food, occasion)
    plan[occasion_name] = course

    # Update the global food status, not just the available_food one
    update_tag_counts(tag_counts, food_thing[course])
    constraints.enforce_at_most(tag_counts, food_thing)
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
