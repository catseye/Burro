The Burro Programming Language, version 1.0
===========================================

October 2007, Chris Pressey, Cat's Eye Technologies.

*Note: This document describes version 1.0 of the Burro language. For
documentation on the latest version of the language, please see
[Burro.lhs](../src/_Burro.lhs.html).*

(1) Introduction
----------------

*Burro* is a Brainfuck-like programming language whose programs form an
algebraic group under concatenation.

(At least, that is how I originally would have described it. But that
description turns out to be not entirely precise, because the technical
meanings of "group" and "program" come into conflict. A more precise
statement would be: "Burro is a semi-formal programming language, the
set of whose program texts, paired with the operation of concatenation,
forms an algebraic group over a semantic equivalence relation." But the
first version is close enough for jazz, and rolls off the tongue more
easily...)

Anyway, what does it mean? It means that, among other things, every
Burro program has an *antiprogram* — a series of instructions that can
be appended to it to annihilate its behavior. The resulting catenated
program has the same semantics as no program at all — a "no-op," or a
zero-length program.

Why is this at all remarkable? Well, take the Brainfuck program fragment
`[-]+[]`. What could you append to it to it to make it into a "no-op"
program? Evidently *nothing*, because once the interpreter enters an
infinite loop, it's not going to care what instructions you've put after
the loop. And a program that loops forever isn't the same as one that
does nothing at all.

So not all Brainfuck programs have antiprograms. Despite that, Brainfuck
does embody a lot of symmetry. Group theory, too, is a branch of
mathematics particularly suited to the study of symmetry. And as you
might imagine, there is a distinct relation between symmetrical
programming languages and reversible programming (even though it may not
be immediatly clear exactly what that relationship is.) These are some
of the factors that encouraged me to design Burro.

(2) Background
--------------

Before explaining Burro, a short look of group theory and of the theory
of computation would probably be helpful.

### Group Theory

Recall (or go look up in an abstract algebra textbook) that a *group* is
a pair of a set S and a binary operation · : S × S → S that obeys the
following three axioms:

-   For any three elements _a_, _b_, and _c_ of the set S, (_a_ · _b_) ·
    _c_ = _a_ · (_b_ · _c_). In other words, the operation is
    "associative." Parentheses don't matter, and we generally leave them
    out.
-   There exists some element of S, which we call **e**, such that _a_ ·
    **e** = **e** · _a_ = _a_ for every element _a_ of S. Think of **e**
    as a "neutral" element that just doesn't contribute anything.
-   For every element _a) of S there is an element _a'_ of S such that
    _a_ · _a'_ = **e**. That is, for any element, you can find some element
    that "annihilates" it.

There are lots of examples of groups — the integers under the operation
of addition, for example, where **e** is 0, and the annihilator for any
integer is simply its negative (because _x_ + (-_x_) always equals 0.)

There are also lots of things you can prove are true about any group
(that is, about groups in general.) For instance, that **e** is unique:
if _a_ · _x_ = _a_ and _a_ · _y_ = _a_ then _x_ = _y_ = **e**. (This
particular property will become relevant very soon, so keep it in mind
as you read the next section.)

The set on which a group is based can have any number of elements.
Research and literature in group theory often concentrates on finite
groups, because these are in some ways more interesting, and they are
useful in error-correcting codes and other applications. However, the
set of Burro programs is countably infinite, so we will be dealing with
infinite groups here.

### Theory of Computation

I don't need to call on a lot of theory of computation here except to
point out one fact: for any program, there are an infinite number of
equivalent programs. There are formal proofs of this, but they can be
messy, and it's something that should be obvious to most programmers.
Probably the simplest example, in Brainfuck, is that `+-`, `++--`,
`+++---`, `++++----`, etc., all have the same effect.

To be specific, by "program" here I mean "program text" in a particular
language; if we're talking about "abstract programs" in no particular
language, then you could well say that there is only and exactly one
program that does any one thing, it's just that there are an infinite
number of concrete representations of it.

This distinction becomes important with respect to treating programs as
elements of a group, like we're doing in Burro. Some program will be the
neutral element **e**. But either *many* programs will be equivalent to
this program — in which case **e** is not unique, contrary to what group
theory tells us — or we are talking about abstract programs independent
of any programming language, in which case our goal of defining a
particular language called "Burro" for this purpose seems a bit futile.

