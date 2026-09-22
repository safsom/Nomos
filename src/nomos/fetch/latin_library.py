"""Parse the Latin Library's Roman-law texts into addressable provisions.

Covers:
  * Digesta Iustiniani   (50 books)   -- "Dig. 9.2.27.5"
  * Codex Iustinianus    (12 books)   -- "CJ.4.1.1"
  * Institutiones        (4 books)    -- "Inst. 3.24.5"
  * Gaius, Institutiones (4 books)    -- "Gai. 3.211"
  * Lex XII Tabularum                 -- "XII Tab. 8.6"

Source: https://www.thelatinlibrary.com/  (Public Domain Mark 1.0), via the
CLTK mirror https://github.com/cltk/lat_text_latin_library

The Digest is the single most valuable text for this project: roughly 21,000
short fragments, each attributed to a named jurist, each stating or arguing
toward a liability allocation, and each already carrying a precise citation.
It is, in effect, a pre-existing case-law database with 1,400 years of
continuous downstream citation.
"""

from __future__ import annotations

import os
import re
from typing import Iterator

from ..schema import Provision, Source, clean

LATIN_LIBRARY = Source(
    name="The Latin Library (via CLTK mirror)",
    url="https://github.com/cltk/lat_text_latin_library",
    license="Public Domain Mark 1.0",
    availability="included",
    note="Latin originals. Public domain; see LICENSE.md in data/raw/latin_library.",
)

# ---------------------------------------------------------------------------
# Digest
# ---------------------------------------------------------------------------

# "Dig. 9.1.1pr." | "Dig. 9.1.1.2" | "Dig. 9.1.0. De ..." | "Dig. 50.17.1"
DIG_CITE = re.compile(
    r"^\s*Dig\.\s*(\d+)\.(\d+)\.(\d+)(?:\.(\d+)|(pr))?\s*\.?\s*(.*)$",
    re.IGNORECASE,
)
# An attribution line looks like "Ulpianus 18 ad ed." / "Paulus libro 22 ad ed."
ATTRIB = re.compile(
    r"^\s*([A-Z][a-z]+(?:us|er|o)?)\s+(?:libro\s+)?([IVXLCDM\d]+)?\s*(ad\s+\w+|\w[\w\s]{0,40})?\.?\s*$"
)

JURISTS = {
    "ulpianus", "paulus", "gaius", "papinianus", "modestinus", "pomponius",
    "iulianus", "africanus", "marcianus", "callistratus", "florentinus",
    "labeo", "celsus", "iavolenus", "scaevola", "marcellus", "tryphoninus",
    "hermogenianus", "venuleius", "alfenus", "proculus", "neratius", "maecianus",
    "licinnius", "licinius", "terentius", "furius", "rutilius", "claudius",
    "iustinianus", "arrius", "aelius", "sabinus", "quintus", "mauricianus",
    "macer", "menander", "tarruntenus", "arcadius", "charisius", "paternus",
    "vivianus", "valens", "priscus", "clementius", "ofilius", "iavolenius",
}


def _is_attribution(line: str) -> bool:
    first = line.strip().split()[:1]
    if not first:
        return False
    return first[0].strip(",.").lower() in JURISTS


