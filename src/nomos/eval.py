"""Evaluation.

The obvious metric for autoformalisation is "does it compile", and it is
almost worthless here.  A holding that compiles has used real factor names and
a real remedy constructor; it has not necessarily read the provision.  Worse,
the most reliable way to produce a compiling, well-formed, coherent holding is
to copy the nearest binding precedent -- which scores perfectly and learns
nothing.

So the harness below reports metrics in two strata:

* **forced** -- the existing case base already determined the outcome before
  the model saw the provision.  Agreement here is cheap.
* **open** -- nothing in the case base settled it.  The model had to read the
  text.  This is where the number matters, and it is the number to quote.

`novelty_gap` is the difference between the two.  A system with a large
positive gap is retrieving rather than reading.

Four things are measured against held-out gold formalisations:

1. `outcome` -- did it pick the right winner?
2. `ratio`   -- Jaccard overlap on the factors relied upon.  This is the
                hardest and most interesting: two formalisations can agree on
                the outcome while disagreeing entirely about why, and the
                *why* is what precedent transmits.
3. `remedy`  -- exact match on the remedy expression, and a looser match that
                ignores string payloads.
4. `situation` -- Jaccard on the factors found present.
"""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from typing import Iterable, Optional

from .analogy import Holding, at_least_as_strong, forces, is_open


def jaccard(a: Iterable[str], b: Iterable[str]) -> float:
    sa, sb = set(a), set(b)
    if not sa and not sb:
        return 1.0
    return len(sa & sb) / max(1, len(sa | sb))


_STRLIT = re.compile(r'"[^"]*"')


def remedy_shape(r: str) -> str:
    """The remedy with its string payloads blanked out.

    `(Remedy.inKind "of the best of his field")` and
    `(Remedy.inKind "with the best of his land")` are the same remedy *shape*
    and different remedies.  Scoring both ways separates disagreement about
    legal form from disagreement about wording."""
    return _STRLIT.sub('""', (r or "").strip())


@dataclass
class Comparison:
    citation: str
    stratum: str                  # "forced" | "open"
    outcome_match: bool
    ratio_jaccard: float
    situation_jaccard: float
    remedy_exact: bool
    remedy_shape_match: bool
    gold: Holding
    pred: Holding

    def to_json(self) -> dict:
        return {
            "citation": self.citation, "stratum": self.stratum,
            "outcome": self.outcome_match,
            "ratio_jaccard": round(self.ratio_jaccard, 3),
            "situation_jaccard": round(self.situation_jaccard, 3),
            "remedy_exact": self.remedy_exact,
            "remedy_shape": self.remedy_shape_match,
            "gold_winner": self.gold.winner, "pred_winner": self.pred.winner,
            "gold_ratio": self.gold.reason, "pred_ratio": self.pred.reason,
            "gold_remedy": self.gold.remedy, "pred_remedy": self.pred.remedy,
        }


def compare(gold: Holding, pred: Holding, base: list[Holding]) -> Comparison:
    stratum = "open" if is_open(base, gold.situation) else "forced"
    return Comparison(
        citation=gold.cite,
        stratum=stratum,
        outcome_match=(gold.winner == pred.winner),
        ratio_jaccard=jaccard(gold.reason, pred.reason),
        situation_jaccard=jaccard(gold.situation, pred.situation),
        remedy_exact=(gold.remedy.strip() == pred.remedy.strip()),
        remedy_shape_match=(remedy_shape(gold.remedy) == remedy_shape(pred.remedy)),
        gold=gold, pred=pred,
    )


def _mean(xs: list[float]) -> float:
    return sum(xs) / len(xs) if xs else 0.0


