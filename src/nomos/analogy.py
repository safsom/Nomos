"""Precedential constraint and analogical retrieval, in Python.

This mirrors `Nomos.Reasoning.Precedent` exactly, so that the pipeline can
compute constraint over the whole corpus without invoking Lean, and Lean can
then be used to *check* the results rather than to produce them.
`tests/test_agreement.py` runs both implementations over the seed corpus and
asserts they agree.

## Retrieval

The interesting design decision here is how precedents are chosen to show a
model that is being asked to formalise a new provision.  The obvious answer --
embed everything and take nearest neighbours -- is available and implemented as
a baseline in `lexical_neighbours`, but it is not the primary strategy, because
similarity is not the relation precedent runs on.

`retrieve` ranks instead by *constraint distance*:

1. **Binding precedents.**  Cases that already force an outcome here.  A model
   shown these is being told the answer is not open.
2. **Near misses.**  Cases that would bind but for one missing ratio factor, or
   one counter-factor the precedent never faced.  These are the most
   informative examples in the corpus, because each one locates a boundary: it
   says "this far and no further, and here is the fact that stops it."
3. **Same-pattern cases from other traditions.**  Useful for suggesting a
   remedy shape when the outcome is settled but the quantum is not.
4. **Lexical neighbours.**  Fallback.

This ordering falls out of the formal model rather than being tuned, which is
the point: the retrieval strategy is a consequence of the theory of precedent,
not a hyperparameter.
"""

from __future__ import annotations

import json
import math
import re
from collections import Counter
from dataclasses import dataclass, field
from typing import Iterable, Literal, Optional

from .factors import BY_NAME, Side, split_by_side

# ---------------------------------------------------------------------------


@dataclass
class Holding:
    """Mirrors `Nomos.Liability.Holding`."""

    cite: str
    situation: list[str]           # factor names
    winner: Side
    remedy: str                    # a Lean Remedy expression, as source text
    reason: list[str]              # factor names actually relied on
    tradition: str = ""
    provision_id: str = ""
    restatement: str = ""
    confidence: str = "high"

    # -- derived -----------------------------------------------------------

    @property
    def supporting(self) -> list[str]:
        return [f for f in self.situation if BY_NAME[f].side == self.winner]

    @property
    def opposing(self) -> list[str]:
        return [f for f in self.situation if BY_NAME[f].side != self.winner]

    def well_formed(self) -> bool:
        """`Holding.WellFormed`: the holding must rest on something, and what
        it rests on must be present in the case and favour the winner."""
        return bool(self.reason) and all(
            f in self.situation and BY_NAME[f].side == self.winner
            for f in self.reason)

    def malformation(self) -> list[str]:
        out = []
        if not self.reason:
            out.append("the holding relies on no factor at all: a ratio must be "
                       "non-empty, or the holding would bind every situation "
                       "that raises no counter-reason")
        if not self.situation:
            out.append("the fact situation is empty")
        for f in self.reason:
            if f not in self.situation:
                out.append(f"reason factor {f!r} is not in the fact situation")
            elif BY_NAME[f].side != self.winner:
                out.append(f"reason factor {f!r} favours {BY_NAME[f].side}, "
                           f"but the holding is for {self.winner}")
        return out

    def to_json(self) -> dict:
        return {
            "cite": self.cite, "situation": self.situation,
            "winner": self.winner, "remedy": self.remedy,
            "reason": self.reason, "tradition": self.tradition,
            "provision_id": self.provision_id,
            "restatement": self.restatement, "confidence": self.confidence,
        }

    @staticmethod
    def from_json(d: dict) -> "Holding":
        return Holding(
            cite=d["cite"], situation=list(d["situation"]), winner=d["winner"],
            remedy=d.get("remedy", "Remedy.exempt"), reason=list(d["reason"]),
            tradition=d.get("tradition", ""),
            provision_id=d.get("provision_id", ""),
            restatement=d.get("restatement", ""),
            confidence=d.get("confidence", "high"),
        )