def parse_digest(path: str) -> Iterator[Provision]:
    book_no = None
    m = re.search(r"digest(\d+)\.txt$", os.path.basename(path))
    if m:
        book_no = int(m.group(1))

    with open(path, encoding="utf8", errors="replace") as fh:
        lines = fh.read().split("\n")

    # The file opens with a table of rubrics, then repeats each rubric inline.
    # We detect the start of substance as the first non-rubric citation.
    cur = None            # (book, title, frag, sect, rubric)
    buf: list[str] = []
    attrib = ""
    seen_body = False

    def flush():
        nonlocal cur, buf, attrib
        if cur is None:
            return
        b, t, f, s, rub = cur
        body = clean("\n".join(buf))
        if f == 0:
            # a rubric (title heading), e.g. "Dig. 9.1.0. Si quadrupes ..."
            txt = rub or body
            if not txt:
                cur, buf, attrib = None, [], ""
                return
            pid = f"roman.digest.{b}.{t}.0"
            yield_val = Provision(
                id=pid, tradition="roman", work="Digesta Iustiniani",
                citation=f"Dig. {b}.{t}.0", canonical=f"D.{b}.{t}.0",
                language="la", text=clean(txt), source=LATIN_LIBRARY,
                era=(-100, 533), path=[str(b), str(t), "0"], kind="rubric",
            )
        else:
            if not body:
                cur, buf, attrib = None, [], ""
                return
            sec = "pr" if s == "pr" else str(s) if s is not None else None
            cite = f"Dig. {b}.{t}.{f}" + (f".{sec}" if sec and sec != "pr" else ("pr" if sec == "pr" else ""))
            # Scholarly convention: "D.9.1.1pr" (no separator before pr),
            # "D.9.1.1.4" for numbered sections.
            canon = f"D.{b}.{t}.{f}" + ("pr" if sec == "pr" else (f".{sec}" if sec else ""))
            pid = "roman.digest." + canon[2:]
            yield_val = Provision(
                id=pid, tradition="roman", work="Digesta Iustiniani",
                citation=cite, canonical=canon, language="la",
                text=body, source=LATIN_LIBRARY, attribution=attrib,
                era=(-100, 533),
                path=[str(b), str(t), str(f)] + ([sec] if sec else []),
                kind="provision",
            )
        cur, buf, attrib = None, [], ""
        return yield_val

    out: list[Provision] = []
    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        m = DIG_CITE.match(line)
        if m:
            b, t, f = int(m.group(1)), int(m.group(2)), int(m.group(3))
            s = m.group(4)
            s = "pr" if m.group(5) else (int(s) if s is not None else None)
            rest = (m.group(6) or "").strip()
            # Rubric list at the head of the file: many "x.y.0." lines in a row
            # before any body text.  We keep only the inline repetitions, which
            # is harmless because ids are deduplicated downstream.
            p = flush()
            if p:
                out.append(p)
            cur = (b, t, f, s, rest if f == 0 else "")
            if f != 0 and rest:
                buf.append(rest)
            seen_body = seen_body or f != 0
            continue
        if cur is not None and not buf and _is_attribution(line):
            attrib = line.rstrip(".").strip()
            continue
        if cur is not None:
            buf.append(line)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


# ---------------------------------------------------------------------------
# Codex
# ---------------------------------------------------------------------------

CJ_CITE = re.compile(r"^\s*CJ\.(\d+)\.(\d+)\.(\d+)\s*[:.]\s*(.*)$")


def parse_codex(path: str) -> Iterator[Provision]:
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = fh.read().split("\n")

    cur = None
    buf: list[str] = []
    attrib = ""
    out: list[Provision] = []

    def flush():
        nonlocal cur, buf, attrib
        if cur is None:
            return None
        b, t, l = cur
        body = clean("\n".join(buf))
        cur_, buf_, attrib_ = cur, buf, attrib
        cur, buf, attrib = None, [], ""
        if not body:
            return None
        kind = "rubric" if l == 0 else "provision"
        canon = f"CJ.{b}.{t}.{l}"
        return Provision(
            id=f"roman.codex.{b}.{t}.{l}", tradition="roman",
            work="Codex Iustinianus", citation=canon, canonical=canon,
            language="la", text=body, source=LATIN_LIBRARY,
            attribution=attrib_, era=(117, 534),
            path=[str(b), str(t), str(l)], kind=kind,
        )

    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        # The head-of-file rubric dump puts dozens of citations on one line.
        if line.count("CJ.") > 3:
            continue
        m = CJ_CITE.match(line)
        if m:
            p = flush()
            if p:
                out.append(p)
            b, t, l = int(m.group(1)), int(m.group(2)), int(m.group(3))
            rest = (m.group(4) or "").strip()
            cur = (b, t, l)
            if l == 0:
                buf.append(rest)
            elif rest:
                attrib = rest          # emperor name follows the colon
            continue
        if cur is not None:
            buf.append(line)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


# ---------------------------------------------------------------------------
# Institutes of Justinian and of Gaius  (numbered paragraphs)
# ---------------------------------------------------------------------------

ROMAN_NUM = re.compile(r"^\s*([IVXLC]+):([IVXLC]+)\s+(.*)$")
PARA_NUM = re.compile(r"^\s*(\d{1,3})\s*[. ]?\s*(.+)$")


def _roman(s: str) -> int:
    vals = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100, "D": 500, "M": 1000}
    tot, prev = 0, 0
    for ch in reversed(s.upper()):
        v = vals.get(ch, 0)
        tot += v if v >= prev else -v
        prev = max(prev, v)
    return tot


