"""The autoformalisation loop.

    provision text
        │
        ├─ triage ──────────► does this allocate a loss?  which factors?
        │                     (cheap pass; also gives the retrieval key)
        │
        ├─ retrieve ────────► binding precedents and near misses, chosen by
        │                     constraint distance (see analogy.retrieve)
        │
        ├─ formalise ───────► candidate Holding as JSON
        │
        ├─ verify ──────────► Lean: compiles?  well-formed?  coherent?
        │                     (see verify.py)
        │
        └─ repair ──────────► on failure, hand the model its own errors
                              and the conflicting precedents, up to N times

Accepted candidates are appended to the case base, so later provisions are
formalised against a corpus that includes the earlier ones.  That ordering is
not an implementation convenience: it is the mechanism.  A legal order builds
itself the same way, and the reason the corpus is processed
tradition-by-tradition in rough chronological order is that this lets the
precedent machinery do real work rather than starting cold at every provision.

## Models

`pipeline` does not depend on any particular model API.  A backend is anything
with `.complete(system, user) -> str`.  Four are provided; `EchoBackend` needs
no network and exists so the tests and the notebook run anywhere.
"""

from __future__ import annotations

import json
import os
import re
import time
from dataclasses import dataclass, field
from typing import Callable, Iterable, Optional, Protocol

from .analogy import Holding, is_open, retrieve
from .factors import BY_NAME, validate
from . import prompts
from .verify import VerifyResult, verify


class Backend(Protocol):
    def complete(self, system: str, user: str) -> str: ...


# ---------------------------------------------------------------------------
# backends
# ---------------------------------------------------------------------------

class EchoBackend:
    """A backend that returns canned answers.  Used by the tests and by the
    notebook when no API key is present, so the whole pipeline is runnable
    offline and its shape is inspectable without spending anything."""

    def __init__(self, answers: Optional[dict[str, str]] = None,
                 default: str = '{"applicable": false, "notes": "echo backend"}'):
        self.answers = answers or {}
        self.default = default
        self.calls: list[tuple[str, str]] = []

    def complete(self, system: str, user: str) -> str:
        self.calls.append((system, user))
        for key, val in self.answers.items():
            if key in user:
                return val
        return self.default


class AnthropicBackend:
    def __init__(self, model: str = "claude-sonnet-4-5", max_tokens: int = 2048,
                 api_key: Optional[str] = None):
        import anthropic  # noqa: F401  (imported lazily on purpose)
        self.client = anthropic.Anthropic(api_key=api_key or os.environ.get("ANTHROPIC_API_KEY"))
        self.model, self.max_tokens = model, max_tokens

    def complete(self, system: str, user: str) -> str:
        r = self.client.messages.create(
            model=self.model, max_tokens=self.max_tokens, system=system,
            messages=[{"role": "user", "content": user}])
        return "".join(b.text for b in r.content if getattr(b, "type", "") == "text")


class OpenAIBackend:
    def __init__(self, model: str = "gpt-4o-mini", api_key: Optional[str] = None):
        import openai  # noqa: F401
        self.client = openai.OpenAI(api_key=api_key or os.environ.get("OPENAI_API_KEY"))
        self.model = model

    def complete(self, system: str, user: str) -> str:
        r = self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "system", "content": system},
                      {"role": "user", "content": user}])
        return r.choices[0].message.content or ""


class HFBackend:
    """A local transformers backend, for the fine-tuned model."""

    def __init__(self, model_id: str, max_new_tokens: int = 1024, device: str = "auto"):
        from transformers import AutoModelForCausalLM, AutoTokenizer  # noqa
        import torch  # noqa
        self.tok = AutoTokenizer.from_pretrained(model_id)
        self.model = AutoModelForCausalLM.from_pretrained(
            model_id, device_map=device, torch_dtype="auto")
        self.max_new_tokens = max_new_tokens

    def complete(self, system: str, user: str) -> str:
        msgs = [{"role": "system", "content": system},
                {"role": "user", "content": user}]
        text = self.tok.apply_chat_template(msgs, tokenize=False,
                                            add_generation_prompt=True)
        ids = self.tok(text, return_tensors="pt").to(self.model.device)
        out = self.model.generate(**ids, max_new_tokens=self.max_new_tokens,
                                  do_sample=False)
        return self.tok.decode(out[0][ids["input_ids"].shape[1]:],
                               skip_special_tokens=True)


# ---------------------------------------------------------------------------
# json extraction
# ---------------------------------------------------------------------------

_FENCE = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL)


