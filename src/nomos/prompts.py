"""Prompt construction for precedent-guided autoformalisation.

The design principle: **show the model the constraint, not the neighbourhood.**

A conventional retrieval-augmented formaliser shows the model the k most
similar examples and hopes it generalises.  That works for mathematics, where
similar statements really do have similar formalisations.  It works much less
well for law, because the whole point of a legal distinction is that two
superficially similar cases come out differently, and the fact that makes them
differ is often a single word.

So the prompt here is built from the formal apparatus rather than from
similarity.  For a target provision it supplies:

* the **binding precedents** -- cases that already settle this fact pattern, if
  any, with the ratio that binds spelled out;
* the **near misses** -- cases that would bind but for one fact, with that fact
  named.  These are where the model learns what the boundaries are;
* an explicit statement of whether the question is **open**, and if so, that the
  correct output records a gap rather than guessing;
* the **dayyo constraint** -- where the outcome follows a fortiori from a
  lighter case, the remedy is a lower bound and must not be inflated.

The last of those is the one that most needs saying, and is the reason
`Nomos.Reasoning.Analogy.no_strengthening` is in the library.
"""

from __future__ import annotations

import json
from typing import Iterable, Optional

from .analogy import Holding, Retrieved, is_open, retrieve
from .factors import ALL, BY_NAME

SYSTEM = """\
You formalise provisions of historical legal texts into the Nomos Lean library.

Nomos represents a ruling as a `Holding`:

  * `situation` -- the factors the tribunal found present
  * `winner`    -- `claimant` (the party seeking redress) or `respondent`
  * `remedy`    -- what is owed, as a Lean `Remedy` expression
  * `reason`    -- the subset of the WINNER's factors the ruling actually relied on

Three rules govern the output, and they are checked mechanically:

1. Every factor in `reason` must appear in `situation` AND must favour the
   party who won.  A factor that favours the respondent can never be a reason
   for the claimant, however natural that sounds in prose.  (For example
   "the animal was innocuous, so he pays only half" -- `behavedAnomalously`
   favours the RESPONDENT; the claimant's reasons there are the ones that
   survive it, such as `respondentsInstrument`.)

2. Where a provision states a rule and then an exception, formalise the rule as
   one holding and the exception as another.  Do not fold the exception into
   the rule's antecedent.

3. Where the outcome follows a fortiori from a lighter precedent, the remedy
   that follows is a LOWER BOUND, not a value.  If the text does not itself
   state a quantum, use the precedent's own remedy unchanged.  Inflating it is
   an error the Mishnah names *dayyo* and this library proves unsound.

If the provision does not allocate a loss at all -- if it is a definition, a
procedural direction, a rubric, a narrative, or an exhortation -- say so and
return `null` rather than inventing a holding.

Return JSON only, matching this schema:

{"applicable": true|false,
 "restatement": "one neutral sentence saying what the provision holds",
 "situation": ["factorName", ...],
 "winner": "claimant"|"respondent",
 "remedy": "<Lean Remedy expression>",
 "reason": ["factorName", ...],
 "confidence": "high"|"medium"|"low",
 "notes": "anything the formalisation could not capture"}
"""


def factor_glossary() -> str:
    lines = ["FACTOR VOCABULARY (use these names exactly)", ""]
    lines.append("Reasons for the CLAIMANT:")
    for f in ALL:
        if f.side == "claimant":
            cites = f"  [{', '.join(f.cites)}]" if f.cites else ""
            lines.append(f"  {f.name:28s} {f.gloss}{cites}")
    lines.append("")
    lines.append("Reasons for the RESPONDENT:")
    for f in ALL:
        if f.side == "respondent":
            cites = f"  [{', '.join(f.cites)}]" if f.cites else ""
            lines.append(f"  {f.name:28s} {f.gloss}{cites}")
    return "\n".join(lines)


REMEDY_GRAMMAR = """\
REMEDY EXPRESSIONS (valid Lean; compose freely)

  Remedy.exempt                              -- no burden; the loss stays put
  (Remedy.compensate ⟨"the damage"⟩)          -- make good the loss
  (Remedy.compensate ⟨"half the damage"⟩)     -- the Mishnah's ḥatzi nezek; Ex 21:35
  (Remedy.multiple 2 ⟨"the damage"⟩)          -- a statutory double
  (Remedy.tariff ⟨30, ⟨"shekel"⟩⟩)            -- a fixed sum; units do not convert
  (Remedy.inKind "of the best of his field")  -- restitution of a specified quality
  (Remedy.restore ⟨"the ox", ResKind.livestock⟩)
  (Remedy.surrender ⟨"the ox", ResKind.livestock⟩)   -- noxal surrender
  (Remedy.orElse A B)                        -- the BEARER elects between A and B
  (Remedy.both A B)                          -- cumulative
  (Remedy.corporal 3 "stripes")
  Remedy.capital

Units seen in the corpus: shekel, mina, gur, gan, as, sela, zuz, denarius.
Keep the source's own unit.  Never convert one to another: the library treats
quantities in different units as incomparable on purpose.
"""


def render_precedent(r: Retrieved, i: int) -> str:
    h = r.holding
    lines = [
        f"[{i}] {h.cite}   ({h.tradition})   -- {r.kind}",
        f"    why shown: {r.why}",
    ]
    if h.restatement:
        lines.append(f"    holds: {h.restatement}")
    lines += [
        f"    situation: {h.situation}",
        f"    winner:    {h.winner}",
        f"    remedy:    {h.remedy}",
        f"    ratio:     {h.reason}",
    ]
    if r.missing:
        lines.append(f"    distinguished because absent: {r.missing}")
    if r.new_counters:
        lines.append(f"    distinguished by new counter-reason: {r.new_counters}")
    return "\n".join(lines)


