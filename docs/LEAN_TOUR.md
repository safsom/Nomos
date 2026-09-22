# A tour of the Lean library

4,446 lines, 128 theorems, no `sorry`, no `axiom`, no Mathlib. A clean
`lake build` -- toolchain already installed, `.lake` deleted -- takes about
**11 seconds**. That is the practical argument for staying off Mathlib: the
verifier runs inside a generation loop, and a two-minute build there would
make the loop unusable.

Read in this order.

---

## `Core/Party.lean` — the ontology, kept thin

`Party`, `Res`, `Act`, `Measure`, `Quantity`. Everything is an opaque name plus
a kind. The corpus spans societies that disagree about who counts as a person
and what can be owned; building any of that in would prejudge the comparative
questions.

One thing to notice: `Quantity.le` requires the units to match. Gur of barley
and shekels of silver are simply not ordered. That is deliberate and load-bearing
— see the incomparability theorems below.

*(`Measure` is the unit-of-account type. It is not called `Unit` because that
would shadow `_root_.Unit` and make every `IO Unit` in a client file
ambiguous — which it did, once.)*

## `Core/Remedy.lean` — what a legal order does about a wrong

An inductive with eleven constructors, three of which are there for reasons the
corpus forced:

* `orElse` — the bearer elects. Roman noxal liability (*aut noxae dedere aut
  aestimationem offerre*, D.9.1.1pr) and Exodus 21:29–30's ransom clause have
  the same shape and neither is expressible without a disjunction.
* `inKind` — restitution of a specified quality. Ex 22:4's *meitav*, "of the
  best of his field", is doing legal work that `compensate` would lose.
* `both` — cumulative.

`AtLeast` is "at least as heavy as", the reflexive-transitive closure of a
`Step` relation whose every clause is a substantive judgement worth reading.

The interesting part is `Incomparable`. Proving that one remedy *is* heavier
than another is easy — exhibit the chain. Proving it is *not* needs an
invariant preserved by every step, and two suffice for the whole corpus:
`someBranchBloodless` (can the bearer discharge this without blood?) and
`fromCorporal` (is this reachable from a purely corporal starting point?). With
those, `capital_incomparable_tariff` falls out: **death and thirty shekels are
not different amounts on one scale.**

## `Core/Factor.lean` — the vocabulary

25 one-sided factors, 14 for the claimant and 11 for the respondent, each with
the citations it was read off. `Situation` is a list of them.

Factors are one-sided *by definition*: a fact that cuts both ways is two
factors, not one with a sign. This is the HYPO/CATO convention and Horty's, and
it is what makes the a fortiori relation well-defined.

## `Core/Liability.lean` — the kernel

`Incidence` (who is answerable to whom, in what, on what authority) and
`Holding` (what a tribunal decided, including the `reason` it relied on).

Two things to look at:

* `exempt_allocates_to_claimant` — exemption is not the absence of an
  allocation, it is an allocation to the victim. Everything downstream depends
  on treating `Remedy.exempt` as a remedy.
* `WellFormed` — a holding must rest on something, and what it rests on must be
  present in the case and favour the winner. This is the definition the
  verifier turns into a compile error, and the one that caught a real mistake
  in our own reading of m.Bava Kamma 1:1.

## `Reasoning/Precedent.lean` — the reason model

Horty & Bench-Capon (2012), mechanised. `AtLeastAsStrong s h` says the new
situation is at least as strong for `h`'s winner as `h`'s own was: the ratio is
present, and no counter-reason appears that the precedent did not already face.

Theorems worth knowing:

| | |
|---|---|
| `Forces.mono_corpus` | law accumulates: adding cases never withdraws a constraint |
| `Forces.mono_situation` | more support for the winner never weakens the binding |
| `decision_against_precedent_incoherent` | **precedent binds** |
| `open_decision_settles_one_way` | **the gap is free**: in a genuinely open case, no decision contradicts the record |
| `distinguishable_iff` | escaping a precedent means either its ratio is absent or the case raises something new — there is no third way |

`CoherentOn` restricts coherence to a finite list of situations, which makes it
decidable. `conflictsAt` localises a failure to the two rulings pulling against
each other.

## `Reasoning/Analogy.lean` — and its limits

* `kal_vachomer` — a fortiori transfer.
* `dayyo` — the bound it delivers is *tight*: the constant award realises it.
* `no_strengthening` — **nothing above the bound is entailed.** This is the
  Sages against R. Tarfon, and the reason a pipeline that emits a quantum where
  the precedent fixes only a bound has produced an unsound formalisation.
* `CommonDenominator` — the structure of m.Bava Kamma 1:1's argument: shared
  features, plus the requirement that *each paradigm contributes something the
  shared set lacks*.
* `common_denominator_underdetermines` — **the Mishnah's generalisation does not
  follow from its paradigms.** The proof is one line once `irredundant` is in
  hand, which is exactly the point: the Mishnah's own care in distinguishing the
  four categories is what blocks the deduction. The closing rule is legislation,
  not inference. That is not a criticism; it is a description, and here it is a
  theorem.

