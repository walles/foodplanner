Example:
    ./foodplanner.rb examples/menu.yaml examples/calendar.yaml

# TODO

* Add support for "on Fridays, we only want food with a certain tag".

* Start by selecting food for the occations with the fewest possible
choices and continue up from there.

* Accept a previously generated menu as input and avoid those courses
for this menu.

* Add support for expressing things like "we want sausage at most once
per generated menu". Needs tagging of food courses, and some way of
putting constraints on different tags.

* Add support for expressing things like "we want vegetarian at least
once per generated menu". Needs tagging of food courses, and some way
of putting constraints on different tags.

* Add support for expressing things like "this course is best cooked
on Fridays".
