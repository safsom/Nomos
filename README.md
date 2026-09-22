# Nomos

**A formal model of how legal orders allocate loss — and a machine-checked
pipeline that reads new law into it by analogy to law already read.**

Nomos is a Lean 4 library, a 60,595-provision corpus of legal texts, and a
Python pipeline that turns provisions into formal rulings and hands them to a
proof assistant for checking. The proof assistant does not merely check that
the output is well-typed. It checks that the ruling is *legally well-formed* —
that the facts a decision is said to rest on actually favour the party who won
— and that it does not contradict the rulings already formalised around it.
---

## Contents

- [Who this is for](#who-this-is-for)
- [Why liability comes first](#why-liability-comes-first)
- [Three things the formalism does](#three-things-the-formalism-does)
- [Why the corpus is ancient](#why-the-corpus-is-ancient)
- [What is in the corpus](#what-is-in-the-corpus)
- [Findings](#findings)
- [Quickstart](#quickstart)
- [Evaluation](#evaluation-and-why-it-is-stratified)
- [What is wrong with it](#what-is-wrong-with-it)
- [Roadmap](#roadmap)
- [Licences](#licences)

---

## Who this is for

**If you work on formal methods or AI for law**, the interesting parts are
`lean/Nomos/Reasoning/` — a mechanised account of precedential constraint with
soundness results about analogical extension — and `src/nomos/verify.py`, a
verifier that rejects a formalisation for being legally incoherent, not merely
ill-typed.

**If you are a legal scholar**, look at `lean/Nomos/Bench/` and
`lean/Nomos/Corpus/`, where six legal traditions are formalised in one
vocabulary and the comparison is *computed* rather than asserted.
[Findings](#findings) has the results, including one that was not anticipated.

**If you draft or litigate commercial agreements**, look at
`lean/Nomos/Core/Standard.lean`. It is a model of what a term like
"commercially reasonable efforts" could really mean, and it explains why the
drafting convention of naming a stronger-sounding standard does not reliably
buy a stronger obligation.

**If you just want to run it**, jump to [Quickstart](#quickstart). The Lean
library has no dependencies and builds from scratch in about thirteen seconds;
the Python side is standard library only except for the notebooks.

---

## Why liability?

Most formal or computational treatments of law start from rights, duties or obligations and
derive everything else. Nomos does the opposite: it takes **liability** — who
must bear, repair or answer for a loss — as the primitive, and reconstructs
rights as patterns in the liability rules. Three arguments for this choice below, in increasing order of how
much they should matter to you.

### Liabilities plausibly predate rights

Ancient legal codes are very loud about liability! Hammurabi does not say a
field owner has a right that his crop not be eaten; it says that a shepherd who
pastures his flock there without leave pays twenty *gur* of grain for every ten
*gan*. The Book of Exodus does not confer bodily security; it says that if an ox gores, the
ox is destroyed, and where the owner had been warned, he answers too. The Tang
Code of 653 CE opens its treatment of dangerous animals with a penalty, not an
entitlement. A formalism that starts from rights must invent them before it can read any of
this. A formalism that starts from liability reads it directly and *derives*
the rights; it simply needs some implicit concept of "debt" or similar.

### There is a plausible formal derivation of rights from liabilities (though vice versa may be possible too)

In `lean/Nomos/Core/Right.lean` of this project, a *right to φ*
is defined as a conjunction of two liability facts: you are answerable to
nobody for doing φ, and anyone who interferes becomes answerable to you. The
eight incidents imagined by Wesley Newcomb Hohfeld as being foundational to legal reasoning — claim, duty, privilege, no-claim, power, liability,
immunity, disability — fall out of a single exposure relation, and Hohfeld's
correlativity and opposition tables also come out as one-line theorems.

The key result is **`privilege_is_waiver`**: every liberty is the waiver of
some order. Given any arrangement in which you are at liberty to do something,
there is an arrangement differing only at that point in which you were not, and
the first is the waiver of the second. Privilege and consent are two
descriptions of one arrangement.

So nothing is lost (and much is gained, as discussed above) by taking liability as our primitive. `Hammurabi57` in the same
file is an example: from the single exposure that §57
states, it derives the field owner's right to harvest in the full sense
(liberty plus protection) neither half of which the text mentions.

### Modern commercial law arguably works the same way!

This is the argument that should persuade anyone who finds the ancient material
quaint.

Open a complex enough commercial agreement (e.g. between a hedge fund and a corporation) and look at where the negotiation
tends to go. It went into the indemnities, the representations and
warranties made by either party, the limitation-of-liability clause, the caps, the baskets, the
carve-outs from the caps, and the survival periods, and exceptions to the foregoing. A modern M&A agreement or
enterprise software contract is, in its economically operative parts, an
instrument for allocating exposure to loss under specified conditions. The
language of rights in it — "Customer shall have the right to…" — is arguably a
surface convention over that allocation.

Thus, treating liability as primitive is a reasonable
description of how the most economically consequential body of modern private
law is structured, drafted and argued about. The ancient corpus is where the
formalism is *tested*; commercial practice is somewhere it could be *pointed*.

**What this does not claim.** Constitutional and human-rights law is genuinely
rights-first, and much of public law concerns jurisdiction, power and procedure
rather than loss. Nomos (at this moment) has almost nothing useful to say about Magna Carta
cl. 39 — "No free man shall be seized … except by the lawful judgment of his
peers or by the law of the land" — and the theorem
`magna_carta_39_is_not_a_liability_rule` records that as a limitation rather
than hiding it. The claim is that liability is the right primitive for private
law, ancient and modern; not that rights are eliminable everywhere.

---

## Three objectives for the formalism

### 1. It models vague standards without defining them

"Reasonable efforts." "Due diligence." "Such care as a prudent man would take."
*Diligentia quam suis rebus.* Every developed legal order runs on terms of this
kind, and none of these legal orders necessarily defines such terms.

The usual response in formal legal modelling is to treat this as a defect: pick
a threshold, fit a classifier, learn an embedding. But Nomos treats it as a feature
and models it directly. A vague standard is not a predicate awaiting
definition. It is:

1. a **comparative** — "this precaution is at least as careful as that one" —
   which lawyers make confidently, and agree about far more readily than they
   agree about the standard itself; plus
2. a **record** of what conduct has been held to satisfy it and what to fail.

Conduct above something held sufficient is sufficient. Conduct below something
held insufficient is insufficient. Everything else is **open**.

Three theorems follow (`lean/Nomos/Core/Standard.lean`):

| | |
|---|---|
| `not_settled_both_ways` | a coherent record never contradicts itself, and coherence is a finite check on the record alone — you never need to know where the threshold "really" is |
| `decide_open_preserves_coherent` | in the open region, **either** decision is consistent with everything previously decided |
| `settled_monotone` | the settled region only grows |

**Why a commercial lawyer should care.** Drafting convention around efforts
clauses assumes a ladder: *best efforts* > *reasonable best efforts* >
*commercially reasonable efforts* > *reasonable efforts*. Delaware has
substantially declined to enforce that ladder. In *Williams Cos. v. Energy
Transfer Equity* the court treated "commercially reasonable efforts" and
"reasonable best efforts" as imposing the same obligation to take all
reasonable steps to solve problems and close; *Akorn v. Fresenius* carried
forward the view that even "best efforts" is implicitly qualified by
reasonableness. Courts instead decide, case by case, whether the particular
conduct was enough.

On the model here that is exactly what you would predict. Naming a standard
does not fix a threshold, because a threshold is not the kind of thing a name
can fix. What gives the term content is the accumulating record of what conduct
has been held sufficient — and parties keep litigating because most disputes
land in the open region, where by construction neither answer contradicts
anything previously decided. If you want a determinate obligation, the model
says what to do: **define the conduct, not the adverb.**

### 2. It knows what analogy can and cannot transfer

If a rule gives remedy *r* in a lighter case, what does it give in a heavier
one? The natural answer — *more* — is unsound, and `no_strengthening` in
`lean/Nomos/Reasoning/Analogy.lean` proves it:

> **Analogical extension transfers a lower bound, never a value.**

The precedent entails *at least* *r* in the heavier case and nothing further,
because the award function giving exactly *r* everywhere is consistent with the
precedent. Any pipeline that formalises a rule by analogy and emits a specific
quantum has overclaimed.

This is not a new observation; it is the rabbinic *dayyo* principle — "it is
enough that the inferred law be as strict as that from which it is inferred" —
recorded in Mishnah Bava Kamma 2:5 as the Sages' answer to R. Tarfon's a
fortiori argument. It now has a two-line proof.

Independently, Qing Code art. 44 (斷罪無正條, "deciding a case where there is no
exact provision") legislates about the same gap: where no provision fits, cite
the nearest statute *by analogy* (比附), determine 應加應減 — "the appropriate
increase or decrease" — and **report it upward for memorial to the throne**,
with the deciding official personally liable if the penalty comes out too heavy
or too light. Two legal cultures with no contact, both noticing that analogy
leaves the quantum open, and answering it — one with a logical restriction, one
with mandatory review.

### 3. It verifies formalisations for legal coherence, not just types

This is our main engineering contribution. Three checks run on every candidate:

| check | catches |
|---|---|
| **compiles** | the facts exist, the remedy is a remedy, the outcome is an outcome |
| **well-formed** | every fact the ruling is said to rest on is present in the case **and favours the party who won** |
| **coheres** | adding it does not make that tradition's case base force both outcomes on some situation it already addresses |

The middle check is a reasoning check wearing a type-checker's clothes. A model
that reads "the animal was innocuous, so he pays only half" and records *the
animal was innocuous* as a reason the **claimant** won produces syntactically
perfect Lean that fails to compile, because innocuousness is a defence. This
caught a real error in the project's own hand-formalisation of Mishnah Bava
Kamma 1:1, and a second in Magna Carta cl. 20 where an early draft had the
parties the wrong way round. Both are documented in `docs/LEAN_TOUR.md`.

The third check is what a schema can never do. A reading of a provision that
contradicts the twenty provisions formalised around it has almost certainly
misread it, and no amount of checking that provision in isolation would reveal
it.

---

## Why the corpus is ancient

The subject of this project is casuistic legal reasoning. Ancient law is the
**test set**, chosen for three reasons.

**It is out of copyright.** A corpus that can be redistributed is a corpus
other people can check. Modern case law and statutes are mostly paywalled,
licence-encumbered, or both.

**It is maximally diverse.** The strongest available test of whether a factor
vocabulary describes *law* rather than *a legal culture* is to point it at
legal orders with no shared ancestry. Tang China had no contact with Rome,
Babylon or Israel, and wrote in a different script with a different
philosophical vocabulary. If the same factors describe its rules, that is
evidence. If they do not, the approach is in trouble — and one would want to
find that out early and cheaply.

**It is hard in the right way.** Ancient codes state outcomes without reasons,
which is the difficult case for any model of precedent. If the machinery works
on Hammurabi it will work on a body of reported decisions.

The scenario used throughout as the alignment axis is deliberately mundane: an
animal in someone's charge gets loose and does damage. Nothing about it is
culturally particular; every agrarian society had to settle it. So when six
legal orders settle it differently, the difference is about law rather than
about anything else.

---

## What is in the corpus

**60,595 provisions, 21.4M characters, five languages.**

| tradition | works | provisions | licence |
|---|---|---:|---|
| **Roman & canon** | Digest, Codex Iustinianus, Codex Theodosianus, Gaius' *Institutes*, Justinian's *Institutes*, Twelve Tables, Decretals of Gregory IX | 30,332 | Public Domain Mark 1.0 |
| **Chinese** | 唐律疏議 (Tang Code, 653), 大清律例 (Qing Code), 大明律 (Ming Code), 名公書判清明集 (Song judgments), 刑案匯覽三編 (Qing case reports), 通典, 折獄龜鑑 / 棠陰比事 / 疑獄集 (case collections), 韓非子 / 商君書 / 管子 (Legalists), 洗冤集錄 | 16,849 | unspecified — works public domain by age |
| **Rabbinic & biblical** | Talmud Bavli (Bava Kamma / Metzia / Batra), Mishnah Seder Nezikin, Exodus | 13,351 | CC-BY-NC / CC-BY / Public Domain |
| **English** | Magna Carta (1215) | 63 | Public Domain Mark 1.0 |

Every provision carries its citation, source and licence. Texts come from
GitHub mirrors of the Latin Library (via CLTK), Daizhige, and the Sefaria
export; [`DATA_LICENSES.md`](DATA_LICENSES.md) gives exact provenance,
redistribution terms and known data-quality problems.

The largest single works: the **Digest** at 20,770 fragments — essentially the
scholarly count, a useful sign the segmentation is right — 通典 at 9,097
blocks, the **Codex** at 5,270, the **Codex Theodosianus** at 2,916, and the
**Great Qing Code** at 2,331 units, being 430 statutes (律) with 1,901
substatutes (例), the numbering preserving which 例 hangs off which 律.

On top of the raw text sit **60 hand-made formalisations** across six
traditions, each machine-checked, and **9 cross-cultural fact patterns** that
align them.

**Some texts are cited but not shipped on the repository.** Hammurabi, Eshnunna, the Hittite
laws, Gortyn, the Anglo-Saxon codes, Glanvill, Bracton, the nineteenth-century
English cases and the Animals Act 1971 appear as **citations plus clearly
labelled editorial restatements**, with `text: null`. These are paraphrases of
what the provisions do, written by the project — not renderings of what they
say — and they are marked as such everywhere they appear.
`python -m nomos.fetch.restricted` retrieves the real texts. These texts were excluded for primarily licensing and 
access reasons.

---

## Findings

All of these are `by decide` over the formalised holdings. No human argumentation (other than that involved in writing these legal texts) was involved. 

### Convergence is about facts rather than outcomes

Seven holdings across six traditions and 2,600 years (Eshnunna, Babylon,
Exodus, the Mishnah, Rome, Tang China, England) all decide the
forewarned animal case in favor of the claimant, and all rest it on the same fact: that
the keeper knew the animal was dangerous.

> *bos cornu petere solitus* (Digest 9.1.1.4) · "wont to gore in time past"
> (Exodus 21:29) · *mu'ad* (Mishnah) · 噬犬 (Tang Code art. 207) ·
> "characteristics … known to that keeper" (Animals Act 1971 s.2(2))

The Tang commentary specifies the precaution owed by quoting the Miscellaneous
Ordinances: *cut off both horns; hobble its feet*. Hammurabi §251 imposes
liability where the owner "did not blunt its horns or tie up his ox".

### Divergence is sometimes incommensurable

The Book of Exodus makes the forewarned keeper capitally liable; Hammurabi charges thirty
shekels; Tang China gives forty blows of the light stick, redeemable.
`Remedy.capital_incomparable_tariff` proves two of these are *not ordered at
all* — not because an exchange rate is missing, but because one of the two
systems denies there is one (Numbers 35:31 forbids ransom for a life).

### A smaller result

When two animals kill each other and neither keeper is at fault, four legal
orders split the loss: Eshnunna §53, Exodus 21:35, the Mishnah's *ḥatzi nezek*,
and Tang Code art. 206 — 償減價之半, "compensates half the depreciation", with
the commentary working the arithmetic on a horse worth ten bolts of silk.
Three of those are plausibly one tradition. The fourth is not.

---

# AI use
This repository was initially drafted in collaboration with a large language model (Claude, specifically the $20/month version), and independently and substantially revised by the author without use of a large language model. All Lean proofs are machine-checked (no sorry, no axiom), so the theorems do not depend on that provenance. The interpretive claims (factor assignments, ratios, cross-tradition groupings), carry citations so they can be checked, but have had no other specialist review. Source texts in data/raw/ are not model-generated.

---

## Quickstart

```bash
# 1. Lean. No Mathlib, no cache; a clean build takes about thirteen seconds.
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
cd lean && lake build && lake exe export-corpus | head -3 && cd ..

# 2. Build the corpus (~7 seconds). It is a derived artefact and is not
#    committed; data/raw/ and the builder both are.
make corpus

# 3. Everything else
make seed          # re-export the 60 formalisations from Lean
make test          # 35 tests, including Python/Lean agreement
jupyter lab notebooks/
```

`PYTHONPATH=src` if you are not installing the package. The notebooks build the
corpus themselves if it is missing.

Two flags worth knowing:

```bash
python -m nomos.build_corpus --no-nc      # drop non-commercially licensed texts
python -m nomos.fetch.restricted --list   # texts cited but not shipped, and where to get them
```

**Layout**

```
lean/          4,464 lines, 128 theorems, 18 modules. No sorry, no axioms, no
               Mathlib -- everything is decidable finite combinatorics over
               fact sets, which is what keeps the verifier fast enough to sit
               inside a generation loop.
data/raw/      staged source texts, with their licences
data/seed/     the 60 hand-made formalisations, exported from Lean
src/nomos/     corpus builders, the constraint engine, retrieval, the Lean
               verifier, the pipeline, baselines, evaluation
notebooks/     1 corpus · 2 autoformalisation · 3 fine-tuning
tests/         35 tests
docs/          LEAN_TOUR.md -- a guided reading of the Lean library
```

[`RESEARCH.md`](RESEARCH.md) has the longer argument, the related work, and a
fuller account of what could sink the approach.

---

## Evaluation

Compile rate is nearly worthless as a metric here. The most reliable way to
produce a compiling, well-formed, coherent holding is to copy the nearest
binding precedent — which scores perfectly and reads nothing.

So results are reported in two strata: **forced** (the existing case base
already determined the outcome before the system saw the provision) and **open**
(it did not). On a fifteen-holding held-out split:

| system | open | forced | ratio agreement (open) | gap |
|---|---:|---:|---:|---:|
| majority class | 0.20 | 0.90 | 0.00 | +0.70 |
| nearest precedent | 0.40 | 1.00 | 0.10 | +0.60 |
| lexical nearest-neighbour | 1.00 | 0.50 | 0.10 | −0.50 |

`nearest_precedent` is perfect on the forced stratum and mediocre on the open
one. Any evaluation that pooled them would have called it a strong system.
**Quote the open column.**

The metric that matters most is *ratio agreement* — whether the system agrees
about **which facts mattered**, not just who won. Outcome agreement is easy:
most provisions find for the claimant. Agreeing on the reasons is what
precedent actually transmits.

*These numbers are on n ≈ 15. They show the harness works and that the
stratification bites. They establish nothing about any system.*

---

## Licences

**Code is MIT** (`LICENSE`). **Data is not uniformly licensed** — read
[`DATA_LICENSES.md`](DATA_LICENSES.md) before redistributing anything derived
from `data/`. In particular one substantial text is CC-BY-NC, so anything
derived from it inherits a non-commercial restriction;
`python -m nomos.build_corpus --no-nc` produces a corpus without it.
Editorial restatements of this text are provided in this repository for approximation purposes
but they can be retrieved following instructions in [`RESEARCH.md`](RESEARCH.md).
