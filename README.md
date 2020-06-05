Burro
=====

This is the reference distribution for Burro, a formal programming language
whose denoted programs form a group under concatenation of their program texts.

For the definition of the Burro language version 1.0, which was the
first attempt to do this but does not actually succeed in forming a group,
see the file [`doc/burro-1.0.md`](doc/burro-1.0.md).

For the definition of the Burro language version 2.0, which does indeed
form a group, see the Literate Haskell file `Burro.lhs` in the `src`
directory.  This also serves as a reference implementation of the language,
and includes a sketch of a proof that Burro is Turing-complete.

The sense in which Burro programs form a group
----------------------------------------------

The language version 1.0 and 2.0 documents don't do a great job of explaining
what is meant by the set of Burro programs forming a group — 1.0 tries
to explain by defining a new concept, a "group over an equivalence relation",
and 2.0 just carries on with the idea without elucidating it.  This new
concept is not necessary and I'll try to briefly provide a more conventional
description here.

Let B be the set of Burro program texts.  Burro program texts are just
strings of symbols, so B is a monoid under concatenation.

Every Burro program text _t_ represents some Burro program ⟦_t_⟧.
But because we typically ignore some operational aspects of execution,
multiple program texts can represent the same program.  For example,
`+-` and `-+` represent the same program.

In other words, ⟦⟧ is not injective, and because it is not injective,
it induces an equivalence relation.  If, for Burro program texts _s_ and _t_,
⟦_s_⟧ = ⟦_t_⟧, we say _s_ ~ _t_.

We can take the quotient of B by this equivalence relation
to obtain the quotient semigroup B/\~.  This is the set of all representable
Burro programs.  And in fact B/\~ is not only a semigroup, it is also a group.

Because B/\~ is a group, for every program _a_ in B/\~ there exists a
unique program _b_ in B/\~ such that _a_ * _b_ = e, where * is program composition
and e is the null program.

From this we infer that for every program text _s_ in B there exists a program
text _t_ in B such that ⟦_s_⟧ * ⟦_t_⟧ = ⟦_s_ _t_⟧ = e.

This is the sense in which Burro programs form a group, and in which every
Burro program text has an annihilator (in fact, it has infinitely many.)
