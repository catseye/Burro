-> encoding: UTF-8

The Burro Programming Language
==============================
Version 2.0  
June 2010, Chris Pressey, Cat's Eye Technologies  
Revised Summer 2020 (reformatted Markdown, renamed module, removed `main`)

Introduction
------------

Burro is a programming language whose programs form an algebraic group under
the operation of concatenation and over the equivalence relation of "computes
the same function."  This means that, for every Burro program, we can
construct a corresponding antiprogram that, when appended onto the first
program, results in a "no-op" program (a program with no effect — the
identity function.)

(In fact, for every set of Burro programs that compute the same function,
there is a corresponding set of antiprograms, any of which can "cancel out"
any program in the first set.  From our proof that Burro programs form a
group, we obtain a constructive algorithm which, for any given program, will
derive only one corresponding antiprogram, a kind of syntactic inverse.)

This is a kind of reversible computing, but Burro differs from most reversible
languages in that it is not the execution trace that is being "undone", but
the program itself that is being annihilated.

This document describes version 2.0 of the Burro language, a reformulation
which addresses several issues with Burro 1.0.  An update to the language was
desired by the author after it was pointed out by [ais523][] that the set of
Burro version 1.0 programs do not, in fact, form a proper group (the inverse
of `(/)` is `{\}`, but no inverse of `{\}` is defined; also, the implementations
(at least) did not support moving the tape head left past the "start" of the
tape, so `<>` was not a well-defined program.)

Additionally in this document, we construct a Burro 2.0 program equivalent to
a certain Turing machine.  While this Turing machine is not universal, the
translation method we use demonstrates how it would be possible to map an
arbitrary Turing machine to a Burro program, hopefully making uncontroversial
the idea that Burro qualifies as universal.

For further background information on the Burro project, you may also wish
to read the [Burro 1.0 article][], with the understanding that the language
description given there is obsolete.

[ais523]: https://esolangs.org/wiki/Ais523
[Burro 1.0 article]: ../../doc/burro-1.0.md


Changes from Burro 1.0
----------------------

The `{\}` construct does not appear in Burro 2.0.  Instead, the `(/)` construct
serves as its own inverse.  The tree-like structure of decision continuations
is not present in Burro 2.0 either.  Instead, decision information is kept on
a second tape, called the "stack tape".

Henceforth in this document, the term Burro refers to Burro 2.0.


About this Document
-------------------

This document is a reference implementation of Burro in literate Haskell,
using Markdown syntax for the textual prose portions (although the version
you are reading may have been converted to another format, such as HTML,
for presentation.)  As such, this document serves as an "executable
semantics", both defining the language and providing a ready tool.

>     module Language.Burro.Definition where


Inductive Definition of a Burro Program
---------------------------------------

The symbol `e` is a Burro program.  
The symbol `!` is a Burro program.  
The symbol `+` is a Burro program.  
The symbol `-` is a Burro program.  
The symbol `<` is a Burro program.  
The symbol `>` is a Burro program.  
If _a_ and _b_ are Burro programs, then `(`_a_`/`_b_`)` is a Burro program.  
If _a_ and _b_ are Burro programs, then _ab_ is a Burro program.  
Nothing else is a Burro program.  

>     data Burro = Null
>                | ToggleHalt
>                | Inc
>                | Dec
>                | GoLeft
>                | GoRight
>                | Test Burro Burro
>                | Seq Burro Burro
>         deriving (Read, Eq)


Representation of Burro Programs
--------------------------------

For a concrete representation, the symbols in the inductive definition
given above can be taken to be a subset of a character set; for the
purposes of this semantics, we will use the ASCII character set.  Parsing
a given string of symbols into a Burro program is straightforward; all
symbols which are not Burro symbols are simply ignored.