## `Core/Standard.lean` — "reasonable efforts"

A `Standard` is a comparative plus two lists: conduct held sufficient, conduct
held insufficient. It is never defined.

* `not_settled_both_ways` — a coherent record never contradicts itself, and
  coherence is a finite check on the record alone.
* `decide_open_preserves_coherent` — in the open region, **either decision is
  consistent with everything already decided.**
* `settled_monotone` — the settled region only grows.

The worked example is m.Bava Kamma 6:1's penning standard, with
`ordinary_open` proving that the grade the Mishnah leaves unaddressed really is
unaddressed — which is the question b.Bava Kamma 55b–56a then argues about.

## `Core/Right.lean` — rights, derived

A `Frame` (states, an exposure relation, an interference relation, an effect of
acts on states), the eight Hohfeldian incidents defined from it, and the
correlativity and opposition tables as theorems. Most are `Iff.rfl`, which is
not a sign the formalisation is trivial — it is Hohfeld's actual thesis that the
eight terms name two relations seen from either end plus their negations.

Then the payoff: `privilege_is_waiver`. Every liberty is the waiver of some
order, so rights are the shape liability rules take and nothing further has to
be posited to recover them.

`Hammurabi57` does it concretely: from the single exposure LH §57 states, derive
the field-owner's right to harvest in the full sense — liberty plus protection —
neither half of which the text mentions.

## `Core/Defeasance.lean` — rules and exceptions

Prioritised rules; a rule is defeated when a higher-priority applicable rule is
*incompatible* with it. Incompatibility covers opposite outcomes **and** the
same outcome with a different remedy, because some of the most important
defeaters in the corpus leave the winner untouched and change only what is owed
(D.9.1.1.4: the claimant still wins, but the owner loses the option of
abandoning the animal).

`determinate` proves that where conflicts are broken by priority, the theory
fixes both the winner and the remedy. The worked example is m.BK 6:1's four-rule
cascade, including the clause where liability *relocates* to the bandits.

## `Corpus/` — the formalised sources

`Covenant.lean` (Exodus 21–22), `Rabbinic.lean` (Mishnah Bava Kamma and Metzia),
`Roman.lean` (XII Tables, *lex Aquilia*, Digest), `Mesopotamia.lean` (Hammurabi
and Eshnunna), `Sinica.lean` (the Tang Code) and `Anglia.lean` (Æthelberht to
the Animals Act 1971).

**`Sinica.lean` is the one to read if you read only one.** Tang Code art. 207
requires the keeper of a dangerous animal to mark and tether it — the
commentary specifies cutting the horns and hobbling the feet, which is
Hammurabi §251's "blunt its horns or tie it up" — and art. 206 gives *half* the
depreciation when beasts kill each other, which is Exodus 21:35 and Eshnunna
§53 and the Mishnah's *ḥatzi nezek*. None of this can have been borrowed. The
module's header also sets out Qing Code art. 44, 斷罪無正條, which is a
statutory rule governing reasoning by analogy and the closest thing in any
legal system to a legislative answer to `no_strengthening`.

`Anglia.lean` carries the one documented transmission in the corpus: Alfred's
law-book opens with Exodus 20–23 in Old English, goring ox included, and
`alfred_copies_exodus` shows the formalisations coincide exactly — which is
what borrowing looks like, as against the convergence signature elsewhere.
Mesopotamian and most English holdings are citations plus editorial
restatements; see `DATA_LICENSES.md`.

Each ends with `theorem corpus_sound : corpus.Sound := by decide`, so no
malformed reading can enter the corpus unnoticed.

## `Bench/` — the comparisons

`GoringOx.lean`: one fact pattern, six traditions, 2,600 years, twenty
theorems. `Grazing.lean`: the scenario this project started from — a shepherd's
animals in a neighbour's crop — across Hammurabi, Exodus, the Mishnah and the
Tang Code, including the observation that only the Tang Code regulates
self-help, and it does so by *pricing* it.

In `GoringOx.lean` the headline is
`incoherence_is_the_no_notice_no_liability_rule`: fifteen pairwise merges, five
with no conflicts at all, and every conflict in the rest tracing to Ex 21:28 or
LH §250 — which are the same rule. The
three that matter are in the README. The one to read the proof of is
`covenant_incoherent_on_own_situations`, which is `by decide` and therefore not
an argument at all — it is a computation, and the interesting work is in the
doc-comment explaining why the contradiction it reports is a finding about
Exodus rather than a bug in the model.

## `Export.lean`

`lake exe export-corpus` emits the seed corpus as JSONL, and `--factors` emits
the vocabulary. `remedySource` round-trips a remedy back to valid Lean, which is
what lets the Python pipeline splice generated remedies into candidate
declarations and hand them to the compiler.

The Lean library is the source of truth for the seed data; Python reads what
Lean printed, so the two cannot drift.