There are a couple of ways this could be resolved. We could foray into
domain theory, and try to impose a group structure on the semantics of
programs irrespective of the language they are in. Or we could venture
into representation theory, and see if the program texts can act as
generators of the group elements. Both of these approaches could be
interesting, but I chose an approach that I found to be less of a
distraction, and possibly more intuitive, at the cost of introducing a
slight variation on the notion of a group.

### Group Theory, revisited

To this end, let's examine the idea of a *group over an equivalence
relation*. All this is, really, is being specific about what constitutes
"equals" in those group axioms I listed earlier. In mathematics there is
a well-established notion of an *equivalence relation* — a relationship
between elements which paritions a set into disjoint equivalence
classes, where every element in a class is considered equivalent to
every other element in that same class (and inequivalent to any element
in any other class.)

We can easily define an equivalence relation on programs (that is,
program texts.) We simply say that two programs are equivalent if they
have the same semantics: they map the same inputs to the same outputs,
they compute the same function, they "do the same thing" as far as an
external observer can tell, assuming he or she is unconcerned with
performance issues. As you can imagine, this relation will be very
useful for our purpose.

We can also reformulate the group axioms using an equivalence relation.
At the very least, I can't see why it should be invalid to do so.
(Indeed, this seems to be the general idea behind using "quotients" in
abstract algebra. In our case, we have a set of program texts and a
"semantic" equivalence relation "are equivalent programs", and the
quotient set is the set of all computable functions regardless of their
concrete representation.)

So let's go ahead and take that liberty. The resulting algebraic
structure should be quite similar to what we had before, but with the
equivalence classes becoming the real "members" of the group, and with
each class containing many individual elements which are treated
interchangably with respect to the group axioms.

I'll summarize the modified definition here. A *group over an
equivalence relation* is a triple 〈S,·,≡〉 where:

-   S is a set
-   · : S × S → S is a binary operation over S
-   ≡ is a reflexive, transitive, and symmetrical binary relation over S

where the following axioms are also satisfied:

-   ∀ _a_, _b_, _c_ ∈ S: (_a_ · _b_) · _c_ ≡ _a_ · (_b_ · _c_)
-   ∃ **e** ∈ S: ∀ _a_ ∈ S: _a_ · **e** ≡ **e** · _a_ ≡ _a_
-   ∀ _a_ ∈ S: ∃ _a'_ ∈ S: _a_ · _a'_ ≡ **e**

Every theorem that applies to groups should be easy to modify to be
applicable to a group over an equivalence relation: just replace = with
≡. So what we have, for example, is that while any given **e** itself
might not be unique, the equivalence class **E** ⊆ S that contains it
is: **E** is the only equivalence class that contains elements like
**e** and, for the purposes of the group, all of these elements are
interchangeable.

(3) Syntax and Semantics
------------------------

### Five-instruction Foundation

Burro is intended to be Brainfuck-like, so we could start by examining
which parts of Brainfuck are already suitable for Burro and which parts
will have to be modified or rejected.

First, note that Brainfuck is traditionally very lenient about what
constitutes a "no-op" instruction. Just about any symbol that isn't
explicitly mentioned in the instruction set is treated as a no-op (and
this behaviour turns out to be useful for inserting comments in
programs.) In Burro, however, we'll strive for better clarity by
defining an explicit "no-op" instruction. For consistency with the group
theory side of things, we'll call it `e`. (Of course, we won't forget
that `e` lives in an equivalence class with other things like `+-` and
the zero-length program, and all of these things are semantically
interchangeable. But `e` gives us a nice, single-symbol, canonical
program form when we want to talk about it.)

Now let's consider the basic Brainfuck instructions `+`, `-`, `<`, and
`>`. They have a nice, symmetrical organization that is ideally suited
to group structure, so we will adopt them in our putative Burro design.

On the other hand, the instructions `.` and `,` will require devising
some kind of annihilator for interactive input and output. This seems
difficult at least, and not really necessary if we're willing to forego
writing "Hunt the Wumpus" in Burro, so we'll leave them out for now. The
only input for a Burro program is, instead, the initial state of the
tape, and the only output is the final state.

