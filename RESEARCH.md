# Research notes

The longer argument behind [Nomos](README.md): what problem it addresses, what
it commits to, where it sits relative to existing work, what has and has not
been established, and what would refute it. Written to be argued with.

---

## 1. The problem

Law is one of the largest and most consequential bodies of structured reasoning
humans produce, and it resists formalisation in a specific way that
mathematics does not.

The obvious difficulty is vagueness. Legal rules are full of terms — "reasonable
efforts", "due care", "material", "undue hardship" — that have no definition
and are not going to acquire one. 
A less obvious difficulty, and perhaps a harder one, is that legal reasoning is
**ampliative by design**. A tribunal deciding a case that no rule covers does
not thereby fail; but rather does what the institution exists to do (namely, decide on rules). Rules are extended
by analogy to cases nobody anticipated, distinguished on facts nobody wrote
down, and defeated by exceptions that arrive as separate rules years later. A
formalism that represents law as a set of propositions with fixed consequences
represents a legal order that simply does not exist; an empty, formal fantasy, if you will.

A third difficulty is more practical: when it comes to thinking about "learning the law", one quickly realizes that **there is no canonical notion of ground truth**. In
mathematics an autoformalisation of some part of mathematics can be checked by proving something with it.
In law there is no analogue. A formalisation of a statute can be well-typed,
plausible, fluent and simply wrong about what the statute holds, and nothing in
the formal apparatus will notice.

Nomos is an attempt at all three at once. The bet is that they have a common
solution: if you model legal reasoning as *constraint by decided cases* rather
than as deduction from stated rules, then vagueness becomes a gap in the record
rather than a gap in the model, analogical extension becomes a relation you can
state and prove things about, and a formalisation becomes checkable against the
other formalisations around it.

---

## 2. The committments of our approach

We make five committments. 

**Liability is the primitive.** Not rights, duties, obligations or permissions.
The [README](README.md#why-liability-comes-first) argues this at length: the
sources clearly use concepts of liability; rights turn out to be exactly definable from them
(`privilege_is_waiver`); and modern private law, especially commercial and
corporate law, is organised around exposure to loss rather than around
entitlement. The cost of the commitment is that public law (jurisdiction,
procedure, constitutional constraint) is largely invisible to the model, at least for now (unless such statutes can be 
understood as "limits" of private law iteratively applied, which is in our minds a plausible hypothesis).

**Facts are one-sided reasons.** Following HYPO, CATO and Horty & Bench-Capon's
formal reconstruction, a *factor* is a stereotypical pattern of fact that counts
as a reason for exactly one party. A fact that could cut either way is modelled
as two factors, never one with a sign. This is what makes the a fortiori
relation well defined, and it is the most restrictive modelling choice
in the project.

**Precedent constrains a fortiori, not by similarity.** A case binds a later
one when the later one is *at least as strong* for the winner: everything the
earlier tribunal relied on is present, and the later case raises no
counter-reason the earlier one did not already face. Thus, two superficially similar cases can come out differently, and the
fact that makes them differ is often a single word.

**Vague standards are comparatives plus records.** A "standard" is never defined in our project.
It is an ordering on conduct (which lawyers seem to agree about) plus a list of what
has been held to satisfy and what to fail. Its content at any moment is exactly
what those two force--the rest is open and where adjudication happens.

**Everything stays decidable.** The constraint relation, coherence, the settled
region of a standard, conflict detection: all finite conditions over fact sets,
all computable by `decide`. This is why the Lean library has no Mathlib
dependency and builds in twelve seconds, and it is what lets the verifier run
inside a generation loop rather than as a batch job afterwards.

---

## 3. Positioning

As with any project that is academic in aim, we will make clear what is borrowed and what is original.

### Borrowed

**Factor-based precedential constraint.** The model mechanised in
`Reasoning/Precedent.lean` is Horty's, from "Rules and reasons in the theory of
precedent" (*Legal Theory* 17, 2011) and Horty & Bench-Capon, "A factor-based
definition of precedential constraint" (*AI and Law* 20, 2012), refined by
Rigoni (*AI and Law* 23, 2015) and still under active debate — see recent work
on hierarchical constraint and intermediate factors. Behind it stand Ashley's
HYPO and Aleven's CATO. None of this is new here; it is mechanised and pointed
at a corpus it was not designed for.

**Hohfeld.** The eight incidents and their correlativity and opposition tables
are Hohfeld's (*Yale L.J.* 23, 1913 and 26, 1917). They have been formalised
before — Sergot's computational theory of normative positions (*ACM TOCL* 2,
2001), Markovich's *Studia Logica* treatment (2020). What is done here is to
*derive* them from a liability primitive rather than take them as basic.