def parse_institutes_prose(path: str, work: str, prefix: str, sigil: str,
                           era: tuple[int, int]) -> Iterator[Provision]:
    """Justinian's *Institutiones*, which the Latin Library prints unnumbered.

    The file gives a table of rubrics as `IV:I De obligationibus quae ex
    delicto nasc.` and then runs the text as bare paragraphs with no marks at
    all.  So we track the current title from the rubric lines and number
    paragraphs sequentially within it, which gives a citation of the form
    `Inst. 4.1.3` that is positionally accurate but not guaranteed to line up
    with the standard paragraph division.  `meta["numbering"]` records that.
    """
    base = os.path.basename(path)
    m = re.search(r"(\d)", base)
    book = int(m.group(1)) if m else 0

    with open(path, encoding="utf8", errors="replace") as fh:
        lines = [ln.strip() for ln in fh.read().split("\n")]

    para = 0
    buf: list[str] = []
    out: list[Provision] = []
    # The table of contents is the run of short rubric lines before the first
    # substantial paragraph.  Find that paragraph and start there.
    body_started = False

    def flush():
        nonlocal buf, para
        body = clean(" ".join(buf))
        buf = []
        if len(body) < 60:
            return None
        para += 1
        canon = f"{sigil} {book}.{para}"
        return Provision(
            id=f"{prefix}.{book}.{para}", tradition="roman",
            work=work, citation=canon, canonical=canon, language="la",
            text=body, source=LATIN_LIBRARY, era=era,
            path=[str(book), str(para)], kind="provision",
            meta={"numbering": "positional -- this edition prints rubrics only "
                            "in the table of contents, so paragraphs are "
                            "numbered by position within the book, not by the "
                            "standard title.paragraph division"},
        )

    for ln in lines:
        rm = ROMAN_NUM.match(ln)
        if rm and len(ln) < 200:
            buf = []
            continue
        if len(ln) > 220:
            body_started = True
        if not ln:
            p = flush()
            if p and body_started:
                out.append(p)
            continue
        if ln.upper() == ln and len(ln) < 60 and not any(c.islower() for c in ln):
            continue                      # running header
        buf.append(ln)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


# ---------------------------------------------------------------------------
# Theodosian Code, canon law, Magna Carta
# ---------------------------------------------------------------------------

CTH_CITE = re.compile(r"^\s*CTh\.(\d+)\.(\d+)\.(\d+)\s*\.?\s*(?:\[[^\]]*\])?\s*(.*)$")


def parse_theodosian(path: str) -> Iterator[Provision]:
    """*Codex Theodosianus* (438 CE), the imperial constitutions of the
    Christian empire, and the bridge by which Roman law reached the successor
    kingdoms of the west -- the Visigothic *Breviary* is an abridgement of it,
    and through the *Breviary* it shaped early medieval European law far more
    directly than Justinian did.

    Same citation shape as the Codex: `CTh.9.1.1`."""
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = fh.read().split("\n")

    cur, buf, out = None, [], []

    def flush():
        nonlocal cur, buf
        if cur is None:
            return None
        b, t, l = cur
        joined = "\n".join(buf)
        cur, buf = None, []
        # The Latin Library prints the Visigothic Breviary's gloss after many
        # constitutions, marked "interpretatio." -- keep it, but separately:
        # it is a 6th-century reading of a 4th-century text, not the text.
        interp = ""
        m = re.search(r"(?im)^\s*interpretatio\.?\s*", joined)
        if m:
            interp = clean(joined[m.end():])
            joined = joined[:m.start()]
        body = clean(joined)
        if not body:
            return None
        canon = f"CTh.{b}.{t}.{l}"
        return Provision(
            id=f"roman.theodosian.{b}.{t}.{l}", tradition="roman",
            work="Codex Theodosianus", citation=canon, canonical=canon,
            language="la", text=body, source=LATIN_LIBRARY, era=(312, 438),
            path=[str(b), str(t), str(l)],
            kind="rubric" if l == 0 else "provision",
            meta={"interpretatio": interp} if interp else {},
        )

    for raw in lines:
        line = raw.strip()
        if not line:
            continue
        if line.count("CTh.") > 3:
            continue
        m = CTH_CITE.match(line)
        if m:
            p = flush()
            if p:
                out.append(p)
            b, t, l = int(m.group(1)), int(m.group(2)), int(m.group(3))
            cur = (b, t, l)
            rest = (m.group(4) or "").strip()
            if rest:
                buf.append(rest)
            continue
        if cur is not None:
            buf.append(line)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


CAP = re.compile(r"^\s*CAP\.\s*([IVXLC]+)\.\s*(.*)$")


