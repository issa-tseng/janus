# A **ViewModel** is a Model that isn't meant to represent a canonical entity,
# but rather the transient state of some interface component. It provides nice
# hooks to bind itself against application state so the interface can remain
# consistent across pageloads.
#
# Other than certain convenience hooks, though, there are no real functional
# differences between a `ViewModel` and a `Model`; the division is largely
# semantic.

Model = require('./model').Model

class ViewModel extends Model

