"""Parse the Sefaria export into addressable provisions.

Why this corpus matters more than its size suggests.  Almost every ancient
legal collection survives as a bare list of rulings: Hammurabi tells you that
a shepherd who grazes his flock on another's field pays so much grain, and
stops.  The reasoning that produced the rule is gone.  The rabbinic corpus is
the one large ancient body of law that preserves *both* layers -- a terse code
(the Mishnah) and a sustained record of argument about it (the Talmud) -- and
the arguments are overwhelmingly analogical.  Mishnah Bava Kamma opens by
naming four paradigm cases of liability, distinguishing them pairwise, and
then extracting what they have in common in order to license extension to
unnamed cases.  That is, almost exactly, factor-based precedential constraint
in the sense of Horty & Bench-Capon (2012), written down around 200 CE.

Licensing: Sefaria versions carry individual licenses.  We record the license
on every provision.  The William Davidson Talmud is CC-BY-NC, so anything
derived from it inherits a non-commercial restriction; `harvest(..., allow_nc=
False)` drops those texts.

Source snapshot: https://github.com/Sefaria/Sefaria-Export-Archive at commit
1af9cdcb (2020-07-08), the last export that shipped text in-repo.
"""

from __future__ import annotations

import json
import os
import re
from typing import Any, Iterator

from ..schema import Provision, Source, strip_tags

SEFARIA_URL = "https://github.com/Sefaria/Sefaria-Export-Archive"

# Rough composition dates, used only for ordering the corpus chronologically.
ERAS: dict[str, tuple[int, int]] = {
    "Exodus": (-1200, -500),
    "Leviticus": (-1200, -500),
    "Deuteronomy": (-1200, -500),
    "Mishnah": (10, 220),
    "Tosefta": (200, 300),
    "Bavli": (200, 600),
    "Mishneh Torah": (1170, 1180),
    "Shulchan Arukh": (1563, 1565),
}


def _era_for(path_parts: list[str]) -> tuple[int, int] | None:
    for part in path_parts:
        for k, v in ERAS.items():
            if k in part:
                return v
    return None


def _daf(idx: int) -> str:
    """Sefaria indexes Talmud by array position: 2 -> 2a, 3 -> 2b, 4 -> 3a."""
    return f"{idx // 2 + 1}{'a' if idx % 2 == 0 else 'b'}"


def _walk(node: Any, prefix: list[str]) -> Iterator[tuple[list[str], str]]:
    if isinstance(node, str):
        yield prefix, node
    elif isinstance(node, list):
        for i, child in enumerate(node):
            yield from _walk(child, prefix + [str(i)])


def parse_version(path: str, tradition: str = "rabbinic") -> Iterator[Provision]:
    with open(path, encoding="utf8") as fh:
        doc = json.load(fh)

    title = doc.get("title") or os.path.basename(os.path.dirname(os.path.dirname(path)))
    version = doc.get("versionTitle") or "unknown"
    lic = doc.get("license") or "unspecified"
    lang = doc.get("language") or "en"
    sec_names = doc.get("sectionNames") or []
    text = doc.get("text")
    if not text:
        return

    rel = os.path.relpath(path).split(os.sep)
    era = _era_for(rel + [title])
    is_talmud = bool(sec_names) and sec_names[0].lower() == "daf"

    src = Source(
        name=f"Sefaria: {title} ({version})",
        url=SEFARIA_URL,
        license=lic,
        availability="included",
        note=doc.get("versionSource", ""),
    )

    work_slug = re.sub(r"[^a-z0-9]+", "_", title.lower()).strip("_")
    ver_slug = re.sub(r"[^a-z0-9]+", "_", version.lower()).strip("_")[:28]

    for idx_path, raw in _walk(text, []):
        body = strip_tags(raw)
        if len(body) < 12:
            continue
        nums = [int(x) for x in idx_path]
        if is_talmud:
            if nums[0] < 2:
                continue
            head = _daf(nums[0])
            rest = [str(n + 1) for n in nums[1:]]
            cite = f"{title} {head}" + (":" + ".".join(rest) if rest else "")
            addr = [head] + rest
        else:
            addr = [str(n + 1) for n in nums]
            cite = f"{title} {':'.join(addr)}"

        pid = f"{tradition}.{work_slug}.{'.'.join(addr)}.{lang}.{ver_slug}"
        yield Provision(
            id=pid,
            tradition=tradition,
            work=title,
            citation=cite,
            canonical=f"{title} {':'.join(addr)}",
            language=lang,
            text=body,
            source=src,
            era=era,
            path=addr,
            kind="commentary" if "Talmud" in rel or is_talmud else "provision",
            meta={"version": version, "sectionNames": sec_names},
        )


