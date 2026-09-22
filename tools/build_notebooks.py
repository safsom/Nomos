#!/usr/bin/env python3
"""Generate the notebooks.

Kept as a script so the notebooks are reproducible artefacts rather than
hand-edited JSON that drifts from the library.
"""

from __future__ import annotations

import os

import nbformat as nbf
from nbformat.v4 import new_code_cell, new_markdown_cell, new_notebook

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "notebooks")

PREAMBLE = """\
import os, sys, json, subprocess
from pathlib import Path

# Locate the repository root whether this runs from notebooks/ or the root.
ROOT = Path.cwd()
while not (ROOT / "src" / "nomos").exists() and ROOT != ROOT.parent:
    ROOT = ROOT.parent
sys.path.insert(0, str(ROOT / "src"))
os.chdir(ROOT)
print("repo root:", ROOT)

# The built corpus is a reproducible artefact and is not shipped in the
# archive (it is 13 MB gzipped and rebuilds from data/raw in about a minute).
if not any((ROOT / "data/corpus").glob("provisions.jsonl*")):
    print("building the corpus from data/raw ...")
    subprocess.run([sys.executable, "-m", "nomos.build_corpus"], check=True,
                   env={**os.environ, "PYTHONPATH": str(ROOT / "src")})
"""


# ---------------------------------------------------------------------------
# 01: the corpus
# ---------------------------------------------------------------------------

