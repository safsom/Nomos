"""Write the seed formalisations and fact patterns out as data.

The Lean library is the source of truth: this runs `lake exe export-corpus`
and attaches the provision text from the corpus, so each seed record carries
the original text, our reading of it, and the Lean declaration together.
"""

from __future__ import annotations

import json
import os
import sys
from collections import Counter

from .analogy import Holding
from .fact_patterns import PATTERNS
from .schema import read_jsonl, resolve, write_jsonl
from .verify import export_seed, lean_available, render

HERE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CORPUS = os.path.join(HERE, "data", "corpus")
SEED = os.path.join(HERE, "data", "seed")

# Citations in the Lean corpus, mapped to canonical ids in the provision
# corpus.  Only the ones whose text we actually ship can be linked; the
# Mesopotamian restatements have no text here by design.
CITE_TO_CANONICAL = {
    "Ex 21:28": ["Exodus 21:28"],
    "Ex 21:29": ["Exodus 21:29"],
    "Ex 21:29-30": ["Exodus 21:29", "Exodus 21:30"],
    "Ex 21:32": ["Exodus 21:32"],
    "Ex 21:33-34": ["Exodus 21:33", "Exodus 21:34"],
    "Ex 21:35": ["Exodus 21:35"],
    "Ex 21:36": ["Exodus 21:36"],
    "Ex 22:4": ["Exodus 22:4"],
    "Ex 22:5": ["Exodus 22:5"],
    "Ex 22:9-10": ["Exodus 22:9", "Exodus 22:10"],
    "Ex 22:13": ["Exodus 22:13"],
    "Ex 22:14": ["Exodus 22:14"],
    "m.BK 1:1 (ox / keren)": ["Mishnah Bava Kamma 1:1"],
    "m.BK 1:1 (crop-destroying beast / shen)": ["Mishnah Bava Kamma 1:1"],
    "m.BK 1:1 (fire / esh)": ["Mishnah Bava Kamma 1:1"],
    "m.BK 1:1 (pit / bor)": ["Mishnah Bava Kamma 1:1"],
    "m.BK 1:1 (general rule: the common feature)": ["Mishnah Bava Kamma 1:1"],
    "m.BK 2:5 (agreed: horn in the public domain)": ["Mishnah Bava Kamma 2:5"],
    "m.BK 1:4, 4:9 (mu'ad)": ["Mishnah Bava Kamma 1:4", "Mishnah Bava Kamma 4:9"],
    "m.BK 1:4, 4:9 (tam)": ["Mishnah Bava Kamma 1:4", "Mishnah Bava Kamma 4:9"],
    "m.BM 7:8 (shomer chinam)": ["Mishnah Bava Metzia 7:8"],
    "m.BM 7:8 (shomer sachar / socher)": ["Mishnah Bava Metzia 7:8"],
    "m.BM 7:8 (sho'el)": ["Mishnah Bava Metzia 7:8"],
    "D.9.1.1pr (Ulpian) = XII Tab.": ["D.9.1.1pr"],
    "D.9.1.1.4 (Ulpian, citing Servius)": ["D.9.1.1.4"],
    "D.9.1.1.11 (Ulpian, citing Q. Mucius)": ["D.9.1.1.11"],
    "D.9.2.2pr (Gaius) -- lex Aquilia c.1": ["D.9.2.2pr"],
    "D.9.2.27.5 (Ulpian) -- lex Aquilia c.3": ["D.9.2.27.5"],
    "D.9.2.44pr (Ulpian)": ["D.9.2.44pr"],
    "D.9.2.5.2 (Ulpian, citing Pegasus)": ["D.9.2.5.2"],
    "D.50.17.203 (Pomponius)": ["D.50.17.203"],
    "D.9.2.4pr (Gaius)": ["D.9.2.4pr"],
    "D.13.6.5.2, D.16.3.1.35 (Ulpian) -- utilitas contrahentium":
        ["D.13.6.5.2", "D.16.3.1.35"],
    "D.13.6.5.2 (Ulpian) -- commodatum": ["D.13.6.5.2"],
    "XII Tab. 8.2": ["XII Tab. 8.2"],
    "XII Tab. 8.3": ["XII Tab. 8.3"],
    # Chinese -- the Tang Code ships with text, so these link to real provisions
    "唐律疏議 art. 207 (畜產蹋人) -- failure to mark and tether": ["TL.207"],
    "唐律疏議 art. 207 (畜產蹋人) -- deliberate release (故放)": ["TL.207"],
    "唐律疏議 art. 206 (犬殺傷畜產) -- dog": ["TL.206"],
    "唐律疏議 art. 206 (犬殺傷畜產) -- other beasts, half damages": ["TL.206"],
    "唐律疏議 art. 204 (官私畜毀食官私物)": ["TL.204"],
    "唐律疏議 art. 204 -- killing the trespassing beast 登時": ["TL.204"],
    "唐律疏議 art. 209 (放畜損食官私物)": ["TL.209"],
    "唐律疏議 art. 203 (故殺官私馬牛)": ["TL.203"],
    # English -- only Magna Carta ships with text
    "Magna Carta (1215) cl. 39": ["Magna Carta (1215) cl. 39"],
    "Magna Carta (1215) cl. 20": ["Magna Carta (1215) cl. 20"],
}