In addition, `[` and `]` will cause problems, because as we saw in the
introduction, `[-]+[]` is an infinite loop, and it's not clear what we
could use to annihilate it. We'll defer this question for later and for
the meantime leave these instructions out, too.

What we're left in our "Burro-in-progress" is essentially a very weak
subset of Brainfuck, with only the five instructions `+-><e`. But this
is a starting point that we can use to see if we're on the right track.
Do the programs formed from strings of these instructions form a group
under concatenation over the semantic equivalence relation? i.e., Does
every Burro program so far have an inverse?

Let's see. For every *single-instruction* Burro program, we can
evidently find another Burro instruction that, when appended to it,
"cancels it out" and makes a program with the same semantics as `e`:

  Instruction   Inverse   Concatenation   Net effect
  ------------- --------- --------------- ------------
  `+`           `-`       `+-`            `e`
  `-`           `+`       `-+`            `e`
  `>`           `<`       `><`            `e`
  `<`           `>`       `<>`            `e`
  `e`           `e`       `ee`            `e`

Note that we once again should be more explicit about our requirements
than Brainfuck. We need to have a tape which is infinite in both
directions, or else `<` wouldn't always be the inverse of `>` (because
sometimes it'd fail in some way like falling off the edge of the tape.)
And, so that we don't have to worry about overflow and all that rot,
let's say cells can take on any unbounded negative or positive integer
value, too.