def other(side: Side) -> Side:
    return "respondent" if side == "claimant" else "claimant"


# ---------------------------------------------------------------------------
# the constraint relation
# ---------------------------------------------------------------------------

def at_least_as_strong(situation: Iterable[str], h: Holding) -> bool:
    """`AtLeastAsStrong`: the new situation is at least as strong for `h`'s
    winner as `h`'s own situation was."""
    s = set(situation)
    if not set(h.reason) <= s:
        return False
    opp = other(h.winner)
    s_against = {f for f in s if BY_NAME[f].side == opp}
    h_against = {f for f in h.situation if BY_NAME[f].side == opp}
    return s_against <= h_against


def grounds_of_distinction(situation: Iterable[str], h: Holding
                           ) -> tuple[list[str], list[str]]:
    """Why a precedent does not bind: (missing ratio factors, new counters)."""
    s = set(situation)
    missing = [f for f in h.reason if f not in s]
    opp = other(h.winner)
    h_against = {f for f in h.situation if BY_NAME[f].side == opp}
    new_counters = [f for f in s if BY_NAME[f].side == opp and f not in h_against]
    return missing, new_counters


def forces(corpus: list[Holding], situation: Iterable[str],
           side: Side) -> Optional[Holding]:
    """The first precedent for `side` that binds `situation`, if any."""
    for h in corpus:
        if h.winner == side and at_least_as_strong(situation, h):
            return h
    return None


def is_open(corpus: list[Holding], situation: Iterable[str]) -> bool:
    return (forces(corpus, situation, "claimant") is None
            and forces(corpus, situation, "respondent") is None)


def conflicts_at(corpus: list[Holding], situation: Iterable[str]
                 ) -> list[tuple[Holding, Holding]]:
    pro = [h for h in corpus
           if h.winner == "claimant" and at_least_as_strong(situation, h)]
    con = [h for h in corpus
           if h.winner == "respondent" and at_least_as_strong(situation, h)]
    return [(p, c) for p in pro for c in con]


def coherent_on(corpus: list[Holding],
                situations: Iterable[Iterable[str]]) -> bool:
    return all(not conflicts_at(corpus, s) for s in situations)


def incoherence_report(corpus: list[Holding]) -> list[dict]:
    """Every self-contradiction the corpus commits on its own situations."""
    out = []
    for h in corpus:
        cs = conflicts_at(corpus, h.situation)
        if cs:
            out.append({
                "situation": h.situation,
                "at": h.cite,
                "conflicts": [{"claimant": p.cite, "respondent": c.cite}
                              for p, c in cs],
            })
    return out


# ---------------------------------------------------------------------------
# retrieval
# ---------------------------------------------------------------------------

RetrievalKind = Literal["binding", "near-miss", "same-pattern", "lexical"]


@dataclass
class Retrieved:
    holding: Holding
    kind: RetrievalKind
    score: float
    why: str
    missing: list[str] = field(default_factory=list)
    new_counters: list[str] = field(default_factory=list)


