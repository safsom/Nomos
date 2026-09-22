"""Assemble the normalised provision corpus from the staged raw sources."""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter

from .schema import Provision, write_jsonl
from .fetch import latin_library, sefaria, sinica

HERE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RAW = os.path.join(HERE, "data", "raw")
OUT = os.path.join(HERE, "data", "corpus")


def build(allow_nc: bool = True, languages=("en",)) -> list[Provision]:
    rows: list[Provision] = []

    ll_root = os.path.join(RAW, "latin_library")
    if os.path.isdir(ll_root):
        rows.extend(latin_library.harvest(ll_root))
    else:
        print(f"  ! missing {ll_root}", file=sys.stderr)

    sn_root = os.path.join(RAW, "sinica")
    if os.path.isdir(sn_root):
        rows.extend(sinica.harvest(sn_root))
    else:
        print(f"  ! missing {sn_root}", file=sys.stderr)

    sf_root = os.path.join(RAW, "sefaria")
    if os.path.isdir(sf_root):
        rows.extend(sefaria.harvest(sf_root, languages=languages, allow_nc=allow_nc))
    else:
        print(f"  ! missing {sf_root}", file=sys.stderr)

    # Provisions declared in data/seed/restricted_provisions.jsonl: sources
    # that are public but which the build sandbox could not reach.  They ship
    # with text=None and are filled in by src/nomos/fetch/restricted.py.
    extra = os.path.join(HERE, "data", "seed", "restricted_provisions.jsonl")
    if os.path.exists(extra):
        from .schema import Source
        with open(extra, encoding="utf8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                d = json.loads(line)
                d["source"] = Source(**d["source"])
                d["era"] = tuple(d["era"]) if d.get("era") else None
                rows.append(Provision(**d))

    seen: set[str] = set()
    uniq: list[Provision] = []
    for p in rows:
        if p.id in seen:
            continue
        seen.add(p.id)
        uniq.append(p)
    return uniq


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--no-nc", action="store_true",
                    help="exclude non-commercially licensed texts")
    ap.add_argument("--languages", default="en")
    ap.add_argument("--out", default=os.path.join(OUT, "provisions.jsonl.gz"),
                    help="ends in .gz -> written compressed")
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    rows = build(allow_nc=not args.no_nc,
                 languages=tuple(args.languages.split(",")))
    n = write_jsonl(args.out, rows)

    by_trad = Counter(p.tradition for p in rows)
    by_work = Counter(p.work for p in rows)
    by_lic = Counter(p.source.license for p in rows)
    chars = sum(len(p.text or "") for p in rows)

    print(f"wrote {n} provisions -> {args.out}  ({chars/1e6:.1f}M chars)")
    print("\nby tradition:")
    for k, v in by_trad.most_common():
        print(f"  {v:7d}  {k}")
    print("\nby work:")
    for k, v in by_work.most_common():
        print(f"  {v:7d}  {k}")
    print("\nby licence:")
    for k, v in by_lic.most_common():
        print(f"  {v:7d}  {k}")

    stats = {
        "provisions": n, "characters": chars,
        "by_tradition": dict(by_trad), "by_work": dict(by_work),
        "by_license": dict(by_lic),
    }
    with open(os.path.join(os.path.dirname(args.out), "stats.json"), "w") as fh:
        json.dump(stats, fh, indent=2)


if __name__ == "__main__":
    main()