def notebook_corpus() -> nbf.NotebookNode:
    cells = [
        new_markdown_cell("""\
# 1 · The corpus

What is in `data/`, where it came from, and what the formalised seed looks like.

Four bodies of text ship with this repository:

| tradition | provisions | language | licence |
|---|---:|---|---|
| Roman & canon — Digest, Codex, Theodosian Code, Gaius, Institutes, XII Tables, Decretals | ~30,300 | Latin | Public Domain Mark 1.0 |
| Chinese — Tang / Ming / Qing codes, Song and Qing case reports, Legalists | ~16,800 | Classical Chinese | unspecified (works PD by age) |
| Rabbinic & biblical — Mishnah, Talmud, Exodus | ~13,400 | English | CC0 / CC-BY / CC-BY-NC / PD |
| English — Magna Carta | 63 | Latin | Public Domain Mark 1.0 |

All were fetched from GitHub mirrors (`cltk/lat_text_latin_library`,
`garychowcmu/daizhigev20`, `Sefaria/Sefaria-Export-Archive`).  A fifth group —
Hammurabi, Eshnunna, the Hittite laws, Gortyn, the Anglo-Saxon codes, Bracton,
the scienter cases and the Animals Act 1971 — is carried as citations and
editorial restatements only, because the sandbox this was built in could not
reach those sources. `python -m nomos.fetch.restricted --list` shows them and
will fetch them anywhere with ordinary network access.

**A word on the non-commercial texts.** The William Davidson Talmud is
CC-BY-NC. If you need a corpus you can use commercially, rebuild with
`python -m nomos.build_corpus --no-nc`; you lose the Talmud and keep everything
else."""),
        new_code_cell(PREAMBLE),
        new_code_cell("""\
from nomos.schema import read_jsonl
from collections import Counter

provisions = list(read_jsonl("data/corpus/provisions.jsonl"))
print(f"{len(provisions):,} provisions, {sum(len(p['text'] or '') for p in provisions)/1e6:.1f}M characters")

by_work = Counter(p["work"] for p in provisions)
for work, n in by_work.most_common():
    lic = next(p["source"]["license"] for p in provisions if p["work"] == work)
    print(f"  {n:6,}  {work:28s} [{lic}]")"""),
        new_markdown_cell("""\
### The Digest

Book 9 title 1 — *si quadrupes pauperiem fecisse dicatur*, "if a four-footed
beast is said to have done damage" — is the Roman goring-ox title. It opens by
deriving the action from the Twelve Tables and stating the noxal election, and
then, four fragments later, gives the condition that Exodus and the Mishnah
also single out: *bos cornu petere solitus*, an ox accustomed to gore."""),
        new_code_cell("""\
idx = {p["canonical"]: p for p in provisions}
for c in ["D.9.1.1pr", "D.9.1.1.4", "D.9.2.44pr", "D.50.17.203"]:
    p = idx[c]
    print(f"[{p['citation']}]  {p['attribution']}")
    print("   ", p["text"][:400])
    print()"""),
        new_markdown_cell("""\
### The Tang Code

653 CE, 502 articles, and the control case for the whole comparative argument:
a legal order with no contact with Rome, Babylon or Israel.

Article 207 makes the keeper of a dangerous animal mark and tether it, and the
official commentary quotes the Miscellaneous Ordinances on what that means —
*cut off both horns, hobble the feet, cut off both ears*. Hammurabi §251 holds
the owner liable where "he did not blunt its horns or tie up his ox."

Article 206 gives **half** the depreciation when beasts kill each other —
Exodus 21:35, Eshnunna §53 and the Mishnah's *ḥatzi nezek*, reached
independently.

And Qing Code art. 44 is a statutory rule governing reasoning by analogy."""),
        new_code_cell("""\
for c in ["TL.207", "TL.206", "TL.204"]:
    r = idx[c]
    print(f"[{r['citation']}]")
    print("  律:", r["text"])
    if r["meta"].get("commentary"):
        print("  疏:", r["meta"]["commentary"][:220])
    print()

q = idx["DQ.44.00"]
print(f"[{q['citation']}]  斷罪無正條 — deciding a case with no exact provision")
print("  ", q["text"][:300])"""),
        new_markdown_cell("""\
> 凡律令該載不盡事理，若斷罪無正條者，引律**比附**，應加應減，定擬罪名，申該上司
> 議定奏聞。若輒斷決，致罪有出入者，以故失論。

"Where the statutes do not exhaustively cover the matter, and there is no exact
provision, cite a statute **by analogy**, determine the appropriate increase or
decrease, settle the designation of the offence, and report it upward for
memorial to the throne. If an official decides it outright and the penalty
comes out too heavy or too light, he is punished as for misjudgment."

That is the gap `Reasoning/Analogy.lean` formalises as `no_strengthening` —
analogy fixes a bound, not a value — recognised and legislated about. 應加應減,
"the appropriate increase or decrease", *is* the gap. The Sages answered it
with *dayyo*; the Qing answered it with mandatory review and personal liability
on the judge."""),
        new_markdown_cell("""\
### Mishnah Bava Kamma 1:1

This is the passage that made the project seem tractable. Read it as an
argument rather than a list: four paradigm cases, then each distinguished from
the others, then the common feature extracted in order to license extension to
cases not named. That is factor-based precedential constraint, described from
the inside, around 200 CE."""),
        new_code_cell("""\
print(idx["Mishnah Bava Kamma 1:1"]["text"])
print()
print("--- and the dayyo dispute, m.BK 2:5 ---")
print(idx["Mishnah Bava Kamma 2:5"]["text"][:1200])"""),
        new_markdown_cell("""\
## The seed formalisations

43 holdings across four traditions, hand-made and machine-checked. The Lean
library is the source of truth; `python -m nomos.build_seed` exports it."""),
        new_code_cell("""\
seed_rows = list(read_jsonl("data/seed/formalizations.jsonl"))
print(f"{len(seed_rows)} seed holdings")
print("by tradition:  ", dict(Counter(r["tradition"] for r in seed_rows)))
print("by fact pattern:", dict(Counter(r["fact_pattern"] for r in seed_rows)))
print("all well-formed:", all(r["well_formed"] for r in seed_rows))
print()
r = next(r for r in seed_rows if r["cite"] == "Ex 21:29")
print("text: ", r["text"])
print("situation:", r["situation"])
print("winner:   ", r["winner"])
print("remedy:   ", r["remedy"])
print("ratio:    ", r["reason"])
print()
print(r["lean"])"""),
        new_markdown_cell("""\
## Fact patterns

The alignment axis. A fact pattern is a question many orders had to answer; the
scenario is stable across cultures and the answer is not, and the gap between
those two is what we are trying to measure."""),
        new_code_cell("""\
patterns = json.load(open("data/corpus/fact_patterns.json"))
for p in patterns:
    wits = ", ".join(f"{w['tradition']}: {w['cite']}" for w in p["witnesses"])
    print(f"{p['id']:22s} {p['name']}")
    print(f"{'':22s} {p['issue']}")
    print(f"{'':22s} {wits}")
    print()"""),
        new_markdown_cell("""\
## Coherence diagnostics

The same constraint relation the Lean library proves theorems about, computed
in Python over the seed corpus. Two things are worth looking at: whether each
tradition contradicts itself on the facts it addressed, and what happens when
you try to merge two traditions into one body of precedent.

The Covenant Code result below is the one we did not expect."""),
        new_code_cell("""\
from nomos.analogy import Holding, conflicts_at, incoherence_report, is_open

def load(rows, trad=None):
    return [Holding(cite=r["cite"], situation=r["situation"], winner=r["winner"],
                    remedy=r["remedy"], reason=r["reason"], tradition=r["tradition"])
            for r in rows if trad is None or r["tradition"] == trad]

seed = load(seed_rows)
for trad in ["covenant", "rabbinic", "roman", "mesopotamian", "chinese", "english"]:
    c = load(seed_rows, trad)
    rep = incoherence_report(c)
    print(f"{trad:14s} {len(c):3d} holdings   self-conflicts: {len(rep)}")
    for r in rep[:2]:
        for cf in r["conflicts"]:
            print(f"                 {cf['claimant']}  (claimant)  vs  {cf['respondent']}  (respondent)")"""),
        new_markdown_cell("""\
The Covenant Code conflict is between **Exodus 21:35** (an ox kills another
man's ox: the loss is divided, so the claimant recovers something) and
**Exodus 21:28** (an ox kills a *man*: "the owner of the ox shall be quit", so
the claimant recovers nothing).

The second situation has every claimant-side factor the first has, plus
`harmToPerson`, and yields less. On the reason model that is a contradiction.

We think it is a finding rather than a bug, and what it localises is the
interesting part. Ex 21:28 is not operating on a compensation logic at all: the
ox is stoned and its flesh may not be eaten, which is how a thing that has shed
human blood is treated (compare Gen 9:5), and the owner being *naqi* is
acquittal of bloodguilt rather than denial of a debt. A factor vocabulary built
for loss-allocation cannot see a sacral category, so it reports the seam as a
contradiction — localised to two verses, reproducibly, in a way a prose
comparison would glide over.

Now the cross-tradition merge."""),
        new_code_cell("""\
cov, rom, rab = load(seed_rows, "covenant"), load(seed_rows, "roman"), load(seed_rows, "rabbinic")

by_trad = {}
for h in seed:
    by_trad.setdefault(h.tradition, []).append(h)
names = sorted(by_trad)
respondents = set()
print(f"{'pair':30s} conflicts")
for i, a in enumerate(names):
    for b in names[i + 1:]:
        merged = by_trad[a] + by_trad[b]
        cross = set()
        for h in merged:
            for p, c in conflicts_at(merged, h.situation):
                if (p in by_trad[a]) != (c in by_trad[a]):
                    cross.add((p.cite, c.cite)); respondents.add(c.cite)
        mark = "" if not cross else "   <- " + "; ".join(sorted({c for _, c in cross}))
        print(f"  {a[:13]:13s}+{b[:13]:13s} {len(cross):3d}{mark}")
print()
print("respondent-side holdings in EVERY cross-tradition conflict:")
for r in sorted(respondents):
    print("   ", r)"""),
        new_markdown_cell("""\
**This is the result we did not expect.**

Five of the fifteen pairs have no conflicts at all — China with Rome, China
with the Mishnah, China with England, England with Rome, England with the
Mishnah. And every conflict in the remaining ten has one of exactly two
holdings on the respondent's side:

* **Ex 21:28** — an ox gores a man, nothing known against it: *the owner shall
  be quit*.
* **LH §250** — an ox gores a man in the street: *this case has no penalty*.

Those are the same rule. Babylon and Israel exempt the keeper of an
un-forewarned animal; Rome, the Mishnah, Tang China and England all make him
answer something. The fault line in the entire corpus runs between *custody
alone grounds liability* and *custody plus notice does*, and it falls exactly
where two geographically adjacent traditions part company from four others.

A vocabulary loose enough to fit anything would have reported no fault line at
all. Proved as `incoherence_is_the_no_notice_no_liability_rule` in
`Nomos/Bench/GoringOx.lean`."""),
        new_markdown_cell("""\
## Retrieval

How the pipeline chooses which precedents to show a model. Not by similarity —
by *constraint distance*. Binding precedents first, then near misses at
distance one, with the fact that blocks each one named."""),
        new_code_cell("""\
from nomos.analogy import retrieve

query = ["harmOccurred", "respondentsInstrument", "harmToPerson",
         "knownVice", "warned", "properPrecaution"]
print("query situation:", query)
print("open under the seed corpus?", is_open(seed, query))
print()
for r in retrieve(seed, query, k=6):
    print(f"[{r.kind:12s}] {r.holding.cite}  ({r.holding.tradition})")
    print(f"               {r.why}")
    print()"""),
    ]
    nb = new_notebook(cells=cells)
    nb.metadata = {"kernelspec": {"display_name": "Python 3", "language": "python",
                                  "name": "python3"},
                   "language_info": {"name": "python", "version": "3.11"}}
    return nb