# Sefaria's per-directory version files vary wildly in completeness and in
# licensing, and the "English" directory sometimes holds French, German and
# Polish translations.  We therefore pick a version by an explicit policy
# rather than by filename, preferring (a) the most permissive licence and
# (b) the most complete text.
LICENSE_RANK = {
    "public domain": 0, "publicdomain": 0, "cc0": 0,
    "cc-by": 1, "ccby": 1, "cc-by-sa": 2,
    "cc-by-nc": 5, "cc-by-nc-sa": 6,
    "unspecified": 8, "none": 9, "": 9,
}

# Language-tagged filenames such as "Bible du Rabbinat 1899 [fr].json" are
# misfiled translations; drop anything tagged with a non-English code.
LANG_TAG = re.compile(r"\[(?!en\b)[a-z]{2}(?:-[a-z]{2})?\]", re.IGNORECASE)

NC_MARKERS = ("nc", "noncommercial", "non-commercial")

# A candidate translation must cover at least this fraction of the fullest
# available translation of the same work to be considered at all.
COMPLETENESS_FLOOR = 0.6

# A small allow-list of translations whose provenance we have checked and
# which we want even when a more permissive but less usable option exists.
TIEBREAK_BONUS = {
    "Mishnah Yomit by Dr. Joshua Kulp": -1,
    "William Davidson Edition - English": -1,
    "The Holy Scriptures A New Translation JPS 1917": -1,
}


def _is_nc(lic: str) -> bool:
    l = (lic or "").lower().replace(" ", "")
    return any(m in l for m in NC_MARKERS)


def _license_rank(lic: str) -> int:
    key = (lic or "").strip().lower()
    if key in LICENSE_RANK:
        return LICENSE_RANK[key]
    for k, v in LICENSE_RANK.items():
        if k and k in key.replace(" ", ""):
            return v
    return 7


def _count_units(node: Any) -> int:
    if isinstance(node, str):
        return 1 if len(node.strip()) >= 12 else 0
    if isinstance(node, list):
        return sum(_count_units(c) for c in node)
    return 0


def harvest(root: str, languages=("en",), allow_nc: bool = True,
            max_versions_per_work: int = 1) -> Iterator[Provision]:
    """root = data/raw/sefaria"""
    for dirpath, _dirs, files in os.walk(root):
        lang_dir = os.path.basename(dirpath)
        if lang_dir not in ("English", "Hebrew"):
            continue
        lang = "en" if lang_dir == "English" else "he"
        if lang not in languages:
            continue

        cands: list[tuple[int, int, str, str]] = []   # units, lic_rank, stem, path
        for fn in files:
            if not fn.endswith(".json") or LANG_TAG.search(fn):
                continue
            path = os.path.join(dirpath, fn)
            try:
                with open(path, encoding="utf8") as fh:
                    doc = json.load(fh)
            except Exception:
                continue
            lic = doc.get("license") or "unspecified"
            # When the caller wants a redistributable-for-any-purpose subset,
            # an unstated licence is not good enough: "merged" files in
            # particular drop version-level licensing and silently mix in
            # NC-licensed translations.
            if not allow_nc and (_is_nc(lic) or _license_rank(lic) > 2):
                continue
            units = _count_units(doc.get("text") or [])
            if units == 0:
                continue
            stem = fn[:-5]
            cands.append((units, _license_rank(lic) + TIEBREAK_BONUS.get(stem, 0),
                          stem, path))
        if not cands:
            continue

        # Completeness dominates.  A permissively-licensed translation that
        # covers 7% of the tractate is not a usable substitute for one that
        # covers all of it, so we first keep only the substantially-complete
        # candidates and only then prefer the most permissive licence.
        best_units = max(c[0] for c in cands)
        viable = [c for c in cands if c[0] >= COMPLETENESS_FLOOR * best_units]
        viable.sort(key=lambda c: (1 if c[2] == "merged" else 0, c[1], -c[0], c[2]))
        for _u, _l, _stem, path in viable[:max_versions_per_work]:
            yield from parse_version(path)