# Which fact pattern each seed holding belongs to.
CITE_TO_PATTERN = {
    "Ex 21:28": "FP-GORE", "Ex 21:29": "FP-GORE", "Ex 21:29-30": "FP-GORE",
    "Ex 21:32": "FP-GORE", "Ex 21:35": "FP-GORE", "Ex 21:36": "FP-GORE",
    "Ex 21:33-34": "FP-PIT", "Ex 22:4": "FP-GRAZE", "Ex 22:5": "FP-FIRE",
    "Ex 22:9-10": "FP-BAILMENT", "Ex 22:13": "FP-BAILMENT",
    "Ex 22:14": "FP-CONSENT",
    "m.BK 1:1 (ox / keren)": "FP-GORE",
    "m.BK 1:1 (crop-destroying beast / shen)": "FP-GRAZE",
    "m.BK 1:1 (fire / esh)": "FP-FIRE",
    "m.BK 1:1 (pit / bor)": "FP-PIT",
    "m.BK 2:5 (agreed: horn in the public domain)": "FP-GORE",
    "m.BK 1:4, 4:9 (mu'ad)": "FP-GORE", "m.BK 1:4, 4:9 (tam)": "FP-GORE",
    "m.BM 7:8 (shomer chinam)": "FP-BAILMENT",
    "m.BM 7:8 (shomer sachar / socher)": "FP-BAILMENT",
    "m.BM 7:8 (sho'el)": "FP-BAILMENT",
    "D.9.1.1pr (Ulpian) = XII Tab.": "FP-GORE",
    "D.9.1.1.4 (Ulpian, citing Servius)": "FP-GORE",
    "D.9.1.1.11 (Ulpian, citing Q. Mucius)": "FP-GORE",
    "D.13.6.5.2, D.16.3.1.35 (Ulpian) -- utilitas contrahentium": "FP-BAILMENT",
    "D.13.6.5.2 (Ulpian) -- commodatum": "FP-BAILMENT",
    "XII Tab. 8.2": "FP-ASSAULT", "XII Tab. 8.3": "FP-ASSAULT",
    "m.BK 1:1 (general rule: the common feature)": "FP-WRONGFUL-DAMAGE",
    "D.9.2.2pr (Gaius) -- lex Aquilia c.1": "FP-WRONGFUL-DAMAGE",
    "D.9.2.27.5 (Ulpian) -- lex Aquilia c.3": "FP-WRONGFUL-DAMAGE",
    "D.9.2.44pr (Ulpian)": "FP-WRONGFUL-DAMAGE",
    "D.9.2.5.2 (Ulpian, citing Pegasus)": "FP-WRONGFUL-DAMAGE",
    "D.50.17.203 (Pomponius)": "FP-WRONGFUL-DAMAGE",
    "D.9.2.4pr (Gaius)": "FP-WRONGFUL-DAMAGE",
    "LH §250 [editorial restatement; text not shipped]": "FP-GORE",
    "LH §251 [editorial restatement; text not shipped]": "FP-GORE",
    "LH §252 [editorial restatement; text not shipped]": "FP-GORE",
    "LH §57 [editorial restatement; text not shipped]": "FP-GRAZE",
    "LH §229 [editorial restatement; text not shipped]": "FP-BUILD",
    "LE §53 [editorial restatement; text not shipped]": "FP-GORE",
    "LE §54 [editorial restatement; text not shipped]": "FP-GORE",
    "唐律疏議 art. 207 (畜產蹋人) -- failure to mark and tether": "FP-GORE",
    "唐律疏議 art. 207 (畜產蹋人) -- deliberate release (故放)": "FP-GORE",
    "唐律疏議 art. 206 (犬殺傷畜產) -- dog": "FP-GORE",
    "唐律疏議 art. 206 (犬殺傷畜產) -- other beasts, half damages": "FP-GORE",
    "唐律疏議 art. 204 (官私畜毀食官私物)": "FP-GRAZE",
    "唐律疏議 art. 204 -- killing the trespassing beast 登時": "FP-GRAZE",
    "唐律疏議 art. 209 (放畜損食官私物)": "FP-GRAZE",
    "唐律疏議 art. 203 (故殺官私馬牛)": "FP-WRONGFUL-DAMAGE",
    "Æthelberht (c. 600) [editorial restatement; text not shipped]": "FP-ASSAULT",
    "Alfred, Domboc, Mosaic prologue (Af El. ~21) [editorial restatement]": "FP-GORE",
    "Magna Carta (1215) cl. 39": "FP-WRONGFUL-DAMAGE",
    "Magna Carta (1215) cl. 20": "FP-WRONGFUL-DAMAGE",
    "Bracton, De legibus (c. 1235) [editorial restatement; text not shipped]": "FP-GORE",
    "May v Burdett (1846) 9 QB 101 [editorial restatement]": "FP-GORE",
    "Cox v Burbidge (1863) 13 CB NS 430 [editorial restatement]": "FP-GORE",
    "Rylands v Fletcher (1868) LR 3 HL 330 [editorial restatement]": "FP-WRONGFUL-DAMAGE",
    "Animals Act 1971 (UK) s.2(2) [editorial restatement]": "FP-GORE",
}