@dataclass
class Report:
    n: int
    by_stratum: dict[str, dict] = field(default_factory=dict)
    overall: dict = field(default_factory=dict)
    comparisons: list[Comparison] = field(default_factory=list)
    pipeline: dict = field(default_factory=dict)

    def novelty_gap(self, metric: str = "outcome") -> Optional[float]:
        f = self.by_stratum.get("forced", {}).get(metric)
        o = self.by_stratum.get("open", {}).get(metric)
        if f is None or o is None:
            return None
        return f - o

    def render(self) -> str:
        lines = [f"n = {self.n}"]
        if self.pipeline:
            lines.append("")
            lines.append("pipeline")
            for k, v in sorted(self.pipeline.items()):
                lines.append(f"  {k:24s} {v}")
        for name in ("open", "forced"):
            s = self.by_stratum.get(name)
            if not s:
                continue
            lines.append("")
            lines.append(f"{name}  (n={s['n']})")
            for k in ("outcome", "ratio_jaccard", "situation_jaccard",
                      "remedy_exact", "remedy_shape"):
                if k in s:
                    lines.append(f"  {k:24s} {s[k]:.3f}")
        gap = self.novelty_gap()
        if gap is not None:
            lines.append("")
            lines.append(f"novelty gap (forced - open, outcome): {gap:+.3f}")
            lines.append("  a large positive gap means the system is retrieving,")
            lines.append("  not reading.")
        return "\n".join(lines)

    def to_json(self) -> dict:
        return {"n": self.n, "by_stratum": self.by_stratum,
                "overall": self.overall, "pipeline": self.pipeline,
                "novelty_gap_outcome": self.novelty_gap(),
                "comparisons": [c.to_json() for c in self.comparisons]}


def summarise(cs: list[Comparison]) -> dict:
    if not cs:
        return {"n": 0}
    return {
        "n": len(cs),
        "outcome": _mean([1.0 if c.outcome_match else 0.0 for c in cs]),
        "ratio_jaccard": _mean([c.ratio_jaccard for c in cs]),
        "situation_jaccard": _mean([c.situation_jaccard for c in cs]),
        "remedy_exact": _mean([1.0 if c.remedy_exact else 0.0 for c in cs]),
        "remedy_shape": _mean([1.0 if c.remedy_shape_match else 0.0 for c in cs]),
    }


def evaluate(gold: list[Holding], predicted: dict[str, Holding],
             base: list[Holding], outcomes: Optional[list] = None) -> Report:
    """`predicted` is keyed by citation."""
    cs = [compare(g, predicted[g.cite], base) for g in gold if g.cite in predicted]
    by = defaultdict(list)
    for c in cs:
        by[c.stratum].append(c)
    rep = Report(
        n=len(cs),
        by_stratum={k: summarise(v) for k, v in by.items()},
        overall=summarise(cs),
        comparisons=cs,
    )
    if outcomes is not None:
        st = Counter(o.status for o in outcomes)
        attempted = [o for o in outcomes if o.status in ("accepted", "rejected")]
        rep.pipeline = {
            "provisions_seen": len(outcomes),
            **{f"status:{k}": v for k, v in sorted(st.items())},
            "accept_rate": (st["accepted"] / len(attempted)) if attempted else 0.0,
            "mean_repairs": _mean([len(o.attempts) - 1 for o in attempted]),
            "mean_seconds": _mean([o.seconds for o in outcomes]),
            "novel_share": _mean([
                1.0 if (o.verification and o.verification.is_novel) else 0.0
                for o in outcomes if o.verification]),
        }
    return rep


def holdout_split(seed: list[Holding], fraction: float = 0.3,
                  seed_value: int = 0) -> tuple[list[Holding], list[Holding]]:
    """Split the seed corpus into a case base and a held-out set.

    Splitting is by *tradition-stratified round robin* rather than at random,
    because a random split leaves the base with no witnesses for some fact
    patterns and makes the 'open' stratum uninterestingly large."""
    import random
    rng = random.Random(seed_value)
    by_trad: dict[str, list[Holding]] = defaultdict(list)
    for h in seed:
        by_trad[h.tradition].append(h)
    base, held = [], []
    for trad, hs in sorted(by_trad.items()):
        hs = list(hs)
        rng.shuffle(hs)
        k = max(1, int(round(len(hs) * fraction)))
        held.extend(hs[:k])
        base.extend(hs[k:])
    return base, held


def write_report(rep: Report, path: str) -> None:
    with open(path, "w", encoding="utf8") as fh:
        json.dump(rep.to_json(), fh, indent=2, ensure_ascii=False)
