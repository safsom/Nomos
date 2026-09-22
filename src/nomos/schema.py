"""Corpus schema for Nomos.

A *provision* is the atomic unit of the corpus: the smallest stretch of a legal
text that states, or argues toward, an allocation of liability.  We deliberately
do not try to make provisions uniform in length or force across traditions --
a Digest fragment, a Mishnah, and a paragraph of Hammurabi are different kinds
of object.  What we make uniform is the *addressing*: every provision carries a
stable canonical citation so that formalizations, alignments and precedent
links can all key off the citation rather than off our segmentation choices.
"""

from __future__ import annotations

import dataclasses
import hashlib
import json
import re
from dataclasses import dataclass, field
from typing import Any, Iterable, Iterator, Optional

SCHEMA_VERSION = "1.0"


@dataclass(frozen=True)
class Source:
    """Where a text came from, and under what terms we may redistribute it."""

    name: str
    url: str
    license: str
    # "included"  -> text ships in this repository
    # "fetchable" -> text is public but blocked from the build sandbox; the
    #                fetcher in src/nomos/fetch/restricted.py will retrieve it
    # "reference" -> we cite it but do not redistribute (e.g. in-copyright
    #                translations); only citations and editorial summaries ship
    availability: str = "included"
    note: str = ""


@dataclass
class Provision:
    """One addressable unit of legal text."""

    id: str                       # stable, e.g. "roman.digest.9.1.1.4"
    tradition: str                # roman | rabbinic | mesopotamian | ...
    work: str                     # "Digesta Iustiniani"
    citation: str                 # "Dig. 9.1.1.4"  (as the source prints it)
    canonical: str                # "D.9.1.1.4"     (normalised for matching)
    language: str                 # ISO 639-1/3
    text: Optional[str]           # None when availability != "included"
    source: Source
    attribution: str = ""         # "Ulpianus 18 ad ed." / "R. Yehuda"
    era: tuple[int, int] | None = None   # rough (earliest, latest) year, neg = BCE
    path: list[str] = field(default_factory=list)   # structural path, e.g. ["9","1","1","4"]
    kind: str = "provision"       # provision | rubric | commentary | case
    meta: dict[str, Any] = field(default_factory=dict)

    def to_json(self) -> dict[str, Any]:
        d = dataclasses.asdict(self)
        d["source"] = dataclasses.asdict(self.source)
        return d

    @property
    def digest(self) -> str:
        return hashlib.sha1((self.id + (self.text or "")).encode("utf8")).hexdigest()[:12]


# --------------------------------------------------------------------------
# Fact patterns: the cross-cultural scenarios that organise the whole project
# --------------------------------------------------------------------------

@dataclass
class FactPattern:
    """A recurring scenario that many legal orders have had to resolve.

    The point of the project is that these scenarios are *stable* across
    cultures while the resolutions are not.  That makes them a natural
    alignment axis: a fact pattern is the "same question" asked of Babylon,
    Athens, Rome, the Mishnah and the Restatement.
    """

    id: str                # "FP-GRAZE"
    name: str
    scenario: str          # a culture-neutral statement of the facts
    issue: str             # the question the legal order must answer
    factors: list[str]     # factor ids that are live in this pattern
    witnesses: list[dict[str, str]] = field(default_factory=list)
    notes: str = ""

    def to_json(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class Factor:
    """A HYPO/CATO-style factor: a stereotypical fact pattern that is a reason.

    `side` is "P" if the factor is a reason for the party claiming redress
    (plaintiff), "D" if it is a reason for the party resisting (defendant).
    Following Horty & Bench-Capon (2012), a factor always favours exactly one
    side; a fact that can cut either way is modelled as two factors.
    """

    id: str
    side: str              # "P" | "D"
    name: str
    gloss: str
    # `dimension` groups factors that are orderings of the same underlying
    # magnitude (e.g. degree of precaution), which is what makes a fortiori
    # reasoning available.
    dimension: str = ""

    def to_json(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class SeedFormalization:
    """A hand-checked (text, Lean) pair: the training signal for the pipeline."""

    id: str
    provision_id: str           # key into the provision corpus
    fact_pattern: str
    tradition: str
    citation: str
    # Editorial restatement of what the provision holds, in neutral language.
    # This is *ours*, not a translation, and is always safe to redistribute.
    restatement: str
    factors_pro_claimant: list[str]
    factors_pro_respondent: list[str]
    outcome: str                # "claimant" | "respondent" | "split" | "open"
    lean_decl: str              # the Lean declaration name
    lean_source: str            # the Lean source text
    lean_module: str            # which module it lives in
    notes: str = ""
    confidence: str = "high"    # high | medium | low -- our confidence in the reading

    def to_json(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


# --------------------------------------------------------------------------
# io helpers
# --------------------------------------------------------------------------

def _open(path: str, mode: str):
    """Open a file, transparently gzipping when the name ends in .gz.

    The built corpus ships compressed -- 67 MB of JSONL is 14 MB gzipped, and
    it is a build artefact anyway -- so every reader and writer here handles
    both."""
    import gzip
    if path.endswith(".gz"):
        return gzip.open(path, mode + "t", encoding="utf8")
    return open(path, mode, encoding="utf8")


def resolve(path: str) -> str:
    """Return `path` if it exists, else `path + '.gz'` if that does."""
    import os
    if os.path.exists(path):
        return path
    if not path.endswith(".gz") and os.path.exists(path + ".gz"):
        return path + ".gz"
    return path


def write_jsonl(path: str, rows: Iterable[Any]) -> int:
    n = 0
    with _open(path, "w") as fh:
        for r in rows:
            obj = r.to_json() if hasattr(r, "to_json") else r
            fh.write(json.dumps(obj, ensure_ascii=False) + "\n")
            n += 1
    return n


def read_jsonl(path: str) -> Iterator[dict[str, Any]]:
    with _open(resolve(path), "r") as fh:
        for line in fh:
            line = line.strip()
            if line:
                yield json.loads(line)


_WS = re.compile(r"[ \t\xa0]+")
_NL = re.compile(r"\n{2,}")


def clean(text: str) -> str:
    """Collapse the whitespace noise that HTML-derived corpora are full of."""
    text = text.replace("\r", "")
    text = _WS.sub(" ", text)
    text = "\n".join(ln.strip() for ln in text.split("\n"))
    text = _NL.sub("\n", text)
    return text.strip()


TAG = re.compile(r"<[^>]+>")


def strip_tags(text: str) -> str:
    return clean(TAG.sub(" ", text))