# ---------------------------------------------------------------------------
# 02: autoformalisation
# ---------------------------------------------------------------------------

def notebook_autoformalize() -> nbf.NotebookNode:
    cells = [
        new_markdown_cell("""\
# 2 · Autoformalisation by precedent

The loop:

```
provision text
    ├─ triage      does this allocate a loss?  which factors?
    ├─ retrieve    binding precedents and near misses, by constraint distance
    ├─ formalise   candidate Holding as JSON
    ├─ verify      Lean: compiles?  well-formed?  coherent with the corpus?
    └─ repair      hand the model its own errors, up to N times
```

The verification step is what makes this different from schema-constrained
generation. Three checks run, and only the first is what autoformalisation work
usually means by "verified":

1. **It compiles.** The factors exist, the remedy is a remedy.
2. **It is well-formed as a holding.** Every factor relied on must be present
   *and favour the party who won*. This catches reasoning errors, not syntax
   errors — a model that reads "the animal was innocuous, so he pays only half"
   and records `behavedAnomalously` as a reason for the *claimant* fails here.
   (It caught exactly that mistake in our own hand-formalisation of m.BK 1:1.)
3. **It coheres with the tradition.** Adding it must not make the tradition's
   case base force both outcomes on some situation it already addresses.

Requires the Lean toolchain. `elan`, then `lake build` in `lean/` -- about
seven seconds, because there is no Mathlib dependency."""),
        new_code_cell(PREAMBLE),
        new_code_cell("""\
from nomos.verify import lean_available, build_library, export_seed
print("lean available:", lean_available())
if lean_available():
    ok, log = build_library()
    print("library builds:", ok)
    if not ok:
        print(log[-2000:])"""),
        new_code_cell("""\
from nomos.schema import read_jsonl
from nomos.analogy import Holding

seed_rows = list(read_jsonl("data/seed/formalizations.jsonl"))
seed = [Holding(cite=r["cite"], situation=r["situation"], winner=r["winner"],
                remedy=r["remedy"], reason=r["reason"], tradition=r["tradition"],
                restatement=(r.get("text") or "")[:300])
        for r in seed_rows]
texts = {r["cite"]: (r.get("text") or "") for r in seed_rows}
print(len(seed), "seed holdings")"""),
        new_markdown_cell("""\
## The verifier, on three candidates

A good one, a reasoning error, and a syntax error."""),
        new_code_cell("""\
from nomos.verify import verify

good = Holding(
    cite="TEST: forewarned beast, properly confined, escapes in a storm",
    situation=["harmOccurred","respondentsInstrument","harmToPerson","knownVice",
               "warned","properPrecaution","irresistibleForce"],
    winner="respondent", remedy="Remedy.exempt",
    reason=["properPrecaution","irresistibleForce"], tradition="rabbinic")

bad = Holding(   # a respondent's defence used as the claimant's ratio
    cite="TEST: malformed",
    situation=["harmOccurred","respondentsInstrument","behavedAnomalously"],
    winner="claimant", remedy='(Remedy.compensate ⟨"the damage"⟩)',
    reason=["behavedAnomalously"], tradition="rabbinic")

ugly = Holding(  # a factor that does not exist
    cite="TEST: bad factor", situation=["harmOccurred","notAFactor"],
    winner="claimant", remedy="Remedy.exempt", reason=["harmOccurred"],
    tradition="roman")

for label, h in [("good", good), ("reasoning error", bad), ("syntax error", ugly)]:
    r = verify(h, h.tradition)
    print(f"{label:16s} {r.summary()}")
    for e in r.errors[:2]:
        print(f"{'':16s}   {e[:110]}")
    print()"""),
        new_markdown_cell("""\
Notice what the middle case shows. The candidate is *syntactically perfect* —
every name exists, the remedy is well-typed — and it still fails, because
`behavedAnomalously` is a reason for the respondent and cannot be a reason the
claimant won. That check is the whole argument for targeting a proof assistant
rather than a JSON schema."""),
        new_markdown_cell("""\
## The prompt

Built from the formal apparatus rather than from similarity. Have a look at
what the model actually sees."""),
        new_code_cell("""\
from nomos import prompts
from nomos.schema import read_jsonl

provisions = list(read_jsonl("data/corpus/provisions.jsonl"))
target = next(p for p in provisions if p["canonical"] == "D.9.2.31")   # the pruner

guess = ["harmOccurred", "respondentActedDirectly", "harmToPerson",
         "noPrecaution", "inPublicOrClaimantsGround"]
user = prompts.build_prompt(target, seed, guess_situation=guess)
print(user[user.index("PRECEDENT ALREADY"):][:2600])"""),
        new_markdown_cell("""\
## Running the pipeline

`EchoBackend` needs no network and is what the tests use. For real runs, set an
API key and swap in `AnthropicBackend` or `OpenAIBackend`, or point
`HFBackend` at the model fine-tuned in notebook 3."""),
        new_code_cell("""\
from nomos.pipeline import (AnthropicBackend, EchoBackend, OpenAIBackend,
                            HFBackend, run, formalize)

if os.environ.get("ANTHROPIC_API_KEY"):
    backend = AnthropicBackend(model="claude-sonnet-4-5")
    print("using Anthropic")
elif os.environ.get("OPENAI_API_KEY"):
    backend = OpenAIBackend()
    print("using OpenAI")
else:
    backend = EchoBackend(answers={
        "PROVISION TO FORMALISE": json.dumps({
            "applicable": True,
            "restatement": ("A pruner who throws down a branch without calling out "
                            "is liable where the branch falls in a public place, and "
                            "on private ground too if a careful man would have "
                            "foreseen the danger."),
            "situation": ["harmOccurred", "respondentActedDirectly", "harmToPerson",
                          "noPrecaution", "inPublicOrClaimantsGround"],
            "winner": "claimant",
            "remedy": '(Remedy.compensate ⟨"the damage"⟩)',
            "reason": ["respondentActedDirectly", "noPrecaution"],
            "confidence": "high",
            "notes": "Mucius extends the rule to private ground by a foreseeability test."
        }),
    }, default=json.dumps({"allocates_loss": True,
                           "factors": ["harmOccurred", "respondentActedDirectly",
                                       "harmToPerson", "noPrecaution",
                                       "inPublicOrClaimantsGround"],
                           "fact_pattern": "FP-WRONGFUL-DAMAGE",
                           "one_line": "the pruner who fells a branch without warning"}))
    print("no API key found -- using EchoBackend with a scripted answer")"""),
        new_code_cell("""\
out = formalize(target, seed, backend, max_repairs=2,
                verify_with_lean=lean_available())
print("status:    ", out.status)
print("retrieved: ", out.retrieved[:5])
if out.verification:
    print("verified:  ", out.verification.summary())
if out.holding:
    print()
    from nomos.verify import render
    print(render(out.holding))"""),
        new_markdown_cell("""\
## Evaluation

The metric that matters is stratified. A system that copies the nearest binding
precedent scores perfectly on provisions whose outcome the corpus already
forced, and learns nothing. So results are reported separately for:

* **forced** — the case base already determined the outcome. Cheap.
* **open** — nothing settled it. The model had to read the text.

`novelty_gap` is the difference. A large positive gap means the system is
retrieving rather than reading."""),
        new_code_cell("""\
from nomos import baselines, eval as ev

base, held = ev.holdout_split(seed, fraction=0.35, seed_value=7)
print(f"case base {len(base)}  |  held out {len(held)}")
print("strata:", {"open": sum(1 for h in held if ev.is_open(base, h.situation)),
                  "forced": sum(1 for h in held if not ev.is_open(base, h.situation))})
print()

lex = baselines.make_lexical(base, texts)
rows = []
for name, fn in [("majority", baselines.majority),
                 ("nearest_precedent", baselines.nearest_precedent),
                 ("lexical_nn", lex)]:
    preds = {h.cite: fn(h.situation, base,
                        {"citation": h.cite, "text": texts.get(h.cite, "")})
             for h in held}
    rep = ev.evaluate(held, preds, base)
    o, f = rep.by_stratum.get("open", {}), rep.by_stratum.get("forced", {})
    rows.append((name, o.get("outcome", 0), f.get("outcome", 0),
                 o.get("ratio_jaccard", 0), rep.novelty_gap() or 0))

print(f"{'system':20s} {'open':>7s} {'forced':>8s} {'ratio(open)':>12s} {'gap':>7s}")
for r in rows:
    print(f"{r[0]:20s} {r[1]:7.2f} {r[2]:8.2f} {r[3]:12.2f} {r[4]:+7.2f}")"""),
        new_markdown_cell("""\
**Read these numbers with the sample size in mind.** The held-out set is about
fifteen holdings, so a single case moves a number by seven points. They are here
to show the harness works and that the stratification bites, not to establish
anything about any system. Getting the seed corpus to a few hundred holdings is
the first thing worth doing with this repository.

What the table does show: `nearest_precedent` gets everything right on the
forced stratum and much less on the open one. Any evaluation that pooled the
two would have reported it as a strong system."""),
        new_markdown_cell("""\
## A full run

Formalising a slice of the Digest, growing the case base as we go. This costs
real API calls if a key is set, so it is deliberately small — raise `LIMIT` to
scale it up."""),
        new_code_cell("""\
LIMIT = 8
candidates = [p for p in provisions
              if p["work"] == "Digesta Iustiniani"
              and p["canonical"].startswith("D.9.2.")
              and p["kind"] == "provision"
              and 120 < len(p["text"] or "") < 900][:LIMIT]
print(f"{len(candidates)} candidate provisions")
for p in candidates[:3]:
    print(f"  {p['citation']:16s} {p['text'][:90]}...")"""),
        new_code_cell("""\
# Uncomment to run.  With EchoBackend this returns 'not-applicable' for
# everything, which is the correct behaviour for a backend that knows nothing.
#
# results = run(candidates, seed, backend, max_repairs=2,
#               verify_with_lean=lean_available(),
#               on_result=lambda o: print(f"{o.citation:18s} {o.status:16s} "
#                                         f"{(o.verification.summary() if o.verification else '')}"))
# import collections; print(collections.Counter(o.status for o in results))
#
# Path("data/runs").mkdir(parents=True, exist_ok=True)
# with open("data/runs/digest_9_2.jsonl", "w") as fh:
#     for o in results:
#         fh.write(json.dumps(o.to_json(), ensure_ascii=False) + "\\n")
print("ready")"""),
    ]
    nb = new_notebook(cells=cells)
    nb.metadata = {"kernelspec": {"display_name": "Python 3", "language": "python",
                                  "name": "python3"},
                   "language_info": {"name": "python", "version": "3.11"}}
    return nb


