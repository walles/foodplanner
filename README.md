Example:
    ./foodplanner.rb examples/menu.yaml examples/calendar.yaml

# TODO

* Add support for expressing things like "we want vegetarian at least
once per generated menu". Needs tagging of food courses, and some way
of putting constraints on different tags.

* Warn about tags not mentioned in any constraints.

* Warn about at-least constraints where there aren't enough courses with the
relevant tag.

* Warn about at-least constraints where there isn't at least one more course
than required. Otherwise each menu will always contain the same courses.

* Fail with an error message on conflicting constraints, like having both
`sausage >= 3` and `sausage <= 1`.

* Fail with an error message if a constraint mentions a non-existing tag.

* If we at runtime realize we can't fulfill a constraint, print a warning about
that and drop the constraint.

* Add support for "on Fridays, we only want food with a certain tag".

* Accept a previously generated menu as input and avoid those courses
for this menu.


# DONE

* Start by selecting food for the occasions with the fewest possible
choices and continue up from there.

* Add support for "this course is best cooked on Fridays".

* Add support for expressing things like "we want sausage at most once
per generated menu". Needs tagging of food courses, and some way of
putting constraints on different tags.

* Fail with an error message on malformed constraints.

* Fail with an error message on unsupported constraint operation.
