"""Baselines.

Any claim that a language model has learned to formalise law by analogy has to
beat systems that are not reading the text at all.  Three are implemented here,
all of them cheap, and the middle one is surprisingly hard to beat on the
metrics people usually report.

* `majority` -- always find for the claimant and award compensation.  The
  trivial floor.
* `nearest_precedent` -- find the precedent that binds these facts (or, if
  none binds, the nearest by constraint distance) and copy its outcome, ratio
  and remedy verbatim.  This is the system that "reasons by analogy" in the
  most literal possible sense: it has no notion of what the provision says.
* `lexical` -- BM25 over provision text, copy the formalisation of the nearest
  provision.  The retrieval-augmented baseline without the reasoning step.

All three take the fact situation as given (an oracle).  That isolates the
subtask -- given the facts, what does the order hold? -- from fact extraction,
which is a separate problem and one the triage pass handles.

The point of `nearest_precedent` in particular: on any evaluation that does not
separate already-forced cases from open ones, it will look excellent, because
most provisions in a well-organised legal text are variations on their
neighbours.  `eval.Report.novelty_gap` exists to make that visible.
"""

from __future__ import annotations

from typing import Callable, Optional

from .analogy import (BM25, Holding, at_least_as_strong, forces,
                      grounds_of_distinction, retrieve, tokenize)


def majority(situation: list[str], corpus: list[Holding],
             provision: Optional[dict] = None) -> Holding:
    return Holding(
        cite=(provision or {}).get("citation", "?"),
        situation=list(situation), winner="claimant",
        remedy='(Remedy.compensate ⟨"the damage"⟩)',
        reason=[f for f in situation
                if f in ("harmOccurred", "respondentsInstrument")],
        restatement="[baseline: majority class]", confidence="low")


def nearest_precedent(situation: list[str], corpus: list[Holding],
                      provision: Optional[dict] = None) -> Holding:
    """Copy the binding precedent, or the closest one if none binds."""
    cite = (provision or {}).get("citation", "?")
    src: Optional[Holding] = None
    for side in ("claimant", "respondent"):
        h = forces(corpus, situation, side)      # type: ignore[arg-type]
        if h is not None:
            src = h
            break
    if src is None:
        got = retrieve(corpus, situation, k=1)
        if got:
            src = got[0].holding
    if src is None:
        return majority(situation, corpus, provision)
    return Holding(
        cite=cite, situation=list(situation), winner=src.winner,
        remedy=src.remedy,
        reason=[f for f in src.reason if f in situation],
        restatement=f"[baseline: copied from {src.cite}]", confidence="low")


def make_lexical(corpus: list[Holding], texts: dict[str, str]
                 ) -> Callable[..., Holding]:
    """BM25 over the text of the formalised provisions."""
    cites = [h.cite for h in corpus]
    docs = [tokenize(texts.get(c, "")) for c in cites]
    index = BM25(docs)
    by_cite = {h.cite: h for h in corpus}

    def run(situation: list[str], _corpus: list[Holding],
            provision: Optional[dict] = None) -> Holding:
        q = (provision or {}).get("text") or ""
        top = index.top(q, k=1)
        cite = (provision or {}).get("citation", "?")
        if not top:
            return majority(situation, corpus, provision)
        src = by_cite[cites[top[0][0]]]
        return Holding(
            cite=cite, situation=list(situation), winner=src.winner,
            remedy=src.remedy,
            reason=[f for f in src.reason if f in situation],
            restatement=f"[baseline: lexical nearest = {src.cite}]",
            confidence="low")

    return run


BASELINES: dict[str, Callable[..., Holding]] = {
    "majority": majority,
    "nearest_precedent": nearest_precedent,
}