def build_prompt(provision: dict, corpus: list[Holding],
                 guess_situation: Optional[list[str]] = None,
                 k: int = 8) -> str:
    """Assemble the user-side prompt for one provision.

    `guess_situation` lets a cheap first pass propose the factors, so the
    precedent retrieval can be done against them.  Without it we fall back to
    lexical retrieval, which is weaker; the two-pass form is the intended use
    and is what `pipeline.formalize` does.
    """
    parts = [factor_glossary(), "", REMEDY_GRAMMAR, ""]

    if guess_situation:
        got = retrieve(corpus, guess_situation, k=k)
        if got:
            parts.append("PRECEDENT ALREADY FORMALISED FOR THIS FACT PATTERN")
            parts.append("")
            for i, r in enumerate(got, 1):
                parts.append(render_precedent(r, i))
                parts.append("")
            binding = [r for r in got if r.kind == "binding"]
            if binding:
                sides = {r.holding.winner for r in binding}
                if len(sides) == 1:
                    side = sides.pop()
                    parts.append(
                        f"NOTE: the existing corpus already FORCES this outcome for "
                        f"the {side} on these facts, via {binding[0].holding.cite}. "
                        f"If your reading of the provision disagrees, say so "
                        f"explicitly in `notes` -- do not quietly contradict it.")
                else:
                    parts.append(
                        "NOTE: the existing corpus forces BOTH outcomes on these "
                        "facts, which means the formalised precedents already "
                        "conflict. Record your reading and flag the conflict in "
                        "`notes`.")
                parts.append("")
            elif is_open(corpus, guess_situation):
                parts.append(
                    "NOTE: nothing in the formalised corpus settles these facts. "
                    "This provision is making new law rather than applying old "
                    "law. Formalise what it says; do not reach for the nearest "
                    "precedent's remedy unless the text itself does.")
                parts.append("")

    src = provision.get("source") or {}
    parts += [
        "PROVISION TO FORMALISE",
        "",
        f"  citation:  {provision.get('citation') or provision.get('canonical')}",
        f"  work:      {provision.get('work')}",
        f"  tradition: {provision.get('tradition')}",
        f"  language:  {provision.get('language')}",
        f"  source:    {src.get('name', '')}",
        "",
        "  text:",
        "  " + (provision.get("text") or "[text not available; formalise from "
                                          "the citation and restatement only]").replace("\n", "\n  "),
        "",
    ]
    if provision.get("restatement"):
        parts.append(f"  editorial restatement: {provision['restatement']}")
        parts.append("")
    parts.append("Return JSON only.")
    return "\n".join(parts)


TRIAGE_SYSTEM = """\
You are triaging provisions of historical legal texts.

For each provision, decide whether it ALLOCATES A LOSS -- that is, whether it
says who must bear, repair or answer for some harm or shortfall.  Rules about
who pays whom, who is exempt, what is owed, and who bears a risk all count.
Definitions, procedural directions, rubrics, lists of officials, narrative,
liturgy and exhortation do not.

If it does allocate a loss, also list the factors present, using ONLY the
vocabulary given.  Be conservative: list a factor only if the text supports it.

Return JSON only:
{"allocates_loss": true|false, "factors": ["factorName", ...],
 "fact_pattern": "FP-GRAZE"|"FP-GORE"|"FP-PIT"|"FP-FIRE"|"FP-BAILMENT"|
                 "FP-BUILD"|"FP-ASSAULT"|"FP-CONSENT"|null,
 "one_line": "what it holds, in one neutral sentence"}
"""


def build_triage_prompt(provision: dict) -> str:
    return "\n".join([
        factor_glossary(),
        "",
        "PROVISION",
        f"  citation:  {provision.get('citation') or provision.get('canonical')}",
        f"  work:      {provision.get('work')}",
        f"  language:  {provision.get('language')}",
        "",
        "  text:",
        "  " + (provision.get("text") or "").replace("\n", "\n  "),
        "",
        "Return JSON only.",
    ])


REPAIR_SYSTEM = """\
A formalisation you produced failed verification.  Fix it.

You will be given the original provision, your previous JSON, and the exact
errors.  Common causes:

 * a factor in `reason` favours the other side, or is not in `situation`;
 * a factor name that does not exist (check spelling against the vocabulary);
 * a malformed Lean remedy expression (check the grammar, including the
   corner brackets ⟨ ⟩ around records);
 * the holding contradicts precedent already in the corpus -- if you believe
   the source really does contradict it, keep your reading and explain in
   `notes`; otherwise revise.

Return corrected JSON only, in the same schema.
"""


def build_repair_prompt(provision: dict, previous: dict,
                        errors: list[str], diagnostics: dict) -> str:
    return "\n".join([
        factor_glossary(),
        "",
        REMEDY_GRAMMAR,
        "",
        "PROVISION",
        f"  citation: {provision.get('citation') or provision.get('canonical')}",
        "  text:",
        "  " + (provision.get("text") or "").replace("\n", "\n  "),
        "",
        "YOUR PREVIOUS ANSWER",
        json.dumps(previous, indent=2, ensure_ascii=False),
        "",
        "ERRORS",
        *[f"  - {e}" for e in errors],
        "",
        ("CONFLICTS WITH EXISTING PRECEDENT\n" +
         "\n".join(f"  - claimant: {c['claimant']}  vs  respondent: {c['respondent']}"
                   for c in diagnostics.get("conflicts", []))
         if diagnostics.get("conflicts") else ""),
        "",
        "Return corrected JSON only.",
    ])