**Legal DSLs.** Catala (Merigoux et al., ICFP 2021) is the state of the art for
statutory computation, with substantial French and US tax law encoded and a
correctness story Lawsky has written about. Catala and Nomos are aimed at
different things: Catala at statutes that *compute* — where the right output is
a number and the question is whether the implementation matches the statute —
Nomos at law that *adjudicates*, where the question is what a tribunal is bound
to do and there is no number.

**Autoformalisation with a verifier in the loop.** Retrieval of similar
examples, expert iteration, rejection sampling against a proof assistant: this is the
standard cookbook of the field of neural theorem proving. Herald (ICLR 2025), DRIFT (2025),
conceptual retrieval-augmented formalisation (2025), and the benchmark work at
EMNLP 2025 on how poorly statement autoformalisation is usually evaluated.
There is also recent work mapping legal text to defeasible deontic logic with
LLMs (arXiv 2506.08899) and translating tax law to code (NLLP 2025).

---

## 4. Why not deontic logic?

The natural move — "there is mechanised modal and deontic logic available in
every major proof assistant, so build on it" — was considered and not taken.
Why?

Standard deontic logic gives `O(φ)`, `P(φ)`, `F(φ)` over propositions, with an
accessibility relation on ideal worlds. That is a good fit for regulation: "you
must file by April 15" is an obligation whose content is a proposition. But we think it is a
poor fit for the more casuistic nature of the reasoning involved in case law, for three reasons.

**The texts do not necessarily state obligations.** Hammurabi §251 does not say the owner
of a goring ox *ought* to confine it. It says that if he has been warned and
has not confined it and the ox kills a free man, he pays half a mina.
Reconstructing an obligation from that is an interpretive act and a contested
one — it is the Holmesian question of whether a legal duty is anything beyond a
prediction that you will be made to pay. A formalism that opens with `O(·)` has
taken a side in that dispute before reading a word.

