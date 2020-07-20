-> encoding: UTF-8

TM2Burro
========

(In this document, "Burro" refers to Burro 2.x.)

This is a Turing machine to Burro compiler, the intent of which is to show
how that any Turing machine can be mechanically translated into a Burro
program, establishing that Burro is Turing-complete.

>     module Language.Burro.Proof.TM2Burro where

Encoding
--------

The configuration of the Turing machine is encoded onto the Burro program's
tape, in the following manner.

The states of the Turing machine's finite control are given contiguous
odd-numbered indexes starting at one.  For instance, if the Turing machine
has four states, the indexes are 1, 3, 5, 9.  The first state is always
the start state and the last state is always the halt state.

The symbols of the Turing machine are likewise identified by a set of
contiguous odd-numbered indexes starting at one.  For instance, simulating
a Turing machine with 2 symbols, on the Burro tape those two symbols would
be called 1 and 3.  Blank cells on the tape are considered to contain the
symbol 1.

Each cell of the Turing machine's tape maps to a series of cells on the
Burro program's tape:

    (state-index, sw1, sw2, ... sw_n_, symbol-on-tape, tw1, tw2, ... tw_m_)

The `sw`_i_ tape cells are scratch cells for working with the Turing machine's
state (`state-index`); likewise the `tw`_i_ tape cells are for working with the
Turing machine's current tape cell (`symbol-on-tape`).

The number of `sw` scratch cells needed is equal to the number of states
of the Turing machine's finite control.  The number of `tw` scratch cells is
equal to the number of symbols of the Turing machine's tape.

These scratch cells are required because how the Burro program will test
for different states and symbols is based on the extensible idiom for
conditionals in Burro given in [Tests.md](../../../../Tests.md), which
uses one scratch cell for each branch.

Simulation
----------

A single execution of the Burro program's body corresponds to a single step
of the Turing machine.  At the start of the Burro program, the halt flag is
set to 0.  Only executing the halt state will set it to 1.

The main structure of the Burro program's body is a large conditional
statement that checks the `state-index` for each of the possible states the
Turing machine could be in, and makes the transitions appropriate for that
state.

Burro tape cells are considered 0 if not initialized, so before checking
the `state-index`, the simulation needs to check if it's 0, and if so, write
a 1 there.  The same thing will need to apply to the `symbol-on-tape` when we
get around to testing it.

In pseudocode, our Burro program will look like this:

    unset halt flag
    ensure state-index is not 0
    if state-index == 1
        move over to symbol-on-tape
        ensure symbol-on-tape is not 0
        if symbol-on-tape == 1
            write new symbol-on-tape
            move to new simulated TM tape cell
            write new state-index
        elif symbol-on-tape == 3
            write new symbol-on-tape
            move to new simulated TM tape cell
            write new state-index
        elif ...
        endif
    elif state-index == 3
        move over to symbol-on-tape
        ensure symbol-on-tape is not 0
        if symbol-on-tape == 1
            write new symbol-on-tape
            move to new simulated TM tape cell
            write new state-index
        elif symbol-on-tape == 3
            write new symbol-on-tape
            move to new simulated TM tape cell
            write new state-index
        elif ...
        endif
    elif ...
    elif state-index == halt-state
        set halt flag
    endif

Translation
-----------

The Turing machine description should be supplied as a list of pairs: `(state-index, choices)`.
The `choices` is a list of quadruples: `(if-read-this-symbol, write-this-symbol, move-this-direction,
go-to-this-state-next)`.

The states in the Turing machine description must start at 1, be given in ascending order with
no gaps.  Similarly, each choices list must begin by testing for symbol 1, then 3, then 5, etc.,
with no gaps and no omissions (every choices list must name every possible symbol.)

>     type StateID = Integer
>     type SymbolID = Integer
>     type Choices = [(SymbolID, SymbolID, Integer, StateID)]
>     type TMDesc = [(StateID, Choices)]

Some helper functions.

How many states are in this Turing machine?

>     numStatesOf tmDesc = length tmDesc

How many symbols are in this Turing machine?

>     numSymbolsOf ((_, choices):rest) = length choices

How many Burro cells are needed to contain a single simulated Turing machine cell?

>     sizeOfTMCell tmDesc = 1 + (numStatesOf tmDesc) + 1 + (numSymbolsOf tmDesc)

Emit _n_ copies of a Burro instruction.

>     emitMany i 0 = ""
>     emitMany i n = i ++ emitMany i (n-1)

Write a symbol to the tape, assuming the current Burro tape cell contains 0.

>     write n = emitMany "+" n

Move to a new simulated Turing machine tape cell.  Either -1 for left one cell,
or 1 for right one cell.

This is complicated by the fact that the number of work cells depends on
the number of states and the number of symbols.

>     move (-1) tmDesc = emitMany "<" (sizeOfTMCell tmDesc)
>     move 1 tmDesc = emitMany ">" (sizeOfTMCell tmDesc)
>     move 0 tmDesc = ""