But does this hold for *any* Burro program? We can use structural
induction to determine this. Can we find inverses for every Burro
program, concatenated with a given instruction? (In the following table,
*b* indicates any Burro program, and *b'* its inverse. Also note that
*bb'* is, by definition, `e`.)

  Instruction   Inverse                Concatenation              Net effect
  ------------- ---------------------- -------------------------- ------------
  `b+`          `-b'`                  `b+-b'` ≡ `beb'` ≡ `bb'`   `e`
  `b-`          `+b'`                  `b-+b'` ≡ `beb'` ≡ `bb'`   `e`
  `b>`          `<b'`                  `b><b'` ≡ `beb'` ≡ `bb'`   `e`
  `b<`          `>b'`                  `b<>b'` ≡ `beb'` ≡ `bb'`   `e`
  `be` ≡ `b`    `eb'` ≡ `b'e` ≡ `b'`   `bb'`                      `e`

Looks good. However, this isn't an abelian group, and concatenation is
definately not commutative. So, to be complete, we need a table going in
the other direction, too: concatenation of a given instruction with any
Burro program.

  Instruction   Inverse                Concatenation            Net effect
  ------------- ---------------------- ------------------------ ------------
  `+b`          `b'-`                  `+bb'-` ≡ `+e-` ≡ `+-`   `e`
  `-b`          `b'+`                  `-bb'+` ≡ `-e+` ≡ `-+`   `e`
  `>b`          `b'<`                  `>bb'<` ≡ `>e<` ≡ `><`   `e`
  `<b`          `b'>`                  `<bb'>` ≡ `<e>` ≡ `<>`   `e`
  `eb` ≡ `b`    `b'e` ≡ `eb'` ≡ `b'`   `bb'`                    `e`

So far, so good, I'd say. Now we can address to the problem of how to
restrengthen the language so that it remains as powerful as Brainfuck.

### Loops

Obviously, in order for Burro to be as capable as Brainfuck, we would
like to see some kind of looping mechanism in it. But, as we've seen,
Brainfuck's is insufficient for our purposes, because it allows for the
construction of infinite loops that we can't invert by concatenation.

We could insist that all loops be finite, but that would make Burro less
powerful than Brainfuck — it would only be capable of expressing the
primitive recursive functions. The real challenge is in having Burro be
Turing-complete, like Brainfuck.

This situation looks dire, but there turns out to be a way. What we do
is borrow the trick used in languages like [L00P][] and [Version][] (and
probably many others.) We put a single, implicit loop around the whole
program. (There is a classic formal proof that this is sufficient — the
interested reader is referred to the paper "Kleene algebra with
tests" [(Footnote 1)](#footnote-1), which gives a brief history,
references, and its own proof.)

This single implicit loop will be conditional on a special flag, which
we'll call the "halt flag", and we'll stipulate is initially set. If
this flag is still set when the end of the program is reached, the
program halts. But if it is unset when the end of the program is
reached, the flag is reset and the program repeats from the beginning.
(Note that although the halt flag is reset, all other program state
(i.e. the tape) is left alone.)

To manipulate this flag, we introduce a new instruction:

  Instruction   Semantics
  ------------- ------------------
  `!`           Toggle halt flag

Then we check that adding this instruction to Burro's instruction set
doesn't change the fact that Burro programs form a group:

  Instruction   Inverse   Concatenation              Net effect
  ------------- --------- -------------------------- ------------
  `!`           `!`       `!!`                       `e`
  `!b`          `b'!`     `!bb'!` ≡ `!e!` ≡ `!!`     `e`
  `b!`          `!b'`     `b!!b'` ≡ `beb'` ≡ `bb'`   `e`

Seems so. Now we can write Burro programs that halt, and Burro programs
that loop forever. What we need next is for the program to be able to
decide this behaviour for itself.

[L00P]: https://esolangs.org/wiki/L00P
[Version]: https://esolangs.org/wiki/Version

### Conditionals

OK, this is the ugly part.

Let's add a simple control structure to Burro. Since we already have
repetition, this will only be for conditional execution. To avoid
confusion with Brainfuck, we'll avoid `[]` entirely; instead, we'll use
`()` to indicate "execute the enclosed code (once) if and only if the
current cell is non-zero".

Actually, let's make it a bit fancier, and allow an "else" clause to be
inserted in it, like so: `(/)` where the code before the `/` is executed
iff the cell is non-zero, and the code after the `/` is executed iff it
is zero.

(The reasons for this design choice are subtle. They come down to the
fact that in order to find an inverse of a conditional, we need to
invert the sense of the test. In a higher-level language, we could use a
Boolean NOT operation for this. However, in Brainfuck, writing a NOT
requires a loop, and thus a conditional. Then we're stuck with deciding
how to invert the sense of *that* conditional, and so forth. By
providing NOT-like behaviour as a built-in courtesy of `/`, we dodge the
problem entirely. If you like, you can think of it as meeting the
aesthetic demands of a symmetrical language: the conditional structures
are symmetrical too.)

A significant difference here with Brainfuck is that, while Brainfuck is
a bit lacksidaisical about matching up `[`'s with `]`'s, we explicitly
*disallow* parentheses that do not nest correctly in Burro. A Burro
program with mismatched parentheses is an ill-formed Burro program, and
thus not really a Burro program at all. We turn up our nose at it; we
aren't even interested in whether we can find an inverse of it, because
we don't acknowledge it. This applies to the placement of `/` outside of
parentheses, or the absence of `/` in parentheses, as well.

(The reasons for this design choice are also somewhat subtle. I
originally wanted to deal with this by saying that `(`, `/`, and `)`
could come in any order, even a nonsensical one, and still make a valid
Burro program, only with the semantics of "no-op" or "loop forever" or
something equally representative of "broken." You see this quite often
in toy formal languages, and the resulting lack of syntax would seem to
allow the set of Burro instructions to be a "free generator" of the
group of Burro programs, which sounds like it might have very nice
abstract-algebraical properties. The problem is that it potentially
interferes with the whole "finding an antiprogram" thing. If a Burro
program with mismatched parentheses has the semantics of "no-op", then
every Burro program has a trivial annihilator: just tack on an
unmatching parenthesis. Similarly, if malformed programs are considered
to loop forever, how do you invert them? So, for these reasons, Burro
has some small amount of syntax — a bit more than Brainfuck is usually
considered to have, but not much.)

Now, it turns out we will have to do a fair bit of work on `()` in order
to make it so that we can always find a bit of code that is the inverse
of some other bit of code that includes `()`.

We can't just make it a "plain old if", because by the time we've
finished executing an "if", we don't know which branch was executed — so
we have no idea what the "right" inverse of it would be. For example,

    (-/e)

After this has finished executing, the current cell could contain 0 -
but is that because it was already 0 before the `(` was encountered, and
nothing happened to it inside the "if"... or is it because it was 1
before the `(` was encountered, and decremented to 0 by the `-`
instruction inside the "if"? It could be either, and we don't know — so
we can't find an inverse.

We remedy this in a somewhat disappointingly uninteresting way: we make
a copy of the value being tested and squirrel it away for future
reference, so that pending code can look at it and tell what decision
was made, and in so doing, act appropriately to invert it.

This information that we squirrel away is, I would say, a kind of
*continuation*. It's not a full-bodied continuation, as the term
continuation is often used, in the sense of "function representing the
entire remainder of the computation." But, it's a bit of context that is
retained during execution that is intended to affect some future control
flow decision — and that's the basic purpose of a continuation. So, I
will call it a continuation, although it is perhaps a diminished sort of
continuation. (In this sense, the machine stack where arguments and
return addresses are stored in a language like C is also a kind of
continuation.)

These continuations that we maintain, these pieces of information that
tell us how to undo things in the future, do need to have an orderly
relationship with each other. Specifically, we need to remember to undo
the more recent conditionals first. So, we retain the continuations in a
FIFO discipline, like a stack. Whenever a `(` is executed, we "push" a
continuation into storage, and when we need to invert the effect of a
previous conditional, we "pop" a continuation from storage.

To actually accomplish this latter action we need to define the control
structure for undoing conditional tests. We introduce the construct
`{\}`, which works just like `(/)`, except that the value that it tests
doesn't come from the tape — instead, it comes from the continuation. We
establish similar syntactic rules about matching every `{` with a `}`
and an intervening `\`, in addition to a rule that says every `{\}` must
be preceded by a `(/)`.

With this, we're very close to having an inverse for conditionals.
Consider:

    (-/e){+\e}

If the current cell contains 0 after `(-/e)`, the continuation will
contain either a 1 or a 0 (the original contents of the cell.) If the
continuation contains a 0, the "else" part of `{+\e}` will be executed —
i.e. nothing will happen. On the other hand, if the continuation
contains a 1, the "then" part of `{+\e}` will be executed. Either way,
the tape is correctly restored to its original (pre-`(-/e)`) state.

There are still a few details to clean up, though. Specifically, we need
to address nesting. What if we're given

    (>(<+/e)/e)

How do we form an inverse of this? How would the following work?

    (>(<+/e)/e){{->\e}<\e}

The problem with this, if we collect continuations using only a naive
stack arrangement, is that we don't remember how many times a `(` was
encountered before a matching `)`. The retention of continuations is
still FIFO, but we need more control over the relationships between the
continuations.

The nested structure of the `(/)`'s suggests a nested structure for
collecting continuations. Whenever we encounter a `(` and we "push" a
continuation into storage, that continuation becomes the root for a new
collection of continuations (those that occur *inside* the present
conditional, up to the matching `)`.) Since each continuation is both
part of some FIFO series of continuations, and has the capacity to act
as the root of it's *own* FIFO series of continuations, the
continuations are arranged in a structure that is more a binary tree
than a stack.

This is perhaps a little complicated, so I'll summarize it in this
table. Since this is a fairly operational description, I'll use the term
"tree node" instead of continuation to help you visualize it. Keep in
mind that at any given time there is a "current continuation" and thus a
current tree node.

#### Instruction: `(`

-   Create a new tree node with
    the contents of the current
    cell
-   Add that new node as a child
    of the current node
-   Make that new node the new
    current node
-   If the current cell is zero,
    skip one instruction past the
    matching `/`

#### Instruction: `/`

-   Skip to the matching `)`

#### Instruction: `)`

-   Make the parent of the
    current node the new current
    node

#### Instruction: `{`

-   Make the most recently added
    child of the current node the
    new current node
-   If the value of the current
    node is zero, skip one
    instruction past the matching `\`

#### Instruction: `\`

-   Skip to the matching `}`

#### Instruction: `}`

-   Make the parent of the
    current node the new current
    node
-   Remove the old current node
    and all of its children

Now, keeping in mind that the continuation structure remains constant
across all Burro programs equivalent to `e`, we can show that control
structures have inverses:

  Instruction   Inverse         Test result   Concatenation                    Net effect
  ------------- --------------- ------------- -------------------------------- ------------
  `a(b/c)d`     `d'{b'\c'}a'`   zero          `acdd'c'a'` ≡ `acc'a'` ≡ `aa'`   `e`
  `a(b/c)d`     `d'{b'\c'}a'`   non-zero      `abdd'b'a'` ≡ `abb'a'` ≡ `aa'`   `e`

There you have it: every Burro program has an inverse.

(4) Implementations
-------------------

There are two reference interpreters for Burro. `burro.c` is written in
ANSI C, and `burro.hs` is written in Haskell. Both are BSD licensed.
Hopefully at least one of them is faithful to the execution model.

### `burro.c`

The executable produced by compiling `burro.c` takes the following
command-line arguments:

-   `burro [-d] srcfile.bur`

The named file is loaded as Burro source code. All characters in this
file except for `><+-(/){\}e!` are ignored.

Before starting the run, the interpreter will read a series of
whitespace-separated integers from standard input. These integers are
placed on the tape initially, starting from the head-start position,
extending right. All unspecified cells are considered to contain 0
initially.

When the program has halted, all tape cells that were "touched" — either
given initially as part of the input, or passed over by the tape head —
are output to standard output.

The meanings of the flags are as follows:

-   The `-d` flag causes debugging information to be sent to standard
    error.

The C implementation performs no syntax-checking. It approximates the
unbounded Burro tape with a tape of finite size (defined by `TAPE_SIZE`,
by default 64K) with cells each capable of containing a C language
`long`.

### `burro.hs`

The Haskell version of the reference implementation is meant to be
executed from within an interactive Haskell environment, such as Hugs.
As such, there is no command-line syntax; the user simply invokes the
function `burro`, which has the signature
`burro :: String -> Tape -> Tape`. A convenience constructor
`tape :: [Integer] -> Tape` creates a tape from the given list of
integers, with the head positioned over the leftmost cell.

The Haskell implementation performs no syntax-checking. Because Haskell
supports unbounded lists and arbitrary-precision integers, the Burro
tape is modelled faithfully.

Discussion
----------

I hadn't intended to come up with anything in particular when I started
designing Burro. I'm hardly a mathematician, and I didn't know anything
about abstract algebra except that I found it intriguing. I suppose that
algebraic structures have some of the same appeal as programming
languages, what with both dealing with primitive operators, equivalent
expression forms, and so forth.

I was basically struck by the variety of objects that could be shown to
have this or that algebraic structure, and I wanted to see how well it
would hold up if you tried to apply these structures to programs.

Why groups? Well, the original design goal for Burro was actually to
create a Brainfuck-like language where the set of possible programs
forms the most *restricted* possible magma (i.e. the one with the most
additional axioms) under concatenation. It can readily been seen that
the set of Brainfuck programs forms a semigroup, even a monoid, under
concatenation (left as an exercise for the interested reader.) At the
other extreme, if the set of programs forms an abelian group under
concatenation, the language probably isn't going to be very
Brainfuck-like (since insisting that concatenation be commutative is
tantamount to saying that the order of instructions in a program doesn't
matter.) This leaves a group as the reasonable target to aim for, so
that's what I aimed for.

But the end result turns out to be related to *reversible computing*.
This shouldn't have been a surprise, since groups are one of the
simplest foundations for modelling symmetry; it should have been obvious
to me that trying to make programs conform to them, would make them
(semantically) symmetrical, and thus reversible. But, it wasn't.

We may ask: in what sense is Burro reversible? And we may compare it to
other esolangs in an attempt to understand.

Well, it's not reversible in the sense that
[Befreak](http://esolangs.org/wiki/Befreak) is reversible — you can't
pause it at any point, change the direction of execution, and watch it
"go backwards". Specifically, you can't "undo" a loop in Burro by
executing 20 iterations, then turning around and "un-executing" those 20
iterations; instead, you "undo" the loop by neutralizing the toggling of
the halt flag. With this approach, inversion is instead *like the loop
never existed in the first place*.

If one did want to make a Brainfuck-like language which was reversible
more in the sense that Befreak is reversible, one approach might be to
add rules like "`+` acts like `-` if the program counter is incoming
from the right". But, I haven't pondered on this approach much at all.

Conversely, the concatenation concept doesn't have a clear
correspondence in a two-dimensional language like Befreak — how do you
put two programs next to each other? Side-by-side, top-to-bottom? You
would probably need multiple operators, which would definately
complicate things.

It's also not reversible in the same way that
[Kayak](http://esolangs.org/wiki/Kayak) is reversible — Burro programs
need not be palindromes, for instance. In fact, I specifically made the
"then" and "else" components of both `(/)` and `{\}` occur in the same
order, so as to break the reflectional symmetry somewhat, and add some
translational similarity.

Conversely, Kayak doesn't cotton to concatenation too well either. In
order to preserve the palindrome nature, concatenation would have to
occur both at the beginning and the end simultaneously. I haven't given
this idea much thought, and I'm not sure where it'd get you.

Lastly, we could go outside the world of esolangs and use the definition
of reversible computing given by Mike Frank [(Footnote 2)](#footnote-2):

> When we say reversible computing, we mean performing computation in
> such a way that any previous state of the computation can always be
> reconstructed given a description of the current state.

Burro appears to qualify by this definition — *almost*. The requirement
that we can reconstruct *any* previous state is a bit heavy. We can
definately reconstruct states up to the start of the last loop
iteration, if we want to, due to the mechanism (continuations) that
we've defined to remember what the program state was before any given
conditional.

But what about *before* the last loop iteration? Each time we reach the
end of the program text with halt flag unset, we repeat execution from
the beginning, and when this happens, there might still be one or more
continuations in storage that were the result of executing `(/)`'s that
did not have matching `{\}`'s.

We didn't say what happens to these "leftover" continuations. In fact,
computationally speaking, it doesn't matter: since syntactically no
`{\}` can precede any `(/)`, those leftover continuations couldn't
actually have any affect during the next iteration. Any `{\}` that might
consume them next time 'round must be preceded by a `(/)` which will
produce one for it to consume instead.

And indeed, discarding any continuation that remains when a Burro
program loops means that continuations need occupy only a bounded amount
of space during execution (because there is only a fixed number of
conditionals in any given Burro program.) This is a desirable thing in a
practical implementation, and both the C and Haskell reference
implementations do just this.

But this is an implementation choice, and it would be equally valid to
write an interpreter which retains all these leftover continuations. And
such an interpreter would qualify as a reversible computer under Mike
Frank's definition, since these continuations would allow one to
reconstruct the entire computation history of the program.

On this last point, it's interesting to note the similarity between
Burro's continuations and Kayak's bit bucket. Although Burro
continuations record the value tested, they really don't *need* to; they
*could* just contain bits indicating whether the tests were successes or
failures. Both emptying the bit bucket, and discarding continuations,
results in a destruction of information that prevents reversibility (and
thermodynamically "generates heat") but allows for a limit on the amount
of storage required.

History
-------

I began formulating Burro in the summer of 2005. The basic design of
Burro was finished by winter of 2005, as was the C implementation. But
its release was delayed for several reasons. Mainly, I was busy with
other (ostensibly more important) things, like schoolwork. However, I
also had the nagging feeling that certain parts of the language were not
quite described correctly. These doubts led me to introduce the concept
of a group over an equivalence relation, and to decide that Burro needed
real syntax rules (lest inverting a Burro program was "too easy.") So it
wasn't until spring of 2007 that I had a general description that I was
satisfied with. I also wanted a better reference implementation, in
something a bit more abstract and rigorous than C. So I wrote the
Haskell version over the summer of 2007.

In addition, part of me wanted to write a publishable paper on Burro.
After all, group theory and reversible computing are valid and
relatively mainstream research topics, so why not? But in the end,
considering doing this was really a waste of my time. Densening my
writing style to conform to acceptable academic standards of
impermeability, and puffing up my "discovery" to acceptable academic
standards of self-importance, really didn't appeal to me. There's no
sense pretending, in high-falutin' language, that Burro represents some
profound advance in human knowledge. It's just something neat that I
built! And in the end it seemed just as valuable, if not moreso, to try
to turn esolangers on to group theory than to turn academics on to
Brainfuck...

Happy annihilating!

-Chris Pressey  
Cat's Eye Technologies  
October 26, 2007  
Windsor, Ontario, Canada

Footnotes
---------

#### Footnote 1

-   Dexter Kozen. [Kleene algebra with tests](http://www.cs.cornell.edu/~kozen/papers/ckat.ps).
    *Transactions on Programming Languages and Systems*, 19(3):427-443, May 1997.

#### Footnote 2

-   Michael Frank.  What's Reversible Computing?
    [http://www.cise.ufl.edu/~mpf/rc/what.html](http://www.cise.ufl.edu/~mpf/rc/what.html)