def parse_decretals(path: str) -> Iterator[Provision]:
    """*Decretales Gregorii IX* (1234), the *Liber Extra*.

    Canon law is in this corpus for a specific reason: it is the one learned
    legal system that was taught, pleaded and applied in medieval England
    alongside the nascent common law.  Bracton read it; the church courts
    applied it; and it carried Roman categories into a jurisdiction that never
    received Roman law directly.  It is the bridge between `Corpus/Roman.lean`
    and `Corpus/Anglia.lean`.

    Each chapter is `CAP. <roman>. <rubric>`, followed by an attribution (the
    pope or council the canon is drawn from) and the text.
    """
    book = 0
    m = re.search(r"gregdecretals(\d)", os.path.basename(path))
    if m:
        book = int(m.group(1))

    with open(path, encoding="utf8", errors="replace") as fh:
        lines = [ln.strip() for ln in fh.read().split("\n")]

    cap, rubric, attrib = 0, "", ""
    buf: list[str] = []
    out: list[Provision] = []

    def flush():
        nonlocal buf, attrib
        body = clean("\n".join(buf))
        buf, at = [], attrib
        attrib = ""
        if cap == 0 or len(body) < 40:
            return None
        canon = f"X {book}.{cap}"
        return Provision(
            id=f"canon.decretals.{book}.{cap}", tradition="canon",
            work="Decretales Gregorii IX (Liber Extra)",
            citation=canon, canonical=canon, language="la", text=body,
            source=LATIN_LIBRARY, attribution=at, era=(1140, 1234),
            path=[str(book), str(cap)], kind="provision",
            meta={"rubric": rubric},
        )

    for ln in lines:
        m = CAP.match(ln)
        if m:
            p = flush()
            if p:
                out.append(p)
            cap = _roman(m.group(1))
            rubric = m.group(2).strip()
            continue
        if not ln:
            continue
        # A short line with no terminal punctuation right after a CAP heading
        # is the attribution ("Gregorius Duci Campaniae.").
        if cap and not buf and len(ln) < 70 and ln.endswith("."):
            attrib = ln.rstrip(".")
            continue
        if cap:
            buf.append(ln)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


MC_CLAUSE = re.compile(r"^\s*(\d{1,2})\.\s+(.{20,})$")


def parse_magna_carta(path: str) -> Iterator[Provision]:
    """*Magna Carta* (1215), in the Latin of the Lincoln exemplar.

    Sixty-three clauses.  Most are feudal grievances of no interest here, but
    a handful are directly about liability and procedure -- cl. 20 (amercement
    proportionate to the offence, *salvo contenemento suo*), cl. 28-31
    (requisition without payment), cl. 39-40 (*nulli vendemus... nulli
    negabimus aut differemus rectum aut justiciam*).
    """
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = [ln.strip() for ln in fh.read().split("\n")]

    cur, buf, out = 0, [], []

    def flush():
        nonlocal buf
        body = clean(" ".join(buf))
        buf = []
        if cur == 0 or len(body) < 25:
            return None
        canon = f"Magna Carta (1215) cl. {cur}"
        return Provision(
            id=f"english.magnacarta.{cur}", tradition="english",
            work="Magna Carta (1215)", citation=canon, canonical=canon,
            language="la", text=body, source=LATIN_LIBRARY, era=(1215, 1215),
            path=[str(cur)], kind="provision",
        )

    for ln in lines:
        m = MC_CLAUSE.match(ln)
        if m:
            p = flush()
            if p:
                out.append(p)
            cur = int(m.group(1))
            buf = [m.group(2)]
            continue
        if not ln:
            p = flush()
            if p:
                out.append(p)
            cur = cur if buf else cur
            continue
        if cur:
            buf.append(ln)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