>     instance Show Burro where
>         show Null = "e"
>         show ToggleHalt = "!"
>         show Inc = "+"
>         show Dec = "-"
>         show GoLeft = "<"
>         show GoRight = ">"
>         show (Test a b) = "(" ++ (show a) ++ "/" ++ (show b) ++ ")"
>         show (Seq a b) = (show a) ++ (show b)
> 
>     parse string =
>             let
>                 (rest, acc) = parseProgram string Null
>             in
>                 trim acc
> 
>     parseProgram [] acc =
>         ([], acc)
>     parseProgram ('e':rest) acc =
>         parseProgram rest (Seq acc Null)
>     parseProgram ('+':rest) acc =
>         parseProgram rest (Seq acc Inc)
>     parseProgram ('-':rest) acc =
>         parseProgram rest (Seq acc Dec)
>     parseProgram ('<':rest) acc =
>         parseProgram rest (Seq acc GoLeft)
>     parseProgram ('>':rest) acc =
>         parseProgram rest (Seq acc GoRight)
>     parseProgram ('!':rest) acc =
>         parseProgram rest (Seq acc ToggleHalt)
>     parseProgram ('(':rest) acc =
>         let
>             (rest',  thenprog) = parseProgram rest Null
>             (rest'', elseprog) = parseProgram rest' Null
>             test = Test thenprog elseprog
>         in
>             parseProgram rest'' (Seq acc test)
>     parseProgram ('/':rest) acc =
>         (rest, acc)
>     parseProgram (')':rest) acc =
>         (rest, acc)
>     parseProgram (_:rest) acc =
>         parseProgram rest acc
> 
>     trim (Seq Null a) = trim a
>     trim (Seq a Null) = trim a
>     trim (Seq a b) = Seq (trim a) (trim b)
>     trim (Test a b) = Test (trim a) (trim b)
>     trim x = x


Group Properties of Burro Programs
----------------------------------

We assert these first, and when we describe the program semantics we will
show that the semantics do not violate them.

The inverse of `e` is `e`: `ee` = `e`  
The inverse of `!` is `!`: `!!` = `e`  
The inverse of `+` is `-`: `+-` = `e`  
The inverse of `-` is `+`: `-+` = `e`  
The inverse of `<` is `>`: `<>` = `e`  
The inverse of `>` is `<`: `><` = `e`  
If _aa'_ = `e` and _bb'_ = `e`, `(`_a_`/`_b_`)(`_b'_`/`_a'_`)` = `e`.  
If _aa'_ = `e` and _bb'_ = `e`, _abb'a'_ = `e`.  

>     inverse Null = Null
>     inverse ToggleHalt = ToggleHalt
>     inverse Inc = Dec
>     inverse Dec = Inc
>     inverse GoLeft = GoRight
>     inverse GoRight = GoLeft
>     inverse (Test a b) = Test (inverse b) (inverse a)
>     inverse (Seq a b) = Seq (inverse b) (inverse a)

For every Burro program _x_, `annihilationOf` _x_ is always equivalent
computationally to `e`.

>     annihilationOf x = Seq x (inverse x)


State Model for Burro Programs
------------------------------

Central to the state of a Burro program is an object called a tape.
A tape consists of a sequence of cells in a one-dimensional array,
unbounded in both directions.  Each cell contains an integer of unbounded
extent, both positive and negative.  The initial value of each cell is
zero.  One of the cells of the tape is distinguished as the "current cell";
this is the cell that we think of as having the "tape head" hovering over it
at the moment.

In this semantics, we represent a tape as two lists, which we treat as
stacks.  The first list contains the cell under the tape head, and
everything to the left of the tape head (in the reverse order from how it
appears on the tape.)  The second list contains everything to the right of
the tape head, in the same order as it appears on the tape.

>     data Tape = Tape [Integer] [Integer]
>         deriving (Read)
> 
>     instance Show Tape where
>         show t@(Tape l r) =
>             let
>                 (Tape l' r') = strip t
>             in
>                 show (reverse l') ++ "<" ++ (show r')

When comparing two tapes for equality, we must disregard any zero cells
farther to the left/right than the outermost non-zero cells.  Specifically,
we strip leading/trailing zeroes from tapes before comparison.  We don't
strip out a zero that a tape head is currently over, however.

Also, the current cell must be the same for both tapes (that is, tape heads
must be in the same location) for two tapes to be considered equal.

>     stripzeroes list = (reverse (sz (reverse list)))
>         where sz []       = []
>               sz (0:rest) = sz rest
>               sz x        = x
> 
>     ensurecell [] = [0]
>     ensurecell x  = x
> 
>     strip (Tape l r) = Tape (ensurecell (stripzeroes l)) (stripzeroes r)
> 
>     tapeeq :: Tape -> Tape -> Bool
>     tapeeq t1 t2 =
>         let
>             (Tape t1l t1r) = strip t1
>             (Tape t2l t2r) = strip t2
>         in
>             (t1l == t2l) && (t1r == t2r)
> 
>     instance Eq Tape where
>         t1 == t2 = tapeeq t1 t2

A convenience function for creating an inital tape is also provided.

>     tape :: [Integer] -> Tape
>     tape x = Tape [head x] (tail x)

We now define some operations on tapes that we will use in the semantics.
First, operations on tapes that alter or access the cell under the tape head.

>     inc (Tape (cell:left) right) = Tape (cell + 1 : left) right
>     dec (Tape (cell:left) right) = Tape (cell - 1 : left) right
>     get (Tape (cell:left) right) = cell
>     set (Tape (_:left) right) value = Tape (value : left) right

Next, operations on tapes that move the tape head.

>     left (Tape (cell:[]) right) = Tape [0] (cell:right)
>     left (Tape (cell:left) right) = Tape left (cell:right)
>     right (Tape left []) = Tape (0:left) []
>     right (Tape left (cell:right)) = Tape (cell:left) right

Finally, an operation on two tapes that swaps the current cell between
them.

>     swap t1 t2 = (set t1 (get t2), set t2 (get t1))

A program state consists of:

-    A "data tape";
-    A "stack tape"; and
-    A flag called the "halt flag", which may be 0 or 1.

The 0 and 1 are represented by False and True boolean values in this
semantics.

>     data State = State Tape Tape Bool
>         deriving (Show, Read, Eq)
> 
>     newstate = State (tape [0]) (tape [0]) True


Semantics of Burro Programs
---------------------------

Each instruction is defined as a function from program state to program
state.  Concatenation of instructions is defined as composition of
functions, like so:

If _ab_ is a Burro program, and _a_ maps state S to state S', and _b_ maps
state S' to S'', then _ab_ maps state S to state S''.

>     exec (Seq a b) t = exec b (exec a t)

The `e` instruction is the identity function on states.

>     exec Null s = s

The `!` instruction toggles the halt flag.  If it is 0 in the input state, it
is 1 in the output state, and vice versa.

>     exec ToggleHalt (State dat stack halt) = (State dat stack (not halt))

The `+` instruction increments the current data cell, while `-` decrements the
current data cell.

>     exec Inc (State dat stack halt) = (State (inc dat) stack halt)
>     exec Dec (State dat stack halt) = (State (dec dat) stack halt)

The instruction `<` makes the cell to the left of the current data cell, the
new current data cell.  The instruction `>` makes the cell to the right of the
current data cell, the new current data cell.

>     exec GoLeft (State dat stack halt) = (State (left dat) stack halt)
>     exec GoRight (State dat stack halt) = (State (right dat) stack halt)

`(`a`/`b`)` is the conditional construct, which is quite special.

First, the current data cell is remembered for the duration of the execution
of this construct — let's call it _x_.

Second, the current data cell and the current stack cell are swapped.

Third, the current stack cell is negated.

Fourth, the stack cell to the right of the current stack cell is made
the new current stack cell.

Fifth, if _x_ is positive, a is evaluated; if _x_ is negative, b is evaluated;
otherwise _x_ = 0 and neither is evaluated.  Evaluation occurs in the state
established by the preceding four steps.

Sixth, the stack cell to the left of the current stack cell is made
the new current stack cell.

Seventh, the current data cell and the current stack cell are swapped again.

>     exec (Test thn els) (State dat stack halt) =
>         let
>             x = get dat
>             (dat', stack') = swap dat stack
>             stack'' = right (set stack' (0 - (get stack')))
>             f = if x > 0 then thn else if x < 0 then els else Null
>             (State dat''' stack''' halt') = exec f (State dat' stack'' halt)
>             (dat'''', stack'''') = swap dat''' (left stack''')
>         in
>             (State dat'''' stack'''' halt')

We observe an invariant here: because only the `(`a`/`b`)` construct affects the
stack tape, and because it does so in a monotonic way — that is, both a
and b inside `(`a`/`b`)` have access only to the portion of the stack tape to the
right of what `(`a`/`b`)` has access to — the current stack cell in step seven
always holds the same value as the current stack cell in step two, except
negated.


Repetition
----------

The repetition model of Burro 2.0 is identical to that of Burro 1.0.
The program text is executed, resulting in a final state, S.  If, in
S, the halt flag is 1, execution terminates with state S.  On the other
hand, if the halt flag is 0, the program text is executed once more,
this time on state S, and the whole procedure repeats.  Initially the
halt flag is 1, so if `!` is never executed, the program never repeats.

Additionally, each time the program repeats, the stack tape is cleared.

>     run program state =
>         let
>             state'@(State dat' stack' halt') = exec program state
>         in
>             if
>                 not halt'
>             then
>                 run program (State dat' (tape [0]) True)
>             else
>                 state'


Central theorem of Burro
------------------------

We now have established enough definitions to give a proof of the central
theorem of Burro, which is:

*Theorem: The set of all Burro programs forms a group over computational
equivalence under the operation of concatenation.*

As covered in the Burro 1.0 article, a "group over an equivalence relation"
captures the notion of replacing the concept of equality in the group
axioms with the concept of equivalency.  Our particular equivalence relation
here is that two programs are equivalent if they compute the same function.

In order to show that a set G is a group, it is sufficient to show the
following four properties hold:

1. Closure: For all a, b in G, ab is also in G.

   This follows from the inductive definition of Burro programs.

2. Associativity: For all a, b and c in G, (ab)c ≡ a(bc).

   This follows from the definition of concatenation (sequential composition);
   it doesn't matter if we concatenate a with b first, then concatenate that
   with c, or if we concatenate b with c first, then concatenate a with that.
   Either way the result is the same string (or in this case, the same Burro
   program.)

3. Identity element: There exists an element e in G, such that for every
   element a in G, ea ≡ ae ≡ a.

   The instruction `e` in Burro has no effect on the program state.  Therefore
   concatenating it to any existing program, or concatenating any existing
   program to it, results in a computationally equivalent program.

4. Inverse element: For each a in G, there exists an element b in G such
   that ab ≡ ba ≡ e.

   This is the key property.  We first show that it holds for each element of
   the inductive definition of Burro programs.  We can then conclude, through
   structural induction, that all Burro programs have this property.

   1. Since `e` is the identity function on states, `e` is trivially its own
      inverse.

   2. Since toggling the halt flag twice is the same as not changing it at all,
      the inverse of `!` is `!`.

   3. By the definitions of incrementation and decrementation, and because
      data cells cannot overflow, the inverse of `+` is `-`, and the inverse
      of `-` is `+`.

   4. By the definitions of left and right, and because the data tape is
      unbounded (never reaches an end,) the inverse of `>` is `<`, and the
      inverse of `<` is `>`.

   5. The inverse of ab is b'a' where b' is the inverse of b and a' is the
      inverse of a.  This is because abb'a' ≡ aea' ≡ aa' ≡ e.

   6. The inverse of `(`a`/`b`)` is `(`b'`/`a'`)`.  (This is the key case of
      the key property.)  Going back to the definition of `(/)`, we see there
      are three sub-cases to consider.  Before execution of `(`a`/`b`)(`b'`/`a'`)`,
      the data tape may be in one of three possible states:

      1. The current data cell is zero.  So in `(`a`/`b`)`, _x_ is 0, which
         goes on the stack and the current data cell becomes whatever was on
         the stack (call it _k_.)  The 0 on the stack is negated, thus stays 0
         (because 0 - 0 = 0).  The stack head is moved right.  Neither a nor
         b is evaluated.  The stack head is moved back left.  The stack and
         data cells are swapped again, so 0 is back in the current data cell
         and k is back in the current stack cell.  This is the same as the
         initial configuration, so `(`a`/`b`)` is equivalent to e.  By the same
         reasoning, `(`b'`/`a'`)` ≡ e, and `(`a`/`b`)(`b'`/`a'`)` ≡ ee ≡ e.

      2. The current data cell is positive (_x_ > 0).  We first evaluate `(`a`/`b`)`.
         The data and stack cells are swapped: the current data cell becomes
         _k_, and the current stack cell becomes _x_ > 0.  The current stack cell
         is negated, so becomes -_x_ < 0.  The stack head is moved to the right.

         Because _x_ > 0, the first of the sub-programs, a, is now evaluated.
         The current data cell could be anything — call it _k'_.

         The stack head is moved back to the left, so that the current stack
         cell is once again -_x_ < 0, and it is swapped with the current data
         cell, making it -_x_ and making the current stack cell _k'_.
         
         We are now to evaluate `(`b'`/`a'`)`.  This time, we know the current data
         cell is negative (-_x_ < 0).  The data and stack cells are swapped:
         the current data cell becomes _k'_, and the current stack cell becomes
         -_x_ < 0.  The current stack cell is negated, so becomes _x_ > 0.  The
         stack head is moved to the right.

         Because -_x_ < 0, the second of the sub-programs, a', is now evaluated.
         Because a' is the inverse of a, and it is being applied to a state 
         that is the result of executing a, it will reverse this state to
         what it was before a was executed (inside `(`a`/`b`)`.)  This means the
         current data cell will become _k_ once more.

         The stack head is moved back to the left, so that the current stack
         cell is once again _x_ > 0, and it is swapped with the current data
         cell, making it _x_ and making the current stack cell _k_.  This is
         the state we started from, so `(`a`/`b`)(`b'`/`a'`)` ≡ e.

      3. Case 3 is an exact mirror image of case 2 — the only difference
         is that the first time through, _x_ < 0 and b is evaluated, thus the
         second time through, -_x_ > 0 and b' is evaluated.  Therefore
         `(`a`/`b`)(`b'`/`a'`)` ≡ e in this instance as well.

QED.


Driver and Unit Tests
---------------------

We define a few more convenience functions to cater for the execution
of Burro programs on an initial state.

>     interpret text = run (parse text) newstate

Although we have proved that Burro programs form a group, it is not a
mechanized proof, and only goes so far in helping us tell if the
implementation (which, for an executable semantics, is one and the same
as the formal semantic formulation) is correct.  Unit tests can't tell us
definitively that there are no errors in the formulation, but they can
help us catch a class of errors, if there is one present.

For the first set of test cases, we give a set of pairs of Burro programs.
In each of these pairs, both programs should be equivalent in the sense of
evaluating to the same tape given an initial blank tape.

For the second set, we simply give a list of Burro programs.  We test
each one by applying the `annihilationOf` function to it and checking that
the result of executing it on a blank tape is equivalent to `e`.

>     testCases = [
>                   ("+++",            "-++-++-++"),
>                   ("+(>+++</---)",   "->+++<"),
>                   ("-(+++/>---<)",   "+>---<"),
>                   ("(!/!)",          "e"),
>                   ("+(--------!/e)", "+(/)+"),
>                   ("+++(/)",         "---"),
>                   ("---(/)",         "+++"),
>                   ("+> +++ --(--(--(/>>>>>+)+/>>>+)+/>+)+",
>                    "+> >>> +(---(/+)/)+")
>                 ]

>     annihilationTests = [
>                            "e", "+", "-", "<", ">", "!",
>                            "++", "--", "<+<-", "-->>--",
>                            "(+/-)", "+(+/-)", "-(+/-)",
>                            "+(--------!/e)"
>                         ]

>     allTestCases = testCases ++ map nihil annihilationTests
>         where
>             nihil x = ((show (annihilationOf (parse x))), "e")

Our unit test harness evaluates to a list of tests which did
not pass.  If all went well, it will evaluate to the empty list.

>     test [] =
>         []
>     test ((a, b):cases) =
>         let
>             resultA = interpret a
>             resultB = interpret b
>         in
>             if
>                 resultA == resultB
>             then
>                 test cases
>             else
>                 ((a, b):(test cases))

Finally, some miscellaneous functions for helping analyze why the
Burro tests you've written aren't working :)

>     debug (a, b) = ((a, interpret a), (b, interpret b))

>     debugTests = map debug (test allTestCases)

[Ed. note: historically, the Burro 2.0 source has included a proof
of Turing-completeness of Burro here.  However, it has never been
a correct proof.  Despite this, the author remains convinced that
Burro 2.0 is in fact Turing-complete.  In 2020 there were some efforts
to produce a new, correct proof, however, these efforts are ongoing.
Until these efforts are complete, the incorrect proof has been
removed from this document to avoid confusion and false claims.]

Happy annihilating (for reals this time)!

-Chris Pressey  
Cat's Eye Technologies  
June 7, 2010  
Evanston, Illinois, USA
