Burro
=====

This is the reference distribution for Burro, a formal programming language
whose programs form a _group_ (an algebraic structure from group theory).
The precise sense of this statement is explained below, but the following
can be taken as a high-level summary:
For every Burro program text, there exists an "annihilator" program text which,
when concatenated to the original program text, forms a "no-op" program.

For the definition of the Burro language version 1.0, which was the
first attempt to do this but does not actually succeed in forming a group,
see the file [`doc/burro-1.0.md`](doc/burro-1.0.md).

For the definition of the Burro language version 2.0, whose program do
indeed form a group, see the Literate Haskell file
[`Language/Burro/Definition.lhs`](src/Language/Burro/) in the
`src` directory.  This definition also serves as a reference implementation
of the language.

The sense in which Burro programs form a group
----------------------------------------------

The documentation efforts for versions 1.0 and 2.0 of Burro don't do a
really good job of explaining what is meant by the set of Burro programs
"forming a group".  Burro 1.0 tries to explain it by defining a new concept,
a "group over an equivalence relation", and 2.0 just carries on with that idea
without elucidating it.  This new concept is not really necessary, however, and
I'll try to briefly provide a more conventional explication here.

Let **B** be the set of syntactically valid Burro program texts (hereinafter
simply "program texts").  **B** is defined by an inductive definition, so it
can be thought of as an algebraic structure with a number of operations of
various arities.

Every program text _t_ represents some Burro program, which we will denote by
⟦_t_⟧.  Because we are happy to ignore most operational aspects of execution,
we think of the program as a function that maps inputs to outputs, and for
this reason, for any given program, there may be multiple program texts that
represent it.  For example, `+-` and `-+` represent the same program.  To put
it another way, the mapping ⟦∙⟧ is not injective.

Furthermore, because ⟦∙⟧ is defined in a syntax-directed fashion, it is a
_homomorphism_ between **B** and the set of Burro programs; for each of the
operations of the algebra on **B** there is a corresponding operation on
the set of Burro programs.

Even furthermore, because ⟦∙⟧ is a homomorphism, it induces an equivalence
relation (indeed, a congruence relation) between the two sets.
For any program texts _s_ and _t_, if ⟦_s_⟧ = ⟦_t_⟧, we say _s_ ~ _t_, or
(in English) we say that _s_ and _t_ are congruent program texs.

We can take the quotient of **B** by this congruence relation to obtain the
algebraic structure **B**/\~.  This is the set of all Burro programs representable
by B, which is by definition the set of all Burro programs.

We now get into what we mean by "group language".  Because **B**/\~
"inherits" all of the operations from **B**, it has two properties:

*   the identity function is an element of **B**/\~, because it
    is the meaning of the program text `e` (or a program text of length zero.)
*   because two program texts in **B** can be concatenated to form a
    new program text in **B**, two programs in **B**/\~ can be composed
    in analogous way to form a new program in **B**/\~.

In addition, **B**/\~ has the following property that **B** does *not* have:
For every program _p_ in **B**/\~, there exists another program _q_ in **B**/\~
such that the composition of these two programs is the identity function ⟦`e`⟧.

And, although this follows directly from the definitions, it's important
to note this: because the program _q_ is in **B**/\~, and **B**/\~ is the
result of taking the quotient of the congruence relation, we know there
exists at least one, and indeed, in general, many program texts _t_ that
represent _q_.

And (again, although this may be a bit straightforward,) because ⟦∙⟧ is defined
in a syntax-directed fashion, we can do the following:  Given a program text _s_,
we can find ⟦_s_⟧ (call it _p_), then we can find the function _q_ that when
composed with _p_ results in the identity function ⟦`e`⟧, and lastly we can find a
program text _t_ such that ⟦_t_⟧ = _q_.

(In fact, the reason we know we can find such a _t_ is because we have
syntax-directed rules for finding a _t_ from any given _s_, and we can show that
the composition of ⟦_s_⟧ and ⟦_t_⟧ always equals ⟦`e`⟧.)

So, that is the sense in which we say that the set of Burro programs forms a
group, and in which every syntactically valid Burro program text has an annihilator.
