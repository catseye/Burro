--
-- burro.hs
-- Reference Interpreter for the Burro Programming Language
-- Chris Pressey, Cat's Eye Technologies
--
-- $Id: burro.hs 10 2007-10-10 01:17:52Z catseye $
--

--
-- Copyright (c)2007 Cat's Eye Technologies.  All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
--  1. Redistributions of source code must retain the above copyright
--     notices, this list of conditions and the following disclaimer.
--  2. Redistributions in binary form must reproduce the above copyright
--     notices, this list of conditions, and the following disclaimer in
--     the documentation and/or other materials provided with the
--     distribution.
--  3. Neither the names of the copyright holders nor the names of their
--     contributors may be used to endorse or promote products derived
--     from this software without specific prior written permission. 
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
-- LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
-- FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
-- COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
-- BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
-- LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
-- ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--

-----------------------------------------------------------------------
-- ========================== Data types =========================== --
-----------------------------------------------------------------------

import Char

data Instruction = Block [Instruction]
                 | Nop
                 | Inc
                 | Dec
                 | GoLeft
                 | GoRight
                 | ToggleHalt
                 | Test [Instruction] [Instruction]
                 | UnTest [Instruction] [Instruction]
    deriving (Show, Read, Eq)

--
-- Our abstract data type for representing the tape.  We represent the
-- tape as two stacks (lists).  The first list contains the cell under
-- the tape head, and everything left of the tape head (in reverse
-- order as it appears on the tape.)  The second list contains everything
-- to the right of the tape head, in the same order as it appears on the
-- tape.  A convenience function for creating an inital tape is also
-- provided.
--

data Tape = Tape [Integer] [Integer]
    deriving (Show, Read, Eq)

tape :: [Integer] -> Tape
tape x = Tape [head x] (tail x)

--
-- Our abstract data type for representing continuations.
--
-- A null continuation (NullCont) represents nothing more to be
-- done.
--
-- A test continuation (TestCont) represents the fact that a
-- conditional was performed, and remembers the value so tested
-- for future possible use in an UnTest that will undo the effect
-- of the conditional.
--
-- Test continuations can be composed in two ways:
--
-- One, when one conditional occurs after another, the test
-- continuations are sequentially stacked.  The continutation
-- representing the conditional test that happened most recently
-- is on the "outside", with the earlier continuation linked into
-- it, like so:
--   TestCont 2 (TestCont 1 NullCont)
--
-- Two, when one conditional occurs inside another, the test
-- continuations are hierarchically organized.  Because this
-- interpreter is recursive, (specifically because it recursively
-- executes the sequences of instructions inside each conditional,)
-- this hierarchical organization need not be explicitly represented
-- in our continuation structures.
--

data Continuation = TestCont Integer Continuation
                  | NullCont
    deriving (Show, Read, Eq)


-----------------------------------------------------------------------
-- ============================= Parser ============================ --
-----------------------------------------------------------------------

parse string =
    let
        (rest, acc) = parseProgram string []
    in
        acc

parseProgram [] acc =
    ([], acc)
parseProgram ('e':rest) acc =
    parseProgram rest acc
parseProgram ('+':rest) acc =
    parseProgram rest (acc ++ [Inc])
parseProgram ('-':rest) acc =
    parseProgram rest (acc ++ [Dec])
parseProgram ('<':rest) acc =
    parseProgram rest (acc ++ [GoLeft])
parseProgram ('>':rest) acc =
    parseProgram rest (acc ++ [GoRight])
parseProgram ('!':rest) acc =
    parseProgram rest (acc ++ [ToggleHalt])

parseProgram ('(':rest) acc =
    let
        (rest',  thenprog) = parseProgram rest []
        (rest'', elseprog) = parseProgram rest' []
        test = Test thenprog elseprog
    in
        parseProgram rest'' (acc ++ [test])
parseProgram ('/':rest) acc =
    (rest, acc)
parseProgram (')':rest) acc =
    (rest, acc)

parseProgram ('{':rest) acc =
    let
        (rest',  thenprog) = parseProgram rest []
        (rest'', elseprog) = parseProgram rest' []
        untest = UnTest thenprog elseprog
    in
        parseProgram rest'' (acc ++ [untest])
parseProgram ('\\':rest) acc =
    (rest, acc)
parseProgram ('}':rest) acc =
    (rest, acc)


-----------------------------------------------------------------------
-- =========================== Execution =========================== --
-----------------------------------------------------------------------

burro :: String -> Tape -> Tape

burro program tape =
    let
        internalRep = parse program
    in
        run internalRep internalRep tape True NullCont

run :: [Instruction] -> [Instruction] -> Tape -> Bool -> Continuation -> Tape

run [] origprog tape True cont =
    tape
run [] origprog tape False cont =
    run origprog origprog tape True NullCont

run (inst:insts) origprog tape halt cont =
    let
        (tape', halt', cont') = execute inst tape halt cont
    in
        run insts origprog tape' halt' cont'

execute :: Instruction -> Tape -> Bool -> Continuation -> (Tape, Bool, Continuation)

execute instr (Tape [] right) halt cont =
    execute instr (Tape [0] right) halt cont
execute Nop tape halt cont =
    (tape, halt, cont)
execute Inc (Tape (cell:left) right) halt cont =
    (Tape (cell + 1 : left) right, halt, cont)
execute Dec (Tape (cell:left) right) halt cont =
    (Tape (cell - 1 : left) right, halt, cont)
execute GoLeft (Tape (cell:left) right) halt cont =
    (Tape left (cell:right), halt, cont)
execute GoRight (Tape left []) halt cont =
    (Tape (0:left) [], halt, cont)
execute GoRight (Tape left (cell:right)) halt cont =
    (Tape (cell:left) right, halt, cont)
execute ToggleHalt tape halt cont =
    (tape, not halt, cont)
execute (Test con alt) tape@(Tape (0:left) right) halt cont =
    let
        (tape', halt', cont') = runSub alt tape halt NullCont
    in
        (tape', halt', TestCont 0 cont')
execute (Test con alt) tape@(Tape (cell:left) right) halt cont =
    let
        (tape', halt', cont') = runSub con tape halt NullCont
    in
        (tape', halt', TestCont cell cont')
execute (UnTest con alt) tape halt cont@(TestCont 0 prevcont) =
    runSub alt tape halt prevcont
execute (UnTest con alt) tape halt cont@(TestCont cell prevcont) =
    runSub con tape halt prevcont

runSub :: [Instruction] -> Tape -> Bool -> Continuation -> (Tape, Bool, Continuation)

runSub [] tape halt cont =
    (tape, halt, cont)
runSub (inst:insts) tape halt cont =
    let
        (tape', halt', cont') = execute inst tape halt cont
    in
        runSub insts tape' halt' cont'


-----------------------------------------------------------------------
-- =========================== Test Cases ========================== --
-----------------------------------------------------------------------

testCase 0 = "e"
testCase 1 = "!"
testCase 2 = "(-!/e)"
testCase 3 = "(-!/e){!+/e}"
testCase 4 = "(->(->(-/e)</e)</e)>(-/e)>(-/e)"
