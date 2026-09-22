# Nomos

**A formal model of legal reasoning with liability taken as primitive.**

---

## Contents

- [Overview](#overview)
- [Architecture: Liability as Primitive](#architecture-liability-as-primitive)
- [Formal Properties](#formal-properties)
- [Corpus](#corpus)
- [Findings](#findings)
- [Quickstart](#quickstart)
- [Evaluation](#evaluation)
- [AI Use](#ai-use)
- [Licences](#licences)

---

## Overview

- **Formal Methods & AI**: `lean/Nomos/Reasoning/` provides a mechanised account of precedential constraint and soundness results for analogical extension. `src/nomos/verify.py` is a verifier that rejects legally incoherent formalisations.
- **Comparative Law**: `lean/Nomos/Bench/` and `lean/Nomos/Corpus/` formalise six legal traditions in a shared vocabulary.
- **Commercial Law**: `lean/Nomos/Core/Standard.lean` provides a formal model of vague standards (e.g., "commercially reasonable efforts").

---

## Architecture: Liability as Primitive

Nomos models law by taking **liability** (who must bear, repair, or answer for a loss) as the primitive, rather than rights or duties. 

- **Derivation of Rights**: In `lean/Nomos/Core/Right.lean`, rights are defined as conjunctions of liability facts. Hohfeld's incidents (claim, duty, privilege, no-claim, power, liability, immunity, disability) are derived from a single exposure relation. 
- **Theorem Example**: `privilege_is_waiver` proves every liberty is the waiver of an order. 
- **Scope Limitation**: Nomos focuses on private law and liability rules. It does not model constitutional law, jurisdiction, or procedural rights (e.g., `magna_carta_39_is_not_a_liability_rule`).

---

## Formal Properties

### 1. Vague Standards (`lean/Nomos/Core/Standard.lean`)
Vague standards are modeled as comparative relations ("precaution A is at least as careful as precaution B") alongside a historical record of conduct held sufficient or insufficient, rather than as defined thresholds.
- `not_settled_both_ways`: Coherence is verifiable from the record alone.
- `decide_open_preserves_coherent`: In the open region, either decision maintains consistency.
- `settled_monotone`: The settled region strictly grows.

### 2. Analogical Extension (`lean/Nomos/Reasoning/Analogy.lean`)
- `no_strengthening`: Proves that analogical extension transfers a lower bound, never a specific quantum or value.

### 3. Verification Engine
The system runs three checks on every candidate formalisation:
1. **Compiles**: Validates syntax and types.
2. **Well-formed**: Ensures every cited fact is present in the case and favours the winning party.
3. **Coheres**: Ensures the addition does not force contradictory outcomes on any situation already addressed in the case base.

---

## Corpus

The test set utilizes ancient legal texts due to their public domain status, maximal cultural divergence, and structure (stating outcomes without explicit reasons).

**Size**: 60,595 provisions, 21.4M characters, 5 languages.

| Tradition | Works | Provisions |
|---|---|---:|
| **Roman & canon** | Digest, Codex Iustinianus, Codex Theodosianus, Gaius, Justinian, Twelve Tables, Decretals of Gregory IX | 30,332 |
| **Chinese** | Tang Code, Qing Code, Ming Code, Song judgments, Qing case reports, etc. | 16,849 |
| **Rabbinic & biblical** | Talmud Bavli, Mishnah Seder Nezikin, Exodus | 13,351 |
| **English** | Magna Carta (1215) | 63 |

- **Annotations**: Contains 60 machine-checked formalisations and 9 cross-cultural fact patterns.
- **Restricted Texts**: Texts encumbered by copyright (e.g., Hammurabi, Animals Act 1971) are provided as marked editorial restatements with `text: null`. Run `python -m nomos.fetch.restricted` to retrieve the original texts.

---

## Findings

Computed across the formalised holdings:
- **Fact Convergence**: Seven holdings across six traditions resolve forewarned animal cases based on the identical fact: the keeper knew the animal was dangerous.
- **Incommensurability**: `Remedy.capital_incomparable_tariff` proves certain remedies (e.g., capital liability vs. fines) lack an ordered exchange rate in specific traditions.
- **Zero-Fault Allocation**: Four unlinked legal systems (Eshnunna, Exodus, Mishnah, Tang Code) split the loss evenly when two animals kill each other without keeper fault.

---

## Quickstart

```bash
# 1. Install Lean and build (approx. 13 seconds)
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
cd lean && lake build && lake exe export-corpus | head -3 && cd ..

# 2. Build the corpus (approx. 7 seconds)
make corpus

# 3. Setup, test, and run
make seed          # re-export the 60 formalisations from Lean
make test          # run 35 tests, including Python/Lean agreement
jupyter lab notebooks/

## Commands

```bash
# 1. Build Lean library (No Mathlib, no cache; ~13 seconds)
curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
cd lean && lake build && lake exe export-corpus | head -3 && cd ..

# 2. Build the corpus (~7 seconds; derived artefact)
make corpus

# 3. Operations
make seed          # Re-export the 60 formalisations from Lean
make test          # Run 35 tests, including Python/Lean agreement
jupyter lab notebooks/
```

**Note:** Set `PYTHONPATH=src` if not installing the package.

**Utility Flags:**
```bash
python -m nomos.build_corpus --no-nc      # Drop non-commercially licensed texts
python -m nomos.fetch.restricted --list   # List cited but unbundled texts and retrieval instructions
```

## Layout

```text
lean/          4,464 lines, 128 theorems, 18 modules. Decidable finite combinatorics over fact sets.
data/raw/      Staged source texts, with their licences.
data/seed/     The 60 hand-made formalisations, exported from Lean.
src/nomos/     Corpus builders, constraint engine, retrieval, Lean verifier, pipelines.
notebooks/     1 corpus · 2 autoformalisation · 3 fine-tuning.
tests/         35 tests.
docs/          LEAN_TOUR.md — A guided reading of the Lean library.
```

## Evaluation

Compile rates are an invalid metric (copying the nearest precedent guarantees a perfect compile score). Evaluation is stratified on a 15-holding held-out split into **forced** (outcome determined by existing case base) and **open** (outcome undetermined) cases. 

| system | open | forced | ratio agreement (open) | gap |
|---|---:|---:|---:|---:|
| majority class | 0.20 | 0.90 | 0.00 | +0.70 |
| nearest precedent | 0.40 | 1.00 | 0.10 | +0.60 |
| lexical nearest-neighbour | 1.00 | 0.50 | 0.10 | −0.50 |

**Key Metric:** Quote the **ratio agreement (open)** column. This measures whether the system agrees on *which facts mattered* to the decision, not merely who won.

## AI Use

Initial drafting was completed in collaboration with a large language model (Claude, specifically the $20/month version) and independently and substantially revised by the author. All Lean proofs are machine-checked (no `sorry`, no axiom). Source texts in `data/raw/` are unmodified original data (or placeholders put because of licensing issues, see below).

## Licences

- **Code:** MIT (`LICENSE`).
- **Data:** Mixed provenance. See `DATA_LICENSES.md` before redistribution. Substantial portions (e.g., specific Talmudic translations) are CC-BY-NC. Use `python -m nomos.build_corpus --no-nc` to generate a strictly commercial-safe corpus. 
- **Restricted Texts:** Texts encumbered by copyright (e.g., Hammurabi, Animals Act 1971) are excluded and replaced with editorial restatements marked `text: null`.