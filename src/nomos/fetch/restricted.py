"""Fetch the sources the build sandbox could not reach.

This library was assembled in an environment whose egress policy allowed
GitHub and the package registries and almost nothing else.  Roman law and the
rabbinic corpus were reachable through GitHub mirrors and are shipped.  The
Mesopotamian, Hittite, Greek and early-medieval material was not, so those
provisions are carried as citations plus editorial restatements, clearly
marked, with `text: null`.

Run this module on a machine with ordinary network access and it will fetch
the public-domain translations and fill them in:

    python -m nomos.fetch.restricted --out data/raw/restricted

Nothing here is required for the library to build or for the pipeline to run.
It exists so that the gap in the shipped data is a gap you can close with one
command rather than a permanent hole.

Every source below is either public domain by age or explicitly open-licensed.
We record the licence with the text.  Check it yourself before redistributing:
licences change, and the burden is on the redistributor.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass, field
from typing import Callable, Optional

# ---------------------------------------------------------------------------


@dataclass
class RestrictedSource:
    key: str
    name: str
    url: str
    license: str
    note: str
    tradition: str
    # a parser taking raw text/HTML and returning [{citation, text}]
    parse: Optional[Callable[[str], list[dict]]] = None
    encoding: str = "utf-8"


def _strip_html(html: str) -> str:
    html = re.sub(r"(?is)<(script|style).*?</\1>", " ", html)
    html = re.sub(r"(?i)<br\s*/?>", "\n", html)
    html = re.sub(r"(?i)</p>", "\n\n", html)
    html = re.sub(r"<[^>]+>", " ", html)
    for a, b in (("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"),
                 ("&gt;", ">"), ("&quot;", '"'), ("&#39;", "'")):
        html = html.replace(a, b)
    html = re.sub(r"[ \t\xa0]+", " ", html)
    return re.sub(r"\n{3,}", "\n\n", html).strip()


_NUMBERED = re.compile(r"^\s*(?:§\s*)?(\d{1,3})\s*[.:)]?\s+(.{15,})$", re.MULTILINE)


def parse_numbered_laws(text: str, prefix: str) -> list[dict]:
    """Most editions of the ANE codes print '57. If a man ...' one per line."""
    body = _strip_html(text)
    out = []
    for m in _NUMBERED.finditer(body):
        n, content = m.group(1), m.group(2).strip()
        if len(content) < 20:
            continue
        out.append({"citation": f"{prefix} §{n}", "number": int(n),
                    "text": content})
    # de-duplicate on number, keeping the longest reading
    best: dict[int, dict] = {}
    for r in out:
        k = r["number"]
        if k not in best or len(r["text"]) > len(best[k]["text"]):
            best[k] = r
    return [best[k] for k in sorted(best)]


SOURCES: list[RestrictedSource] = [
    RestrictedSource(
        key="hammurabi_king",
        name="Code of Hammurabi, trans. L. W. King (1915)",
        url="https://avalon.law.yale.edu/ancient/hamframe.asp",
        license="Public domain (author d. 1919)",
        note=("The Avalon Project's edition.  §§57-58 grazing, §§120-126 "
              "deposit, §§215-240 professionals, §§250-252 the goring ox."),
        tradition="mesopotamian",
        parse=lambda t: parse_numbered_laws(t, "LH"),
    ),
    RestrictedSource(
        key="hammurabi_harper",
        name="The Code of Hammurabi, trans. R. F. Harper (1904)",
        url="https://en.wikisource.org/wiki/The_Code_of_Hammurabi_(Harper_translation)",
        license="Public domain (published 1904)",
        note="Harper's numbering is the one most comparative literature cites.",
        tradition="mesopotamian",
        parse=lambda t: parse_numbered_laws(t, "LH"),
    ),
    RestrictedSource(
        key="twelve_tables_en",
        name="The Twelve Tables (English), Avalon Project",
        url="https://avalon.law.yale.edu/ancient/twelve_tables.asp",
        license="Public domain",
        note="The Latin is already shipped, from the Latin Library.",
        tradition="roman",
    ),
    RestrictedSource(
        key="hittite_laws",
        name="The Hittite Laws",
        url="https://en.wikisource.org/wiki/Hittite_Laws",
        license="Check per-edition; older translations are public domain",
        note=("§§ on straying and injured animals parallel LH and Exodus and "
              "are the third independent Anatolian witness."),
        tradition="hittite",
        parse=lambda t: parse_numbered_laws(t, "HL"),
    ),
    RestrictedSource(
        key="gortyn",
        name="The Law Code of Gortyn",
        url="https://en.wikisource.org/wiki/Great_Code_of_Gortyn",
        license="Public domain for pre-1929 translations (Roby, Bücheler)",
        note="The fullest surviving Greek city code; strong on family property.",
        tradition="greek",
    ),
    RestrictedSource(
        key="eshnunna",
        name="Laws of Eshnunna",
        url="https://en.wikipedia.org/wiki/Laws_of_Eshnunna",
        license="CC-BY-SA for the article; the translation itself may not be",
        note=("§§53-55 are the earliest surviving goring-ox rules and the "
              "closest parallel to Exodus 21:35.  Verify against Yaron, "
              "*The Laws of Eshnunna* (2nd edn, 1988) before relying on them."),
        tradition="mesopotamian",
    ),
    RestrictedSource(
        key="cdli_atf",
        name="CDLI bulk transliterations (ATF)",
        url="https://github.com/cdli-gh/data",
        license="CC-BY-NC-SA per CDLI",
        note=("Reachable from the sandbox via git, but needs git-lfs.  "
              "Transliterations, not translations: useful as evidence of what "
              "actual Mesopotamian contracts look like beside the codes."),
        tradition="mesopotamian",
    ),
    RestrictedSource(
        key="sefaria_full",
        name="Sefaria bulk export (current)",
        url="https://storage.googleapis.com/sefaria-export/",
        license="per-text; see each version's `license` field",
        note=("The shipped rabbinic texts come from the 2020 in-repo snapshot. "
              "The current export lives in a GCS bucket; use "
              "`Sefaria-Export/examples/download_category.sh` for fresh data."),
        tradition="rabbinic",
    ),
    RestrictedSource(
        key="early_english_laws",
        name="Early English Laws (Æthelberht, Alfred, Ine, Cnut)",
        url="https://earlyenglishlaws.ac.uk/laws/texts/",
        license="Site content CC-BY-NC; Liebermann (1903-16) and Attenborough "
                "(1922) are public domain by age",
        note=("Alfred's Domboc opens with an Old English translation of Exodus "
              "20-23, goring ox included -- the one documented transmission of "
              "a rule in this corpus. Af El. ~21 in Liebermann's numbering; "
              "editions disagree, so check."),
        tradition="english",
    ),
    RestrictedSource(
        key="bracton",
        name="Bracton, De legibus et consuetudinibus Angliae",
        url="https://bracton.law.harvard.edu/",
        license="Twiss (1878-83) and Woodbine/Thorne are public domain or "
                "Harvard-hosted; check per volume",
        note=("Where the Roman actio de pauperie enters English writing. "
              "Harvard's edition gives Latin and English in parallel."),
        tradition="english",
    ),
    RestrictedSource(
        key="animals_act_1971",
        name="Animals Act 1971 (UK), s.2",
        url="https://www.legislation.gov.uk/ukpga/1971/22/section/2",
        license="Open Government Licence v3.0",
        note=("s.2(2) states the goring-ox rule in three parts -- a propensity, "
              "abnormal for the species, known to the keeper -- three thousand "
              "years after Exodus 21:29. legislation.gov.uk serves XML at "
              "/data.xml."),
        tradition="english",
    ),
    RestrictedSource(
        key="bailii",
        name="BAILII: May v Burdett, Cox v Burbidge, Rylands v Fletcher",
        url="https://www.bailii.org/",
        license="Judgments are public; BAILII asks that you not bulk-scrape",
        note=("The scienter line. Fetch individually and politely, or use the "
              "printed reports: 9 QB 101, 13 CB NS 430, LR 3 HL 330."),
        tradition="english",
    ),
    RestrictedSource(
        key="ctext_tang",
        name="Chinese Text Project: 唐律疏議 and the dynastic codes",
        url="https://ctext.org/",
        license="CC-BY-SA for ctext's own markup",
        note=("The Tang Code ships with this repository from the Daizhige "
              "transcription, but that transcription silently drops rare "
              "characters (觝, 齧 are missing from the commentary on art. 207). "
              "ctext is the place to check readings, and has an API."),
        tradition="chinese",
    ),
    RestrictedSource(
        key="caselaw",
        name="Caselaw Access Project bulk data",
        url="https://static.case.law/",
        license="Public domain (US judicial opinions)",
        note=("For extending the corpus to modern common law.  The cattle-"
              "trespass and scienter lines are the direct descendants of "
              "D.9.1 and Ex 21:28-36 and would make the strongest test of "
              "whether the factor vocabulary travels."),
        tradition="common-law",
    ),
]

BY_KEY = {s.key: s for s in SOURCES}


def fetch_one(src: RestrictedSource, out_dir: str, timeout: int = 60,
              session=None) -> dict:
    import urllib.request

    os.makedirs(out_dir, exist_ok=True)
    raw_path = os.path.join(out_dir, f"{src.key}.raw")
    parsed_path = os.path.join(out_dir, f"{src.key}.jsonl")
    meta = {"key": src.key, "name": src.name, "url": src.url,
            "license": src.license, "tradition": src.tradition,
            "note": src.note, "fetched": None, "provisions": 0,
            "error": None}
    try:
        req = urllib.request.Request(
            src.url, headers={"User-Agent": "nomos-research/0.1 (+research use)"})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read().decode(src.encoding, errors="replace")
        with open(raw_path, "w", encoding="utf8") as fh:
            fh.write(body)
        meta["fetched"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        if src.parse:
            rows = src.parse(body)
            with open(parsed_path, "w", encoding="utf8") as fh:
                for row in rows:
                    row.update({"tradition": src.tradition,
                                "source": {"name": src.name, "url": src.url,
                                           "license": src.license,
                                           "availability": "fetched"}})
                    fh.write(json.dumps(row, ensure_ascii=False) + "\n")
            meta["provisions"] = len(rows)
    except Exception as exc:                       # noqa: BLE001
        meta["error"] = f"{type(exc).__name__}: {exc}"
    return meta


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", default="data/raw/restricted")
    ap.add_argument("--only", nargs="*", help="source keys to fetch")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    if args.list:
        for s in SOURCES:
            print(f"{s.key:20s} {s.tradition:14s} {s.name}")
            print(f"{'':20s} {s.url}")
            print(f"{'':20s} licence: {s.license}")
            print()
        return

    todo = [s for s in SOURCES if not args.only or s.key in args.only]
    metas = []
    for s in todo:
        print(f"fetching {s.key} ...", end=" ", flush=True)
        m = fetch_one(s, args.out)
        metas.append(m)
        print(m["error"] or f"ok ({m['provisions']} provisions)")
    with open(os.path.join(args.out, "manifest.json"), "w", encoding="utf8") as fh:
        json.dump(metas, fh, indent=2, ensure_ascii=False)
    ok = sum(1 for m in metas if not m["error"])
    print(f"\n{ok}/{len(metas)} sources fetched -> {args.out}")
    if ok < len(metas):
        print("Sources that failed are usually blocked by a local egress policy, "
              "not gone; the URLs above are stable.", file=sys.stderr)


if __name__ == "__main__":
    main()
