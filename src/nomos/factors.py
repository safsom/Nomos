"""The factor vocabulary, mirroring `Nomos.Core.Factor` in the Lean library.

This module is the Python side of a two-sided definition.  `check_against_lean`
verifies that the two agree, and the test suite runs it, so the vocabularies
cannot silently drift apart.
"""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass
from typing import Literal

Side = Literal["claimant", "respondent"]


@dataclass(frozen=True)
class FactorDef:
    name: str            # the Lean constructor name
    side: Side
    tag: str             # kebab-case, matches Factor.tag
    gloss: str
    cites: tuple[str, ...] = ()


CLAIMANT: tuple[FactorDef, ...] = (
    FactorDef("harmOccurred", "claimant", "harm-occurred",
              "The claimant suffered an impairment the order recognises."),
    FactorDef("respondentsInstrument", "claimant", "respondents-instrument",
              "The instrument of harm belonged to, or was in the charge of, the respondent.",
              ("LH §251", "Ex 21:29", "m.BK 1:1", "D.9.1.1.2")),
    FactorDef("respondentActedDirectly", "claimant", "acted-directly",
              "The respondent brought about the harm by his own act, not through a thing.",
              ("D.9.2.2pr",)),
    FactorDef("knownVice", "claimant", "known-vice",
              "The dangerous propensity was known.",
              ("Ex 21:29", "D.9.1.1.4", "m.BK 1:4", "LH §251", "LE §54")),
    FactorDef("warned", "claimant", "warned",
              "The respondent had been specifically warned.",
              ("Ex 21:29", "LH §251", "LE §54")),
    FactorDef("noPrecaution", "claimant", "no-precaution",
              "No precaution at all was taken.", ("m.BK 6:1",)),
    FactorDef("withoutLeave", "claimant", "without-leave",
              "Entry onto the claimant's land or use of his thing without leave.",
              ("LH §57", "Ex 22:4")),
    FactorDef("respondentBenefited", "claimant", "respondent-benefited",
              "The respondent stood to gain: the paid bailee, the hirer, the merchant.",
              ("m.BM 7:8", "D.13.6.5.2")),
    FactorDef("harmToPerson", "claimant", "harm-to-person",
              "The harm was to a person rather than to property."),
    FactorDef("professedSkill", "claimant", "professed-skill",
              "The respondent held himself out as having a skill.",
              ("LH §§215-233", "D.19.2")),
    FactorDef("deviationFromTerms", "claimant", "deviation-from-terms",
              "The respondent departed from the terms on which he held the thing."),
    FactorDef("inPublicOrClaimantsGround", "claimant", "public-or-claimants-ground",
              "The harm happened in a public place or on the claimant's own ground.",
              ("m.BK 2:5",)),
    FactorDef("wrongfulTaking", "claimant", "wrongful-taking",
              "The thing was taken or kept against the owner's will."),
    FactorDef("claimantSuperiorInStatus", "claimant", "claimant-superior-in-status",
              "The claimant stood above the respondent in a recognised status, "
              "so the wrong is aggravated.",
              ("XII Tab. 8.3", "Ex 21:32", "LH §§251-252", "TL art. 207",
               "Æthelberht 1-3")),
    FactorDef("respondentHeldOffice", "claimant", "respondent-held-office",
              "The respondent held office and the harm arose in its exercise.",
              ("TL 監臨主守 articles", "DQ.44.00", "D.9.3")),
    FactorDef("intentToHarm", "claimant", "intent-to-harm",
              "The harm was aimed at, not incidental.",
              ("m.BK 1:1 (keren vs shen)", "D.9.2")),
)