**Deontic operators handle conflict badly and defeasibility worse.** Real rules
come stated flatly, with exceptions arriving later as separate rules that beat
them. The literature knows this and has answered with defeasible deontic logics
(Nute's collection, 1997; Governatori and Rotolo since). The machinery is
substantial, and what it buys over plain prioritised rules — which
`Core/Defeasance.lean` implements in about eighty lines, with a determinacy
theorem — is not obvious for this application.

**Almost everything needed is decidable finite combinatorics.** A modal
embedding would interpose a semantics between the data and the check and buy
nothing for it, while costing the property that makes the verifier usable
inside a loop.

Of course, none of this says deontic logic is philosophically the wrong logical framework to use to understand law. Rather,  it is plausible that the obligation-first framing
is a different project, aimed at regulation rather than adjudication (and perhaps the two converge at some point). Anyone
wanting the bridge should start at `Core/Right.lean`'s `Frame`, which already
has states, an accessibility-like transition, and the eight incidents.

---

## 5. What we have done so far, and what's left to do

### Done

- The formalism can express rules from six legal traditions across 2,600 years
  in one vocabulary, and the expressions are machine-checked for
  well-formedness.
- The comparative results in the README are computations over those
  expressions, reproducible by `lake build`.
- The verifier catches reasoning errors that a schema would not, demonstrated
  on two errors it caught in the project's own work.
- Rights are derivable from liability, exactly, in the sense `privilege_is_waiver`
  states.
- Analogical extension transfers a lower bound and not a value.

### To do

- That a **model** can learn the mapping. Hand-formalisation transfers across
  traditions; whether a fine-tuned or prompted system does is untested, and the
  seed corpus is too small to test it properly.
- That the factor vocabulary is **the** right one, or even a good one. It is
  adequate to the seed set, but does this say much? We have a lot of law to test before we see.
- Anything quantitative. The evaluation numbers are on fifteen held-out
  holdings.
- That the approach scales to a tradition's whole body of law rather than one
  fact pattern within it.

---

## 6. Threats to validity

What could go wrong with this approach?

**The factor vocabulary might be the project's rather than the traditions'.**
When the project says Exodus 21:29 and Digest 9.1.1.4 both exhibit *known
vice*, it asserts that "wont to gore in time past" and *bos cornu petere
solitus* pick out the same legally operative feature. But, obviously, this could be wrong — and it gets *more* likely to be wrong the more traditions the
vocabulary spans. A vocabulary that fits everything distinguishes nothing.

Adding Chinese law was the main test of this and it partly answers the question. The Tang
Code shares no ancestry with anything else in the corpus, and the vocabulary
fits it without strain. More importantly, the fit is **not** total: the corpus
is incoherent at exactly one (very interesting!) rule: Babylon and Israel both exempt the keeper of an un-forewarned
animal, while Rome, the Mishnah, China and England do not. A vocabulary loose
enough to fit anything would have reported agreement everywhere.

What remains untested is whether a model can learn the mapping rather than a
person applying it.

**The reason model may not fit code-form law.** It was built for common-law
adjudication, where courts state reasons. Codes state outcomes. The convention
adopted here — take the reason to be all of the winner's facts — is the weakest
reading available and constrains least, but "constrains loosely" and "does not
constrain" are hard to distinguish at this scale.

**Sixty seed holdings is not a corpus.** Every quantitative statement rests on
fifteen held-out holdings. They demonstrate the harness works and nothing else.

**The verifier can be gamed.** Well-formedness and coherence are necessary, not
sufficient. A system that learns to emit minimal ratios — one fact, always
*harm occurred* — passes every check and says nothing. The non-empty-ratio
requirement blocks the degenerate case, not the lazy one. Ratio agreement on
the open stratum is the metric that catches it, which is why it is the one to
quote.

**The sacral/compensatory seam may be everywhere.** The project found one place
where the factor model reports a contradiction that is really a change of
register: Exodus 21:28 is about pollution, not compensation. If ancient law is
shot through with such changes — purity, honour, status, covenant — then the
loss-allocation lens captures a thinner slice of the material than the corpus
size suggests. This is the most worrying objection and the least tested.

**Segmentation quality is uneven.** The Tang Code's 502 articles and the Qing
Code's statute/substatute units are reliable. Large parts of the Chinese corpus
are segmented into paragraph-sized blocks that are not guaranteed to be single
legal units. Every provision records which it got; see `DATA_LICENSES.md`.

---

## 7. Open problems

Ordered by interest.

1. **Does the vocabulary transfer to a model?** Train on Rome and the Mishnah,
   test on the Tang Code. Runnable now but blocked on seed corpus size.

2. **Can the open region be predicted?** `Standard.Unsettled` identifies where
   a standard has no content yet. A system that could read a body of decided
   cases and say where the next dispute will arise would be doing something
   legal scholarship does badly and practitioners would pay for. The Delaware
   efforts-clause line is a natural test bed: the model predicts litigation
   clusters in the open region, and that is checkable against the docket.

3. **Can incoherence be used as a discovery procedure?** The Exodus 21:28/21:35
   result was found by running a decision procedure over a formalisation, not
   by reading. If that generalises — if coherence checking over a large
   formalised corpus reliably locates the seams where a tradition changes
   register — it would be a new tool for textual scholarship, and a better
   advertisement for formal methods in the humanities than another mechanised
   proof.

4. **What is the right treatment of status remedies?** The remedy algebra
   handles loss-allocation well and status badly: enslavement for debt, loss of
   standing, exile, and the surrender of a person rather than an animal all sit
   awkwardly. They are neither quantities nor corporal sanctions.

5. **Is the analogical bound a result about law or about analogy?** The proof
   concerns award functions respecting a case base and contains no legal
   content. If it is really about analogical inference in general, it should
   have applications well outside law.

6. **Does the open region account describe commercial drafting?** The model
   says that naming a standard cannot fix a threshold and that content accrues
   only through decisions. Delaware's refusal to enforce the efforts ladder is
   consistent with that. Whether it *predicts* drafting behaviour (that is, whether
   parties who define conduct rather than adverbs litigate less) is an
   empirical question with available data.

---

## 8. Sources

Primary texts and their provenance are in [`DATA_LICENSES.md`](DATA_LICENSES.md).
Secondary literature, with the caveat that some items were consulted via
abstracts rather than full text:

**Precedent and case-based reasoning**

- J. Horty, "Rules and reasons in the theory of precedent", *Legal Theory* 17 (2011).
- J. Horty & T. Bench-Capon, "A factor-based definition of precedential constraint", *Artificial Intelligence and Law* 20 (2012). [PDF](http://www.umiacs.umd.edu/~horty/articles/2012-ail-tbc.pdf)
- A. Rigoni, "An improved factor based approach to precedential constraint", *AI and Law* 23 (2015).
- "The Role of Intermediate Factors in Explaining Precedential Constraint", CEUR Vol-3614 (2024). [PDF](https://ceur-ws.org/Vol-3614/paper3.pdf)
- "Hierarchical models of precedential constraint", *AI and Law* (2025).
- K. Ashley, *Modeling Legal Argument* (HYPO); V. Aleven, *Teaching Case-Based Argumentation* (CATO).

**Rights and normative positions**

- W. N. Hohfeld, "Some Fundamental Legal Conceptions as Applied in Judicial Reasoning", *Yale L.J.* 23 (1913), 26 (1917).
- M. Sergot, "A computational theory of normative positions", *ACM TOCL* 2 (2001). [PDF](https://www.doc.ic.ac.uk/~mjs/publications/TOCLNormPos.pdf)
- R. Markovich, "Understanding Hohfeld and Formalizing Legal Rights", *Studia Logica* 108 (2020).

**Deontic and defeasible logic**

- D. Nute (ed.), *Defeasible Deontic Logic* (1997).
- G. Governatori & A. Rotolo, "Practical Normative Reasoning with Defeasible Deontic Logic" (2018).
- "From Legal Texts to Defeasible Deontic Logic via LLMs", arXiv 2506.08899 (2025).

**Computational law**

- D. Merigoux et al., "Catala: A Programming Language for the Law", *ICFP* 2021. [arXiv](https://arxiv.org/abs/2103.03198)
- S. Lawsky, "Coding the Code: Catala and Computationally Accessible Tax Law", *SMU Law Review* (2022).

**Autoformalisation**

- "HERALD: A Natural Language Annotated Lean 4 Dataset", *ICLR* 2025.
- "Reliable Evaluation and Benchmarks for Statement Autoformalization", *EMNLP* 2025.

**Commercial and corporate law**

- F. Easterbrook & D. Fischel, "Limited Liability and the Corporation", 52 U. Chi. L. Rev. 89 (1985).
- *Williams Cos. v. Energy Transfer Equity, L.P.* (Del. 2017); *Akorn, Inc. v. Fresenius Kabi AG* (Del. Ch. 2018) — on efforts clauses; see also the Kirkland & Ellis and Harvard Corporate Governance Forum commentary on efforts qualifiers.

**Comparative and ancient legal history**

- D. Ibbetson, "Wrongs and Responsibility in Pre-Roman Law".
- R. Yaron, *The Laws of Eshnunna*, 2nd edn (1988) — the edition against which the tariff figures in `Corpus/Mesopotamia.lean` should be checked.
- M. Roth, *Law Collections from Mesopotamia and Asia Minor* (1997).
- W. Johnson (trans.), *The T'ang Code* (Princeton, 1979–97) — for checking the Tang readings.