# ---------------------------------------------------------------------------
# 03: fine-tuning
# ---------------------------------------------------------------------------

def notebook_finetune() -> nbf.NotebookNode:
    cells = [
        new_markdown_cell("""\
# 3 · Fine-tuning with a verifier in the loop

Train a small open model to emit `Holding` JSON from a provision plus its
retrieved precedents, then run **expert iteration**: sample, verify with Lean,
keep only what verifies, retrain on that.

This is the standard recipe from neural theorem proving (DeepSeek-Prover,
Lean-STaR, and the expert-iteration line generally) applied to a domain where
the verifier checks something more interesting than type-correctness. Here a
sample survives only if its ratio is *legally* well-formed and it does not
contradict the precedents already formalised around it.

**Where to run this.** A T4 or better; Colab's free tier is enough for a 7B
model in 4-bit with LoRA. Everything before the training cell runs on CPU.

**Expected scale.** 43 seed pairs is far too few to fine-tune on. The realistic
sequence is: (1) bootstrap a few hundred more pairs with a strong API model
through notebook 2, keeping only verified ones; (2) fine-tune on those;
(3) iterate. Cell 6 below builds the dataset from whatever is on disk, so it
grows as you run notebook 2."""),
        new_code_cell(PREAMBLE),
        new_markdown_cell("## 1. Dependencies\n\nSkip if already installed."),
        new_code_cell("""\
# !pip -q install "transformers>=4.44" "peft>=0.12" "trl>=0.9" "datasets>=2.20" \\
#                 "accelerate>=0.33" "bitsandbytes>=0.43" sentencepiece
import importlib
for m in ["torch", "transformers", "peft", "trl", "datasets"]:
    try:
        importlib.import_module(m)
        print(f"{m:14s} ok")
    except ImportError:
        print(f"{m:14s} MISSING -- uncomment the pip line above")"""),
        new_markdown_cell("""\
## 2. Build the training set

Each example is a chat exchange:

* **system** — the formalisation instructions from `nomos.prompts.SYSTEM`,
  including the three rules the verifier enforces;
* **user** — the factor glossary, the remedy grammar, the retrieved precedents
  with the reason each is shown, and the provision;
* **assistant** — the gold `Holding` as JSON.

The precedents in the user turn are retrieved *excluding the target itself*, so
the model never sees the answer it is being asked for."""),
        new_code_cell("""\
from nomos.schema import read_jsonl
from nomos.analogy import Holding, retrieve
from nomos import prompts

seed_rows = list(read_jsonl("data/seed/formalizations.jsonl"))
seed = [Holding(cite=r["cite"], situation=r["situation"], winner=r["winner"],
                remedy=r["remedy"], reason=r["reason"], tradition=r["tradition"],
                restatement=(r.get("text") or "")[:300]) for r in seed_rows]

def example_for(row, corpus):
    target = {"citation": row["cite"], "work": row["tradition"],
              "tradition": row["tradition"], "language": "en",
              "canonical": row["cite"], "text": row.get("text"),
              "source": row.get("source") or {}}
    user = prompts.build_prompt(target, [h for h in corpus if h.cite != row["cite"]],
                                guess_situation=row["situation"], k=6)
    answer = {"applicable": True,
              "restatement": (row.get("text") or "")[:200],
              "situation": row["situation"], "winner": row["winner"],
              "remedy": row["remedy"], "reason": row["reason"],
              "confidence": "high", "notes": ""}
    return {"messages": [
        {"role": "system", "content": prompts.SYSTEM},
        {"role": "user", "content": user},
        {"role": "assistant", "content": json.dumps(answer, ensure_ascii=False, indent=2)},
    ], "cite": row["cite"], "tradition": row["tradition"]}

examples = [example_for(r, seed) for r in seed_rows]

# Anything notebook 2 has accepted, added here.
run_dir = Path("data/runs")
if run_dir.exists():
    for f in run_dir.glob("*.jsonl"):
        for line in open(f, encoding="utf8"):
            o = json.loads(line)
            if o.get("status") == "accepted" and o.get("holding"):
                h = o["holding"]
                examples.append(example_for(
                    {"cite": h["cite"], "tradition": h.get("tradition", ""),
                     "situation": h["situation"], "winner": h["winner"],
                     "remedy": h["remedy"], "reason": h["reason"],
                     "text": h.get("restatement", ""), "source": {}}, seed))

print(f"{len(examples)} training examples")
print(f"mean user-turn length: {sum(len(e['messages'][1]['content']) for e in examples)/len(examples):,.0f} chars")

Path("data/train").mkdir(parents=True, exist_ok=True)
with open("data/train/sft.jsonl", "w", encoding="utf8") as fh:
    for e in examples:
        fh.write(json.dumps(e, ensure_ascii=False) + "\\n")
print("wrote data/train/sft.jsonl")"""),
        new_markdown_cell("""\
## 3. Split

Held out **by tradition**, not at random. A random split lets the model see
Exodus 21:29 while being tested on Exodus 21:36, which is nearly the same
sentence; the resulting number measures memorisation. Holding out a whole
tradition asks the real question: does the factor vocabulary learned on Rome
transfer to Babylon?"""),
        new_code_cell("""\
HELDOUT_TRADITION = "mesopotamian"
train = [e for e in examples if e["tradition"] != HELDOUT_TRADITION]
test  = [e for e in examples if e["tradition"] == HELDOUT_TRADITION]
print(f"train {len(train)}  test {len(test)}  (held out: {HELDOUT_TRADITION})")"""),
        new_markdown_cell("## 4. Load the base model\n\n"
                          "Any instruct-tuned model with a chat template. 7-8B in 4-bit fits a T4."),
        new_code_cell("""\
MODEL_ID = "Qwen/Qwen2.5-7B-Instruct"    # or meta-llama/Llama-3.1-8B-Instruct

# import torch
# from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
#
# bnb = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
#                          bnb_4bit_compute_dtype=torch.bfloat16,
#                          bnb_4bit_use_double_quant=True)
# tok = AutoTokenizer.from_pretrained(MODEL_ID)
# tok.pad_token = tok.pad_token or tok.eos_token
# model = AutoModelForCausalLM.from_pretrained(MODEL_ID, quantization_config=bnb,
#                                              device_map="auto",
#                                              torch_dtype=torch.bfloat16)
# model.config.use_cache = False
print("model id:", MODEL_ID)"""),
        new_markdown_cell("## 5. LoRA + SFT"),
        new_code_cell("""\
# from peft import LoraConfig
# from trl import SFTConfig, SFTTrainer
# from datasets import Dataset
#
# peft_config = LoraConfig(
#     r=32, lora_alpha=64, lora_dropout=0.05, bias="none",
#     task_type="CAUSAL_LM",
#     target_modules=["q_proj","k_proj","v_proj","o_proj",
#                     "gate_proj","up_proj","down_proj"])
#
# args = SFTConfig(
#     output_dir="checkpoints/nomos-sft",
#     num_train_epochs=3,
#     per_device_train_batch_size=1,
#     gradient_accumulation_steps=8,
#     learning_rate=1e-4,
#     lr_scheduler_type="cosine",
#     warmup_ratio=0.05,
#     logging_steps=5,
#     save_strategy="epoch",
#     bf16=True,
#     max_seq_length=6144,     # the precedent block is long; do not truncate it
#     gradient_checkpointing=True,
#     report_to=[],
# )
#
# trainer = SFTTrainer(
#     model=model, args=args, peft_config=peft_config,
#     train_dataset=Dataset.from_list([{"messages": e["messages"]} for e in train]),
#     eval_dataset=Dataset.from_list([{"messages": e["messages"]} for e in test]),
#     processing_class=tok,
# )
# trainer.train()
# trainer.save_model("checkpoints/nomos-sft")
print("training cell -- uncomment to run")"""),
        new_markdown_cell("""\
## 6. Expert iteration

The part that makes this worth doing. Sample k candidates per provision at
temperature, verify each with Lean, keep only those that pass all three checks,
and add them to the training set. The verifier is the filter, so the model is
never trained on a formalisation that contradicts the corpus.

Two guards worth keeping:

* **Do not keep a sample merely because it compiles.** Require `well_formed`
  and `coheres`. A compiling-but-incoherent sample teaches the model to
  contradict the corpus fluently.
* **Deduplicate by holding, not by text.** Several samples will converge on the
  same `Holding` with different prose; keeping all of them over-weights easy
  provisions."""),
        new_code_cell("""\
from nomos.verify import verify, lean_available
from nomos.pipeline import parse_json
from nomos.factors import BY_NAME

def expert_iterate(provisions, corpus, generate, k=4, require_coherence=True):
    \"\"\"`generate(system, user, n) -> list[str]` samples n completions.\"\"\"
    kept, seen = [], set()
    for p in provisions:
        guess = p.get("situation")
        user = prompts.build_prompt(p, corpus, guess_situation=guess, k=6)
        for raw in generate(prompts.SYSTEM, user, k):
            d = parse_json(raw)
            if not d or d.get("applicable") is False:
                continue
            sit = [f for f in d.get("situation", []) if f in BY_NAME]
            rsn = [f for f in d.get("reason", []) if f in BY_NAME]
            h = Holding(cite=p.get("citation", "?"), situation=sit,
                        winner=("respondent" if d.get("winner") == "respondent"
                                else "claimant"),
                        remedy=d.get("remedy", "Remedy.exempt"), reason=rsn,
                        tradition=p.get("tradition", ""))
            key = (h.cite, tuple(sorted(sit)), h.winner, h.remedy, tuple(sorted(rsn)))
            if key in seen:
                continue
            seen.add(key)
            r = verify(h, h.tradition) if lean_available() else None
            if r and r.ok and (r.coheres is not False or not require_coherence):
                kept.append((h, r))
    return kept

print("expert_iterate defined; supply a `generate` and a provision list to run it")"""),
        new_markdown_cell("""\
## 7. Evaluate the fine-tuned model

Same stratified harness as notebook 2, so the numbers are comparable to the
baselines there. Quote the **open** stratum."""),
        new_code_cell("""\
from nomos import eval as ev, baselines
from nomos.pipeline import HFBackend, formalize

# backend = HFBackend("checkpoints/nomos-sft")
# base = [h for h in seed if h.tradition != HELDOUT_TRADITION]
# gold = [h for h in seed if h.tradition == HELDOUT_TRADITION]
# preds = {}
# for h in gold:
#     row = next(r for r in seed_rows if r["cite"] == h.cite)
#     p = {"citation": h.cite, "tradition": h.tradition, "text": row.get("text"),
#          "canonical": h.cite, "work": h.tradition, "language": "en", "source": {}}
#     o = formalize(p, base, backend, max_repairs=1, verify_with_lean=lean_available())
#     if o.holding:
#         preds[h.cite] = o.holding
# rep = ev.evaluate(gold, preds, base)
# print(rep.render())
print("evaluation cell -- uncomment after training")"""),
        new_markdown_cell("""\
## What success would look like

Worth writing down before running anything, so the goalposts stay put.

* **Ratio agreement above chance on the open stratum.** Outcome agreement is
  easy — most provisions find for the claimant. Agreeing on *which facts
  mattered* is the thing precedent actually transmits, and `ratio_jaccard` on
  open cases is the number to watch.
* **Transfer across traditions.** Train without Mesopotamia, test on it. If
  that works, the factor vocabulary is capturing something about legal
  structure rather than about the idiom of a particular text.
* **The verifier catching real errors, not just typos.** Track what fraction of
  rejections are well-formedness or coherence failures rather than syntax. A
  model whose only failures are syntax is not being asked hard enough
  questions.
* **A falsifier.** If a model trained on Rome and the Mishnah can formalise
  Hammurabi as accurately as one trained on Hammurabi directly, the factor
  vocabulary is doing real work. If it cannot, the vocabulary is
  tradition-specific and the whole comparative programme needs rethinking.
  That is the experiment this repository exists to make runnable."""),
    ]
    nb = new_notebook(cells=cells)
    nb.metadata = {"kernelspec": {"display_name": "Python 3", "language": "python",
                                  "name": "python3"},
                   "language_info": {"name": "python", "version": "3.11"}}
    return nb


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for name, nb in [("01_corpus.ipynb", notebook_corpus()),
                     ("02_autoformalize.ipynb", notebook_autoformalize()),
                     ("03_finetune.ipynb", notebook_finetune())]:
        path = os.path.join(OUT, name)
        nbf.validate(nb)
        with open(path, "w", encoding="utf8") as fh:
            nbf.write(nb, fh)
        print(f"wrote {path}  ({len(nb.cells)} cells)")


if __name__ == "__main__":
    main()
