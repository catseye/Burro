Burro
=====

This is the reference distribution for Burro, a formal programming language
whose denoted programs form a group under concatenation of their program texts.

For the definition of the Burro language version 1.0, which was the
first attempt to do this but does not actually succeed in forming a group,
see the file [`doc/burro-1.0.md`](doc/burro-1.0.md).

For the definition of the Burro language version 2.0, which does indeed
form a group, see the Literate Haskell file [`Burro.lhs`](src/Language/) in the
`src/Language` directory.  This also serves as a reference implementation of
the language, and includes a sketch of a proof that Burro is Turing-complete.

The sense in which Burro programs form a group
----------------------------------------------

The language version 1.0 and 2.0 documents don't do a great job of explaining
what is meant by the set of Burro programs forming a group — 1.0 tries
to explain by defining a new concept, a "group over an equivalence relation",
and 2.0 just carries on with the idea without elucidating it.  This new
concept is not necessary and I'll try to briefly provide a more conventional
description here.

Let B be the set of syntactically valid Burro program texts (hereinafter
simply "program texts").  B is defined by an inductive definition, so can be
thought of as an algebraic structure with a number of operations of various arities.

Every program text _t_ represents some Burro program, which we will denote by
⟦_t_⟧.  But because we typically ignore some operational aspects of execution,
multiple program texts can represent the same program.  For example,
`+-` and `-+` represent the same program.

In other words, ⟦⟧ is not injective. It is a homomorphism between B and the
set of Burro programs, and as such it induces an equivalence relation.  If,
for program texts _s_ and _t_, ⟦_s_⟧ = ⟦_t_⟧, we say _s_ ~ _t_.

We can take the quotient of B by this equivalence relation to obtain the
algebraic structure B/\~.  This is the set of all Burro programs representable
by B, which is by definition the set of all Burro programs.

However, in [`Burro.lhs`](src/Language/) we go on to show that B/\~ is not
merely an algebraic structure, it is in fact a group.

Because B/\~ is a group, for every program _a_ in B/\~ there exists a unique
Burro program _b_ in B/\~ such that _a_ * _b_ = e, where * is program composition
and e is the null program.

From this, working backwards through the homomorphism (so to speak), we can infer
that, for every program text _s_ in B there exists a program text _t_ in B
such that ⟦_s_⟧ * ⟦_t_⟧ = ⟦_s_ _t_⟧ = e.  (In fact, for every _s_ there are
infinitely many such _t_'s.)

This is the sense in which the set of Burro programs forms a group, and in which
every syntactically valid Burro program text has an annihilator.
