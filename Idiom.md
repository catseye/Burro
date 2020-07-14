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

But, once we've tested against 1, it's unlikely that we'll want to
do that again.  What about the case of testing against other numbers?
Consider the following:

    ----(L>/R>)<

Now, if _n_ is 3 or less, **R** is executed; if _n_ is 5 or more, **L** is executed.

    -> Tests for functionality "Run Burro Program"

Try it with 3:

    | +++
    | ----(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [4]<[1] [0]<[] True

Try it with 5:

    | +++++
    | ----(
    |     ++
    | >/
    |     ++++
    | >)<
    = State [2]<[-1] [0]<[] True

We see now that the work cell contains 4 - _n_.
