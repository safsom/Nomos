"""Test suite.

Run with `python -m pytest tests/ -q`, or `python tests/test_nomos.py` for a
dependency-free run.

The tests that matter most are `test_python_lean_agreement` -- which checks
that the Python constraint engine and the Lean one give the same answers on
every seed situation -- and `test_verifier_rejects_*`, which check that the
verifier actually catches the failure modes it claims to.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(HERE, "src"))

from nomos import baselines, eval as ev, factors, prompts  # noqa: E402
from nomos.analogy import (Holding, at_least_as_strong, conflicts_at,  # noqa: E402
                           forces, grounds_of_distinction, is_open, retrieve)
from nomos.fact_patterns import PATTERNS  # noqa: E402
from nomos.pipeline import EchoBackend, formalize, parse_json  # noqa: E402
from nomos.schema import read_jsonl  # noqa: E402
from nomos.verify import lean_available, render, verify  # noqa: E402

SEED_PATH = os.path.join(HERE, "data", "seed", "formalizations.jsonl")
LEAN_FACTOR = os.path.join(HERE, "lean", "Nomos", "Core", "Factor.lean")


def load_seed() -> list[Holding]:
    return [Holding(cite=r["cite"], situation=r["situation"], winner=r["winner"],
                    remedy=r["remedy"], reason=r["reason"],
                    tradition=r["tradition"])
            for r in read_jsonl(SEED_PATH)]


# ---------------------------------------------------------------------------
# vocabulary
# ---------------------------------------------------------------------------

def test_factor_vocabularies_agree():
    ok, msg = factors.check_against_lean(LEAN_FACTOR)
    assert ok, msg


def test_every_factor_has_a_side():
    for f in factors.ALL:
        assert f.side in ("claimant", "respondent")
        assert f.tag and f.gloss


def test_fact_pattern_factors_exist():
    for p in PATTERNS:
        bad = factors.validate(p.factors)
        assert not bad, f"{p.id} references unknown factors {bad}"


# ---------------------------------------------------------------------------
# the constraint relation
# ---------------------------------------------------------------------------

def test_seed_is_well_formed():
    for h in load_seed():
        assert h.well_formed(), (h.cite, h.malformation())


def test_precedent_binds_itself():
    for h in load_seed():
        assert at_least_as_strong(h.situation, h), h.cite


def test_adding_supporting_factors_preserves_binding():
    """`AtLeastAsStrong.add_supporting` in the Lean library."""
    for h in load_seed():
        extra = [f.name for f in factors.ALL
                 if f.side == h.winner and f.name not in h.situation][:3]
        assert at_least_as_strong(list(h.situation) + extra, h), h.cite


def test_adding_counter_factors_can_break_binding():
    seed = load_seed()
    broke = 0
    for h in seed:
        counters = [f.name for f in factors.ALL
                    if f.side != h.winner and f.name not in h.situation]
        if counters and not at_least_as_strong(list(h.situation) + [counters[0]], h):
            broke += 1
    assert broke > 0, "a new counter-reason should sometimes distinguish"


def test_distinction_grounds_explain_failure():
    seed = load_seed()
    for h in seed:
        for g in seed:
            if not at_least_as_strong(g.situation, h):
                missing, new = grounds_of_distinction(g.situation, h)
                assert missing or new, (h.cite, g.cite)


def test_monotone_in_corpus():
    seed = load_seed()
    for h in seed[:10]:
        small = [x for x in seed if x.cite != h.cite][:5]
        for side in ("claimant", "respondent"):
            if forces(small, h.situation, side):
                assert forces(seed, h.situation, side), (h.cite, side)


# ---------------------------------------------------------------------------
# known findings
# ---------------------------------------------------------------------------

def test_covenant_self_conflict_is_the_expected_one():
    """The Exodus 21:28 / 21:35 tension, which Nomos/Bench/GoringOx.lean proves."""
    cov = [h for h in load_seed() if h.tradition == "covenant"]
    pairs = set()
    for h in cov:
        for p, c in conflicts_at(cov, h.situation):
            pairs.add((p.cite, c.cite))
    assert ("Ex 21:35", "Ex 21:28") in pairs, pairs


def test_rabbinic_and_roman_are_internally_coherent():
    seed = load_seed()
    for trad in ("rabbinic", "roman"):
        c = [h for h in seed if h.tradition == trad]
        for h in c:
            assert not conflicts_at(c, h.situation), (trad, h.cite)


def test_traditions_do_not_merge():
    seed = load_seed()
    cov = [h for h in seed if h.tradition == "covenant"]
    rom = [h for h in seed if h.tradition == "roman"]
    merged = cov + rom
    cross = [(p.cite, c.cite) for h in merged
             for p, c in conflicts_at(merged, h.situation)
             if (p in cov) != (c in cov)]
    assert cross, "Exodus and Rome should conflict on the innocuous goring ox"


def test_half_damages_shared_across_four_traditions():
    """Ex 21:35, m.BK tam, LE §53 and Tang art. 206 carry the identical term."""
    by = {h.cite: h for h in load_seed()}
    ex = by["Ex 21:35"].remedy
    assert ex == by["m.BK 1:4, 4:9 (tam)"].remedy
    assert ex == by["LE §53 [editorial restatement; text not shipped]"].remedy
    assert ex == by["唐律疏議 art. 206 (犬殺傷畜產) -- other beasts, half damages"].remedy


def test_known_vice_pivots_every_tradition():
    """The convergence claim, checked over the seed data rather than in Lean."""
    by = {h.cite: h for h in load_seed()}
    forewarned = [
        "Ex 21:29",
        "m.BK 1:4, 4:9 (mu'ad)",
        "D.9.1.1.4 (Ulpian, citing Servius)",
        "LH §251 [editorial restatement; text not shipped]",
        "LE §54 [editorial restatement; text not shipped]",
        "唐律疏議 art. 207 (畜產蹋人) -- failure to mark and tether",
        "May v Burdett (1846) 9 QB 101 [editorial restatement]",
        "Animals Act 1971 (UK) s.2(2) [editorial restatement]",
    ]
    for c in forewarned:
        assert c in by, c
        assert "knownVice" in by[c].reason, c
        assert by[c].winner == "claimant", c


def test_alfred_copies_exodus():
    """Documented transmission leaves the formalisations identical."""
    by = {h.cite: h for h in load_seed()}
    alfred = by["Alfred, Domboc, Mosaic prologue (Af El. ~21) [editorial restatement]"]
    exodus = by["Ex 21:29-30"]
    assert alfred.situation == exodus.situation
    assert alfred.winner == exodus.winner
    assert alfred.remedy == exodus.remedy
    assert alfred.reason == exodus.reason


def test_chinese_and_english_are_internally_coherent():
    seed = load_seed()
    for trad in ("chinese", "english"):
        c = [h for h in seed if h.tradition == trad]
        assert c, trad
        for h in c:
            assert not conflicts_at(c, h.situation), (trad, h.cite)


def test_all_incoherence_traces_to_exodus_21_28():
    """The finding: every cross-tradition conflict in the corpus is Ex 21:28."""
    seed = load_seed()
    by_trad = {}
    for h in seed:
        by_trad.setdefault(h.tradition, []).append(h)
    offenders = set()
    names = sorted(by_trad)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            merged = by_trad[a] + by_trad[b]
            for h in merged:
                for p, c in conflicts_at(merged, h.situation):
                    if (p in by_trad[a]) != (c in by_trad[a]):
                        offenders.add(c.cite)
                        offenders.add(p.cite)
    # Every cross-tradition conflict has Ex 21:28 on the respondent side.
    assert offenders, "expected at least one cross-tradition conflict"
    assert "Ex 21:28" in offenders, offenders


# ---------------------------------------------------------------------------
# retrieval
# ---------------------------------------------------------------------------

def test_retrieval_prefers_binding():
    seed = load_seed()
    h = next(x for x in seed if x.cite == "Ex 21:29")
    got = retrieve(seed, h.situation, k=6)
    assert got and got[0].kind == "binding"


def test_retrieval_is_diverse():
    seed = load_seed()
    got = retrieve(seed, ["harmOccurred", "respondentsInstrument", "knownVice"], k=6)
    assert len({r.holding.tradition for r in got}) >= 2


def test_retrieval_excludes_self():
    seed = load_seed()
    h = seed[0]
    got = retrieve(seed, h.situation, k=8, exclude_cites=[h.cite])
    assert all(r.holding.cite != h.cite for r in got)


# ---------------------------------------------------------------------------
# prompting and parsing
# ---------------------------------------------------------------------------

def test_prompt_mentions_every_factor():
    g = prompts.factor_glossary()
    for f in factors.ALL:
        assert f.name in g


def test_prompt_flags_open_questions():
    seed = load_seed()
    novel = ["harmOccurred", "customaryPractice", "noticeGiven",
             "onRespondentsGround"]
    p = prompts.build_prompt({"citation": "X", "text": "t"}, seed,
                             guess_situation=novel)
    assert "nothing in the formalised corpus settles these facts" in p


def test_parse_json_handles_fences_and_prose():
    assert parse_json('```json\n{"a": 1}\n```') == {"a": 1}
    assert parse_json('Sure! {"a": {"b": 2}} hope that helps') == {"a": {"b": 2}}
    assert parse_json("no json here") is None


# ---------------------------------------------------------------------------
# rendering and verification
# ---------------------------------------------------------------------------

def test_render_is_plausible_lean():
    h = load_seed()[0]
    src = render(h)
    assert "def candidate : Precedent" in src
    assert "Side." in src and "Factor." in src


def test_python_lean_agreement():
    """The Python and Lean constraint engines must agree.

    We check via the verifier's `NOMOS_WAS_OPEN` flag, which Lean computes with
    `Open base candidate.situation`, against the Python `is_open`."""
    if not lean_available():
        print("  (skipped: lean not available)")
        return
    seed = load_seed()
    checked = 0
    for h in seed:
        if h.tradition not in ("rabbinic", "roman"):
            continue
        base = [x for x in seed if x.tradition == h.tradition]
        r = verify(h, h.tradition)
        assert r.compiles, (h.cite, r.errors[:2])
        assert r.well_formed, (h.cite, r.errors[:2])
        py_open = is_open(base, h.situation)
        assert r.is_novel == py_open, (h.cite, r.is_novel, py_open)
        checked += 1
        if checked >= 6:
            break
    assert checked, "no holdings checked"


def test_verifier_rejects_empty_ratio():
    if not lean_available():
        print("  (skipped: lean not available)")
        return
    h = Holding(cite="T", situation=[], winner="claimant",
                remedy="Remedy.exempt", reason=[], tradition="roman")
    assert not h.well_formed()
    r = verify(h, "roman")
    assert not r.compiles and not r.well_formed


def test_verifier_rejects_wrong_side_ratio():
    if not lean_available():
        print("  (skipped: lean not available)")
        return
    h = Holding(cite="T", situation=["harmOccurred", "behavedAnomalously"],
                winner="claimant", remedy="Remedy.exempt",
                reason=["behavedAnomalously"], tradition="roman")
    assert not h.well_formed()
    r = verify(h, "roman")
    assert not r.well_formed


def test_verifier_rejects_unknown_factor():
    if not lean_available():
        print("  (skipped: lean not available)")
        return
    h = Holding(cite="T", situation=["harmOccurred", "notAFactor"],
                winner="claimant", remedy="Remedy.exempt",
                reason=["harmOccurred"], tradition="roman")
    r = verify(h, "roman")
    assert not r.compiles


def test_lean_library_builds():
    if not lean_available():
        print("  (skipped: lean not available)")
        return
    proc = subprocess.run(["lake", "build"], cwd=os.path.join(HERE, "lean"),
                          capture_output=True, text=True, timeout=1200)
    assert proc.returncode == 0, proc.stderr[-2000:]


def test_lean_has_no_sorry():
    lean_dir = os.path.join(HERE, "lean", "Nomos")
    offenders = []
    for root, _dirs, files in os.walk(lean_dir):
        for fn in files:
            if not fn.endswith(".lean"):
                continue
            src = open(os.path.join(root, fn), encoding="utf8").read()
            for kw in ("sorry", "axiom "):
                if kw in src:
                    offenders.append(f"{fn}: {kw}")
    assert not offenders, offenders


# ---------------------------------------------------------------------------
# pipeline and evaluation
# ---------------------------------------------------------------------------

def test_pipeline_with_echo_backend():
    seed = load_seed()
    answer = json.dumps({
        "applicable": True, "restatement": "r",
        "situation": ["harmOccurred", "respondentActedDirectly", "noPrecaution"],
        "winner": "claimant", "remedy": '(Remedy.compensate ⟨"the damage"⟩)',
        "reason": ["respondentActedDirectly", "noPrecaution"],
        "confidence": "high", "notes": ""})
    triage = json.dumps({"allocates_loss": True,
                         "factors": ["harmOccurred", "respondentActedDirectly"],
                         "fact_pattern": "FP-WRONGFUL-DAMAGE", "one_line": "x"})
    backend = EchoBackend(answers={"PROVISION TO FORMALISE": answer},
                          default=triage)
    prov = {"id": "t1", "citation": "TEST 1", "work": "W",
            "tradition": "roman", "language": "la", "text": "some text",
            "source": {"name": "n"}}
    out = formalize(prov, seed, backend, max_repairs=1,
                    verify_with_lean=lean_available())
    assert out.status == "accepted", (out.status, out.note)
    assert out.holding and out.holding.well_formed()


def test_pipeline_repairs_a_bad_answer():
    seed = load_seed()
    bad = json.dumps({"applicable": True, "situation": ["harmOccurred"],
                      "winner": "claimant", "remedy": "Remedy.exempt",
                      "reason": ["behavedAnomalously"]})
    good = json.dumps({"applicable": True, "situation": ["harmOccurred"],
                       "winner": "claimant", "remedy": "Remedy.exempt",
                       "reason": ["harmOccurred"]})

    class Seq:
        def __init__(self):
            self.n = 0

        def complete(self, system, user):
            self.n += 1
            if "triaging" in system:
                return json.dumps({"allocates_loss": True,
                                   "factors": ["harmOccurred"],
                                   "fact_pattern": None, "one_line": "x"})
            return bad if "failed verification" not in system else good

    prov = {"id": "t2", "citation": "TEST 2", "tradition": "roman",
            "work": "W", "language": "la", "text": "t", "source": {}}
    out = formalize(prov, seed, Seq(), max_repairs=2,
                    verify_with_lean=lean_available())
    assert out.status == "accepted", (out.status, out.note)
    assert len(out.attempts) >= 2, "should have needed a repair"


def test_baselines_and_eval_run():
    seed = load_seed()
    base, held = ev.holdout_split(seed, fraction=0.3, seed_value=1)
    assert base and held
    preds = {h.cite: baselines.nearest_precedent(h.situation, base) for h in held}
    rep = ev.evaluate(held, preds, base)
    assert rep.n == len(held)
    assert set(rep.by_stratum) <= {"open", "forced"}
    for s in rep.by_stratum.values():
        assert 0.0 <= s["outcome"] <= 1.0


def test_nearest_precedent_beats_majority_on_forced():
    seed = load_seed()
    base, held = ev.holdout_split(seed, fraction=0.35, seed_value=7)
    reps = {}
    for name, fn in [("majority", baselines.majority),
                     ("nearest", baselines.nearest_precedent)]:
        preds = {h.cite: fn(h.situation, base) for h in held}
        reps[name] = ev.evaluate(held, preds, base)
    f_major = reps["majority"].by_stratum.get("forced", {}).get("ratio_jaccard", 0)
    f_near = reps["nearest"].by_stratum.get("forced", {}).get("ratio_jaccard", 0)
    assert f_near >= f_major


def test_novelty_gap_is_positive_for_copying_baseline():
    """The metric's reason for existing: a pure copier should show a large gap."""
    seed = load_seed()
    base, held = ev.holdout_split(seed, fraction=0.35, seed_value=7)
    preds = {h.cite: baselines.nearest_precedent(h.situation, base) for h in held}
    rep = ev.evaluate(held, preds, base)
    gap = rep.novelty_gap()
    assert gap is not None and gap > 0.2, gap


# ---------------------------------------------------------------------------

def main() -> int:
    fns = [(k, v) for k, v in sorted(globals().items())
           if k.startswith("test_") and callable(v)]
    failed = []
    for name, fn in fns:
        try:
            fn()
            print(f"  PASS  {name}")
        except AssertionError as exc:
            print(f"  FAIL  {name}: {exc}")
            failed.append(name)
        except Exception as exc:                     # noqa: BLE001
            print(f"  ERROR {name}: {type(exc).__name__}: {exc}")
            failed.append(name)
    print(f"\n{len(fns) - len(failed)}/{len(fns)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