RESPONDENT: tuple[FactorDef, ...] = (
    FactorDef("claimantConsented", "respondent", "claimant-consented",
              "The claimant consented, or gave leave.  The paradigm liability-waiver.",
              ("LH §57", "Ex 22:14")),
    FactorDef("properPrecaution", "respondent", "proper-precaution",
              "Adequate precaution was taken.", ("m.BK 6:1",)),
    FactorDef("thirdPartyIntervened", "respondent", "third-party-intervened",
              "A third party's deliberate act intervened.", ("m.BK 6:1",)),
    FactorDef("claimantAtFault", "respondent", "claimant-at-fault",
              "The claimant's own conduct contributed.",
              ("D.9.2.11pr", "D.50.17.203", "D.9.1.1.11")),
    FactorDef("irresistibleForce", "respondent", "irresistible-force",
              "Irresistible force: *vis maior*, *ones*, an act of God."),
    FactorDef("gratuitousService", "respondent", "gratuitous-service",
              "The respondent acted gratuitously, for the claimant's benefit only.",
              ("Ex 22:9-10", "m.BM 7:8", "D.16.3.1.35")),
    FactorDef("behavedAnomalously", "respondent", "behaved-anomalously",
              "The animal or thing behaved out of character.",
              ("m.BK 1:4 (tam)", "D.9.1.1.4")),
    FactorDef("onRespondentsGround", "respondent", "on-respondents-ground",
              "The harm occurred on the respondent's own ground."),
    FactorDef("noticeGiven", "respondent", "notice-given",
              "Notice was given and the claimant could have avoided the harm."),
    FactorDef("customaryPractice", "respondent", "customary-practice",
              "The respondent followed established custom or trade practice."),
    FactorDef("defensive", "respondent", "defensive",
              "The respondent was acting in defence of himself or his property.",
              ("D.9.2.4pr", "TL art. 204 (登時殺傷)")),
    FactorDef("respondentSuperiorInStatus", "respondent", "respondent-superior-in-status",
              "The respondent stood above the claimant in a recognised status, "
              "so the wrong is mitigated or excused.",
              ("XII Tab. 8.3", "LH §252", "TL 良賤 gradations")),
)

ALL: tuple[FactorDef, ...] = CLAIMANT + RESPONDENT
BY_NAME: dict[str, FactorDef] = {f.name: f for f in ALL}
BY_TAG: dict[str, FactorDef] = {f.tag: f for f in ALL}


def side_of(name: str) -> Side:
    return BY_NAME[name].side


def validate(names: list[str]) -> list[str]:
    """Return the names that are not in the vocabulary."""
    return [n for n in names if n not in BY_NAME]


def split_by_side(names: list[str]) -> tuple[list[str], list[str]]:
    pro = [n for n in names if BY_NAME[n].side == "claimant"]
    con = [n for n in names if BY_NAME[n].side == "respondent"]
    return pro, con


# ---------------------------------------------------------------------------
# agreement with the Lean source
# ---------------------------------------------------------------------------

_CTOR = re.compile(r"^\s*\|\s*([a-z][A-Za-z]*)\s*$", re.MULTILINE)


def lean_factor_names(lean_factor_file: str) -> list[str]:
    """Extract the Factor constructors from Nomos/Core/Factor.lean."""
    src = open(lean_factor_file, encoding="utf8").read()
    start = src.index("inductive Factor where")
    end = src.index("deriving", start)
    body = src[start:end]
    return _CTOR.findall(body)


def check_against_lean(lean_factor_file: str) -> tuple[bool, str]:
    lean_names = lean_factor_names(lean_factor_file)
    py_names = [f.name for f in ALL]
    if lean_names == py_names:
        return True, f"vocabularies agree ({len(py_names)} factors, same order)"
    missing = set(lean_names) - set(py_names)
    extra = set(py_names) - set(lean_names)
    msg = []
    if missing:
        msg.append(f"in Lean but not Python: {sorted(missing)}")
    if extra:
        msg.append(f"in Python but not Lean: {sorted(extra)}")
    if not msg:
        msg.append("same members, different order "
                   f"(Lean: {lean_names}, Python: {py_names})")
    return False, "; ".join(msg)