def main() -> None:
    os.makedirs(SEED, exist_ok=True)
    if not lean_available():
        print("lake not on PATH; cannot export the seed corpus", file=sys.stderr)
        raise SystemExit(1)

    holdings = export_seed()

    prov_path = resolve(os.path.join(CORPUS, "provisions.jsonl"))
    by_canon: dict[str, dict] = {}
    if os.path.exists(prov_path):
        for p in read_jsonl(prov_path):
            by_canon.setdefault(p["canonical"], p)

    rows, linked, unlinked = [], 0, []
    for h in holdings:
        canons = CITE_TO_CANONICAL.get(h.cite, [])
        texts, ids, srcs = [], [], []
        for c in canons:
            p = by_canon.get(c)
            if p:
                texts.append(p.get("text") or "")
                ids.append(p["id"])
                srcs.append(p["source"])
        if canons and not ids:
            unlinked.append(h.cite)
        elif not canons:
            unlinked.append(h.cite)
        else:
            linked += 1
        rows.append({
            "cite": h.cite,
            "tradition": h.tradition,
            "fact_pattern": CITE_TO_PATTERN.get(h.cite),
            "provision_ids": ids,
            "canonical": canons,
            "text": "\n".join(t for t in texts if t) or None,
            "text_available": bool(ids),
            "source": srcs[0] if srcs else None,
            "situation": h.situation,
            "winner": h.winner,
            "remedy": h.remedy,
            "reason": h.reason,
            "well_formed": h.well_formed(),
            "lean": render(h, decl="holding"),
        })

    out = os.path.join(SEED, "formalizations.jsonl")
    n = write_jsonl(out, rows)

    fp_path = os.path.join(CORPUS, "fact_patterns.json")
    with open(fp_path, "w", encoding="utf8") as fh:
        json.dump([p.to_json() for p in PATTERNS], fh, indent=2, ensure_ascii=False)

    trad = Counter(r["tradition"] for r in rows)
    pat = Counter(r["fact_pattern"] for r in rows)
    print(f"wrote {n} seed formalizations -> {out}")
    print(f"  with shipped text: {sum(1 for r in rows if r['text_available'])}/{n}")
    print(f"  by tradition: {dict(trad)}")
    print(f"  by fact pattern: {dict(pat)}")
    print(f"wrote {len(PATTERNS)} fact patterns -> {fp_path}")
    if unlinked:
        print(f"  note: {len(unlinked)} holdings have no shipped text "
              f"(expected for editorial restatements)")


if __name__ == "__main__":
    main()
