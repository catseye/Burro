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

    --(GT>/LT>)<

Call the number in the current cell of the tape _n_.  We will assume _n_ is odd.
If _n_ is greater than 2, **GT** is executed; if _n_ is less than 2, **LT** is executed.
Both **GT** and **LT** may modify the current cell to whatever they want.  They may
also move around and modify other parts of the tape.  They should however return
the current tape cell to the position they started in.

In both **GT** and **LT** , a "work value" is written in the cell to the right
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

Note also that the work value is not available to us inside the branch,
because it's on the stack, not on the tape.  A trace makes this more obvious.

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
not because of the contents of **GT** or **LT**.  We always know what the value
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
    | >)--(/)<
    = State [4]<[1] [0]<[] True

Try it with 3:

    | +++
    | --(
    |     ++
    | >/
    |     ++++
    | >)--(/)<
    = State [2]<[3] [0]<[] True

Try it with 5:

    | +++++
    | --(
    |     ++
    | >/
    |     ++++
    | >)--(/)<
    = State [2]<[5] [0]<[] True

As you can see, after the test, the contents of the current tape cell
are the same as the value we originally tested against.

But once we've tested a value against 1, it's unlikely that we'll want to
do that again.  What about the case of testing against other numbers?
Consider the following:

    ----(GT>/LT>)----(/)<

Now, if _n_ is greater than 4, **GT** is executed; if _n_ is less than 4, **LT** is executed.
And again, we end up with a work value in the cell to the right, but this time it's
4 - _n_, but again we reverse it to obtain the original value we tested against.

Try it with 3:

    | +++
    | ----(
    |     ++
    | >/
    |     ++++
    | >)----(/)<
    = State [4]<[3] [0]<[] True

Try it with 5:

    | +++++
    | ----(
    |     ++
    | >/
    |     ++++
    | >)----(/)<
    = State [2]<[5] [0]<[] True

The next step will be combining these conditionals so that we can build a test
that tests for multiple cases.

We've already noted that the original value being tested against isn't available
inside the conditional -- it's "hiding" on the stack during that period.

This rules out being able to test multiple cases by nesting conditionals.
So instead of nesting conditionals, we'll chain them one after another.

But there are some implications for this, when it's combined with the fact
that we don't have conditional tests for equality, only tests for greater than
and less then.

We'll revert to a more conventional syntax to try to devise how we can overcome
those implications.

Say the value to be tested is either 1, 3, or 5, and say we want to execute
_a_ if it's 1, _b_ if it's 3, or _c_ if it's 5.  We could try to write our chain
like this:

    if value > 0:
        A
    endif
    if value > 2:
        B
    endif
    if value > 4:
        C
    endif

The problem is that A, B, and C don't match up exactly to _a_, _b_, and _c_.
Instead we have:

*   If value is 1 then A is executed.
*   If value is 3 then A is executed then B is executed.
*   If value is 5 then A then B then C is executed.

But we can overcome this by defining what A, B, and C are, in terms of
_a_, _b_, and _c_, and code that **undoes** _a_, _b_, and _c_.  Using
the notation _x_′ to mean code that undoes _x_, we can choose the following
equations:

*   A = _a_
*   B = _a_′ _b_
*   C = _b_′ _c_

And we can restate the scenario like

*   If value is 1 then _a_ is executed.
*   If value is 3 then _a_ is executed then _a_′ _b_ is executed.
    *   _a_ _a_′ _b_ = _b_, so in effect, only _b_ is executed.
*   If value is 5 then _a_ then _a_′ _b_ then _b_′ _c_ is executed.
    *   _a_ _a_′ _b_ _b_′ _c_ = _c_, so in effect, only _c_ is executed.

So the idiom works out (in theory: now I need to write some test cases here.)