def parse_institutes(path: str, work: str, prefix: str, sigil: str,
                     era: tuple[int, int]) -> Iterator[Provision]:
    """Parse Gaius' Institutes, which the Latin Library *does* number.

    Justinian's are handled by `parse_institutes_prose`, because that edition
    prints no paragraph numbers in the body at all.
    """
    base = os.path.basename(path)
    m = re.search(r"(\d)", base)
    book = int(m.group(1)) if m else 0

    with open(path, encoding="utf8", errors="replace") as fh:
        text = fh.read()

    lines = [ln.strip() for ln in text.split("\n")]
    title_no = 0
    title_name = ""
    para = 0
    buf: list[str] = []
    out: list[Provision] = []
    # Skip the leading table of contents: it is a run of short rubric lines.
    body_started = False

    def flush():
        nonlocal buf
        if not buf:
            return None
        body = clean(" ".join(buf))
        buf = []
        if len(body) < 25:
            return None
        if title_no:
            canon = f"{sigil} {book}.{title_no}.{para}"
            pid = f"{prefix}.{book}.{title_no}.{para}"
            path_ = [str(book), str(title_no), str(para)]
        else:
            canon = f"{sigil} {book}.{para}"
            pid = f"{prefix}.{book}.{para}"
            path_ = [str(book), str(para)]
        return Provision(
            id=pid, tradition="roman", work=work, citation=canon,
            canonical=canon, language="la", text=body, source=LATIN_LIBRARY,
            era=era, path=path_, kind="provision",
            meta={"title": title_name} if title_name else {},
        )

    for ln in lines:
        if not ln:
            continue
        rm = ROMAN_NUM.match(ln)
        if rm and len(ln) < 200:
            p = flush()
            if p and body_started:
                out.append(p)
            title_no = _roman(rm.group(2))
            title_name = rm.group(3).strip()
            para = 0
            continue
        pm = PARA_NUM.match(ln)
        if pm and len(pm.group(2)) > 20:
            p = flush()
            if p and body_started:
                out.append(p)
            para = int(pm.group(1))
            buf = [pm.group(2)]
            body_started = True
            continue
        if body_started:
            buf.append(ln)
    p = flush()
    if p:
        out.append(p)

    seen = set()
    for pr in out:
        if pr.id in seen:
            continue
        seen.add(pr.id)
        yield pr


# ---------------------------------------------------------------------------
# Twelve Tables
# ---------------------------------------------------------------------------

TABULA = re.compile(r"^\s*TABULA\s+([IVX]+)\s*$", re.IGNORECASE)


def parse_twelve_tables(path: str) -> Iterator[Provision]:
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = [ln.strip() for ln in fh.read().split("\n")]

    table = 0
    item = 0
    buf: list[str] = []
    out: list[Provision] = []

    def flush():
        nonlocal buf, item
        body = clean(" ".join(buf))
        buf = []
        if not body or table == 0 or len(body) < 6:
            return None
        item += 1
        canon = f"XII Tab. {table}.{item}"
        return Provision(
            id=f"roman.xiitab.{table}.{item}", tradition="roman",
            work="Lex Duodecim Tabularum", citation=canon, canonical=canon,
            language="la", text=body, source=LATIN_LIBRARY, era=(-451, -449),
            path=[str(table), str(item)], kind="provision",
        )

    prev_blank = True
    for ln in lines:
        tm = TABULA.match(ln)
        if tm:
            p = flush()
            if p:
                out.append(p)
            table = _roman(tm.group(1))
            item = 0
            prev_blank = True
            continue
        if not ln:
            if buf:
                p = flush()
                if p:
                    out.append(p)
            prev_blank = True
            continue
        if ln.upper() == ln and len(ln) < 40 and not any(c.islower() for c in ln):
            continue      # running header
        buf.append(ln)
        prev_blank = False
    p = flush()
    if p:
        out.append(p)
    yield from out


# ---------------------------------------------------------------------------
# driver
# ---------------------------------------------------------------------------

def harvest(root: str) -> Iterator[Provision]:
    """root = data/raw/latin_library"""
    jdir = os.path.join(root, "justinian")
    if os.path.isdir(jdir):
        for i in range(1, 51):
            p = os.path.join(jdir, f"digest{i}.txt")
            if os.path.exists(p):
                yield from parse_digest(p)
        for i in range(1, 13):
            p = os.path.join(jdir, f"codex{i}.txt")
            if os.path.exists(p):
                yield from parse_codex(p)
        for i in range(1, 5):
            p = os.path.join(jdir, f"institutes{i}.txt")
            if os.path.exists(p):
                yield from parse_institutes_prose(
                    p, "Institutiones Iustiniani", "roman.inst", "Inst.", (533, 534))
    for i in range(1, 5):
        p = os.path.join(root, f"gaius{i}.txt")
        if os.path.exists(p):
            yield from parse_institutes(
                p, "Gai Institutiones", "roman.gaius", "Gai.", (160, 180))
    p = os.path.join(root, "12tables.txt")
    if os.path.exists(p):
        yield from parse_twelve_tables(p)

    tdir = os.path.join(root, "theodosius")
    if os.path.isdir(tdir):
        for i in range(1, 17):
            p = os.path.join(tdir, f"theod{i:02d}.txt")
            if os.path.exists(p):
                yield from parse_theodosian(p)

    for i in range(1, 6):
        p = os.path.join(root, f"gregdecretals{i}.txt")
        if os.path.exists(p):
            yield from parse_decretals(p)

    p = os.path.join(root, "magnacarta.txt")
    if os.path.exists(p):
        yield from parse_magna_carta(p)