def retrieve(corpus: list[Holding], situation: Iterable[str],
             k: int = 8, exclude_cites: Iterable[str] = ()) -> list[Retrieved]:
    """Rank precedents by constraint distance from `situation`.

    The ordering is: binding, then near-misses at distance 1, then overlapping
    cases, then anything sharing factors at all.  Within a band, prefer
    precedents whose ratio is *larger* -- they claim more and so are more
    informative -- and then prefer greater factor overlap.
    """
    s = set(situation)
    excl = set(exclude_cites)
    out: list[Retrieved] = []

    for h in corpus:
        if h.cite in excl:
            continue
        missing, new_counters = grounds_of_distinction(s, h)
        overlap = len(s & set(h.situation))
        union = len(s | set(h.situation)) or 1
        jaccard = overlap / union

        if not missing and not new_counters:
            out.append(Retrieved(
                h, "binding", 1000 + len(h.reason) + jaccard,
                f"binds: every factor of its ratio {h.reason} is present, and "
                f"this case raises no counter-reason it did not face"))
        elif len(missing) + len(new_counters) == 1:
            if missing:
                why = (f"would bind but for the absence of {missing[0]!r}, "
                       f"which was part of its ratio")
            else:
                why = (f"would bind but for {new_counters[0]!r}, a "
                       f"counter-reason the precedent never faced")
            out.append(Retrieved(
                h, "near-miss", 500 + jaccard, why, missing, new_counters))
        elif overlap >= 2:
            out.append(Retrieved(
                h, "same-pattern", 100 + jaccard,
                f"shares {overlap} factors with this case", missing, new_counters))
        elif overlap >= 1:
            out.append(Retrieved(
                h, "lexical", jaccard,
                f"shares {overlap} factor with this case", missing, new_counters))

    out.sort(key=lambda r: -r.score)

    # Prefer a spread of traditions among equally-ranked results: showing a
    # model five rabbinic cases teaches it rabbinic style, not the legal point.
    return _diversify(out, k)


def _diversify(items: list[Retrieved], k: int) -> list[Retrieved]:
    chosen: list[Retrieved] = []
    seen_tradition: Counter[str] = Counter()
    pool = list(items)
    while pool and len(chosen) < k:
        best_i, best_key = 0, None
        for i, r in enumerate(pool):
            penalty = 3.0 * seen_tradition[r.holding.tradition]
            key = r.score - penalty
            if best_key is None or key > best_key:
                best_i, best_key = i, key
        r = pool.pop(best_i)
        chosen.append(r)
        seen_tradition[r.holding.tradition] += 1
    return chosen


# ---------------------------------------------------------------------------
# lexical baseline (BM25, no dependencies)
# ---------------------------------------------------------------------------

_TOKEN = re.compile(r"[A-Za-zÀ-ÿ]+")


def tokenize(text: str) -> list[str]:
    return [t.lower() for t in _TOKEN.findall(text or "")]


class BM25:
    """A small self-contained BM25, so the corpus tools have no hard
    dependency on scikit-learn or a vector database."""

    def __init__(self, docs: list[list[str]], k1: float = 1.5, b: float = 0.75):
        self.k1, self.b = k1, b
        self.docs = docs
        self.N = len(docs) or 1
        self.avgdl = sum(len(d) for d in docs) / self.N
        self.df: Counter[str] = Counter()
        self.tf: list[Counter[str]] = []
        for d in docs:
            c = Counter(d)
            self.tf.append(c)
            for t in c:
                self.df[t] += 1
        self.idf = {t: math.log(1 + (self.N - n + 0.5) / (n + 0.5))
                    for t, n in self.df.items()}

    def score(self, query: list[str], i: int) -> float:
        tf, dl, total = self.tf[i], len(self.docs[i]), 0.0
        for t in query:
            f = tf.get(t, 0)
            if not f:
                continue
            denom = f + self.k1 * (1 - self.b + self.b * dl / (self.avgdl or 1))
            total += self.idf.get(t, 0.0) * f * (self.k1 + 1) / denom
        return total

    def top(self, query: str, k: int = 10) -> list[tuple[int, float]]:
        q = tokenize(query)
        scored = [(i, self.score(q, i)) for i in range(self.N)]
        scored.sort(key=lambda x: -x[1])
        return [(i, s) for i, s in scored[:k] if s > 0]


def lexical_neighbours(provisions: list[dict], query: str, k: int = 10
                       ) -> list[tuple[dict, float]]:
    """Baseline retrieval over raw provision text."""
    idx = BM25([tokenize(p.get("text") or "") for p in provisions])
    return [(provisions[i], s) for i, s in idx.top(query, k)]


def load_corpus(path: str) -> list[Holding]:
    out = []
    with open(path, encoding="utf8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                out.append(Holding.from_json(json.loads(line)))
    return out
