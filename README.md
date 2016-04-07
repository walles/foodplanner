Example:
    ./foodplanner.rb examples/menu.yaml examples/calendar.yaml

# TODO

* Add support for "on Fridays, we only want food with a certain tag".

* Add support for expressing things like "we want sausage at most once
per generated menu". Needs tagging of food courses, and some way of
putting constraints on different tags.

* Add support for expressing things like "we want vegetarian at least
once per generated menu". Needs tagging of food courses, and some way
of putting constraints on different tags.

* Accept a previously generated menu as input and avoid those courses
for this menu.


# DONE

* Start by selecting food for the occasions with the fewest possible
choices and continue up from there.

* Add support for "this course is best cooked on Fridays".