def parse_json(text: str) -> Optional[dict]:
    text = (text or "").strip()
    m = _FENCE.search(text)
    if m:
        text = m.group(1).strip()
    start = text.find("{")
    if start < 0:
        return None
    depth, in_str, esc = 0, False, False
    for i in range(start, len(text)):
        c = text[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            continue
        if c == '"':
            in_str = True
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(text[start:i + 1])
                except json.JSONDecodeError:
                    return None
    return None


# ---------------------------------------------------------------------------
# the loop
# ---------------------------------------------------------------------------

@dataclass
class Attempt:
    stage: str
    raw: str
    parsed: Optional[dict]
    result: Optional[VerifyResult] = None


@dataclass
class Outcome:
    provision_id: str
    citation: str
    status: str                       # accepted | rejected | not-applicable | error
    holding: Optional[Holding] = None
    verification: Optional[VerifyResult] = None
    triage: Optional[dict] = None
    attempts: list[Attempt] = field(default_factory=list)
    retrieved: list[str] = field(default_factory=list)
    seconds: float = 0.0
    note: str = ""

    def to_json(self) -> dict:
        v = self.verification
        return {
            "provision_id": self.provision_id, "citation": self.citation,
            "status": self.status,
            "holding": self.holding.to_json() if self.holding else None,
            "triage": self.triage,
            "retrieved": self.retrieved,
            "verification": None if not v else {
                "compiles": v.compiles, "well_formed": v.well_formed,
                "coheres": v.coheres, "novel": v.is_novel,
                "forced_before": v.forces_outcome,
                "errors": v.errors, "conflicts": v.diagnostics.get("conflicts", []),
            },
            "attempts": len(self.attempts), "seconds": round(self.seconds, 2),
            "note": self.note,
        }


def _clean_factors(names: Iterable[str]) -> list[str]:
    seen, out = set(), []
    for n in names or []:
        n = str(n).strip()
        if n in BY_NAME and n not in seen:
            seen.add(n)
            out.append(n)
    return out


def triage(provision: dict, backend: Backend) -> Optional[dict]:
    raw = backend.complete(prompts.TRIAGE_SYSTEM,
                           prompts.build_triage_prompt(provision))
    d = parse_json(raw)
    if not d:
        return None
    d["factors"] = _clean_factors(d.get("factors") or [])
    return d


def formalize(provision: dict, corpus: list[Holding], backend: Backend,
              max_repairs: int = 2, verify_with_lean: bool = True,
              do_triage: bool = True) -> Outcome:
    t0 = time.time()
    pid = provision.get("id", "")
    cite = provision.get("citation") or provision.get("canonical") or pid
    out = Outcome(provision_id=pid, citation=cite, status="error")

    tri = triage(provision, backend) if do_triage else None
    out.triage = tri
    if tri is not None and tri.get("allocates_loss") is False:
        out.status = "not-applicable"
        out.note = tri.get("one_line", "")
        out.seconds = time.time() - t0
        return out

    guess = (tri or {}).get("factors") or None
    if guess:
        out.retrieved = [r.holding.cite for r in retrieve(corpus, guess, k=8)]

    user = prompts.build_prompt(provision, corpus, guess_situation=guess)
    raw = backend.complete(prompts.SYSTEM, user)
    parsed = parse_json(raw)
    out.attempts.append(Attempt("formalize", raw, parsed))

    for attempt in range(max_repairs + 1):
        if not parsed:
            errors = ["response was not valid JSON"]
            vres = None
        elif parsed.get("applicable") is False:
            out.status = "not-applicable"
            out.note = parsed.get("notes", "")
            out.seconds = time.time() - t0
            return out
        else:
            sit = _clean_factors(parsed.get("situation"))
            rsn = _clean_factors(parsed.get("reason"))
            bad = validate(list(parsed.get("situation") or [])
                           + list(parsed.get("reason") or []))
            h = Holding(
                cite=cite, situation=sit,
                winner=("respondent" if parsed.get("winner") == "respondent"
                        else "claimant"),
                remedy=parsed.get("remedy") or "Remedy.exempt",
                reason=rsn, tradition=provision.get("tradition", ""),
                provision_id=pid, restatement=parsed.get("restatement", ""),
                confidence=parsed.get("confidence", "medium"),
            )
            if verify_with_lean:
                vres = verify(h, provision.get("tradition"))
            else:
                vres = VerifyResult(True, h.well_formed(), None, None,
                                    is_open(corpus, h.situation),
                                    h.malformation())
            out.attempts[-1].result = vres
            errors = list(vres.errors)
            if bad:
                errors.append(f"unknown factor names: {bad}")
            if vres.ok and not bad:
                out.holding = h
                out.verification = vres
                out.status = "accepted"
                out.seconds = time.time() - t0
                return out

        if attempt >= max_repairs:
            break
        repair_user = prompts.build_repair_prompt(
            provision, parsed or {}, errors,
            (vres.diagnostics if vres else {}))
        raw = backend.complete(prompts.REPAIR_SYSTEM, repair_user)
        parsed = parse_json(raw)
        out.attempts.append(Attempt(f"repair-{attempt + 1}", raw, parsed))

    out.status = "rejected"
    out.verification = out.attempts[-1].result
    out.note = "; ".join(errors)[:500] if errors else ""
    out.seconds = time.time() - t0
    return out


def run(provisions: list[dict], corpus: list[Holding], backend: Backend,
        max_repairs: int = 2, verify_with_lean: bool = True,
        grow_corpus: bool = True,
        on_result: Optional[Callable[[Outcome], None]] = None) -> list[Outcome]:
    """Formalise a list of provisions, growing the case base as we go."""
    working = list(corpus)
    results: list[Outcome] = []
    for p in provisions:
        o = formalize(p, working, backend, max_repairs, verify_with_lean)
        results.append(o)
        if on_result:
            on_result(o)
        if grow_corpus and o.status == "accepted" and o.holding:
            working.append(o.holding)
    return results
