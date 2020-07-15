Burro Tests
===========

Here are some test cases, written in [Falderal][] format, that can serve
as a check that an implementation of Burro is not grossly broken.

The fact that this test suite was produced as a side-effect of a search
for an extensible idiom for conditionals in Burro should be taken into
account when evaluating its suitability for a particular purpose.

In this document, "Burro" refers to Burro 2.x.

[Falderal]: https://catseye.tc/node/Falderal

Idiom for conditional execution
-------------------------------

    -> Tests for functionality "Run Burro Program"

    -> Functionality "Run Burro Program" is implemented by
    -> shell command "bin/burro run %(test-body-file)"

The basic idiom is the following

    --(L>/R>)<

Call the number in the current cell of the tape _n_.  We will assume _n_ is odd.
If _n_ is 1 or less, **R** is executed; if _n_ is 3 or more, **L** is executed.
Both **R** and **L** may modify the current cell to whatever they want.  They may
also move around and modify other parts of the tape.  They should however return
the current tape cell to the position they started in.

In both **L** and **R** cases, a "work value" is written in the cell to the right
of the current cell.  This "work value" is 2 - _n_.

Try it with -3:

    | ---
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [4]<[5] [0]<[] True

Try it with -1:

    | -
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [4]<[3] [0]<[] True

Try it with 1:

    | +
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [4]<[1] [0]<[] True

Try it with 3:

    | +++
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [2]<[-1] [0]<[] True

Try it with 5:

    | +++++
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [2]<[-3] [0]<[] True

Try it with 7:

    | +++++++
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [2]<[-5] [0]<[] True

Note that the work value is proportional to the number we started with.

Note also that the work value is not (?) available to us inside the branch,
because it's on the stack, not on the tape.

    -> Tests for functionality "Trace Burro Program"

    -> Functionality "Trace Burro Program" is implemented by
    -> shell command "bin/burro debug %(test-body-file)"

    | +
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [0]<[] [0]<[] True ::: +
    = State [1]<[] [0]<[] True ::: -
    = State [0]<[] [0]<[] True ::: -
    = State [-1]<[] [0]<[] True ::: (++>/++++>)
    = State [0]<[] [1,0]<[] True ::: +
    = State [1]<[] [1,0]<[] True ::: +
    = State [2]<[] [1,0]<[] True ::: +
    = State [3]<[] [1,0]<[] True ::: +
    = State [4]<[] [1,0]<[] True ::: >
    = State [4,1]<[] [0]<[] True ::: <
    = State [4]<[1] [0]<[] True

    | +++++
    | --(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [0]<[] [0]<[] True ::: +
    = State [1]<[] [0]<[] True ::: +
    = State [2]<[] [0]<[] True ::: +
    = State [3]<[] [0]<[] True ::: +
    = State [4]<[] [0]<[] True ::: +
    = State [5]<[] [0]<[] True ::: -
    = State [4]<[] [0]<[] True ::: -
    = State [3]<[] [0]<[] True ::: (++>/++++>)
    = State [0]<[] [-3,0]<[] True ::: +
    = State [1]<[] [-3,0]<[] True ::: +
    = State [2]<[] [-3,0]<[] True ::: >
    = State [2,-3]<[] [0]<[] True ::: <
    = State [2]<[-3] [0]<[] True

But it *is* available to us after the branch, so we can make another test.

The complication is that the value changed.  But, at least the change is
not because of the contents of L or R.  We always know what the value
changed to.  In the case of testing against 1, it changed to 2 - _n_.

And in fact, because 2 - (2 - _n_) = _n_, we ought to be able to change it back,
just by doing the same thing we just did, again.

    -> Tests for functionality "Run Burro Program"

Try it with 1:

    | +
    | --(
    |     ++
    | >/
    |     ++++
    | >)--(/)
    = State [4,1]<[] [0]<[] True

Try it with 3:

    | +++
    | --(
    |     ++
    | >/
    |     ++++
    | >)--(/)
    = State [2,3]<[] [0]<[] True

Try it with 5:

    | +++++
    | --(
    |     ++
    | >/
    |     ++++
    | >)--(/)
    = State [2,5]<[] [0]<[] True

As you can see, after the test, the contents of the current tape cell
are the same as the value we originally tested against.

But once we've tested a value against 1, it's unlikely that we'll want to
do that again.  What about the case of testing against other numbers?
Consider the following:

    ----(L>/R>)<

Now, if _n_ is 3 or less, **R** is executed; if _n_ is 5 or more, **L** is executed.

Try it with 3:

    | +++
    | ----(
    |     ++
    | >/
    |     ++++
    | >)----(/)
    = State [4,3]<[] [0]<[] True

Try it with 5:

    | +++++
    | ----(
    |     ++
    | >/
    |     ++++
    | >)----(/)
    = State [2,5]<[] [0]<[] True

The next step will be chaining these conditionals together so that
we can build a test that tests for multiple cases.
