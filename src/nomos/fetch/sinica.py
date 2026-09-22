"""Parse the Chinese legal corpus into addressable provisions.

## Why this tradition matters more than any other addition

Every tradition in the original corpus -- Mesopotamian, biblical, rabbinic,
Roman -- shares a neighbourhood.  They borrowed from each other, argued with
each other, and in some cases descend from each other.  A factor vocabulary
that fits all of them may be fitting a family resemblance rather than anything
about law.

Chinese law is the control.  The Tang Code was promulgated in 653 CE by a state
that had no contact with Rome, Babylon or Israel, working in a script and a
philosophical vocabulary with no common ancestor.  If the same factors describe
its rules, that is evidence the vocabulary is tracking legal structure.  If
they do not, the comparative programme is in trouble and we would want to know.

It also turns out to satisfy, independently, the three conditions that
`Nomos.Reasoning.Precedent` says a tradition needs before the reason model can
apply to it:

1. **It decides concrete disputes and records them.**  The *Minggong shupan
   qingming ji* (名公書判清明集, 13th c.) collects Southern Song civil
   judgments -- land, debt, inheritance, marriage -- under the names of the
   judges who gave them.  The *Xing'an huilan* (刑案匯覽, 1834) is a Qing
   criminal case reporter running to thousands of decisions.
2. **It records which features mattered.**  Both report the reasoning, not
   just the result.
3. **It treats past decisions as authority.**  The Ming and Qing codes attach
   例 (substatutes) to each 律 (statute); the 例 are largely codified
   precedents.  And Qing law had an explicit doctrine of analogical extension,
   比附 *bifu*, regulated by Qing Code art. 44 (斷罪無正條, "deciding a case
   where there is no exact provision"), which permits a judge to apply the
   nearest statute by analogy *and requires him to memorialise the throne for
   confirmation*.

That last item is worth sitting with.  `bifu` is a codified rule about when
reasoning by analogy from an existing provision is permitted, with a mandatory
review step attached because the drafters understood the move to be dangerous.
It is the same worry `Nomos.Reasoning.Analogy.no_strengthening` formalises, and
the Qing answer -- extend, but report it upward -- is a procedural version of
the *dayyo* restriction.

## Sources

All texts from 殆知閣古代文獻藏書 (Daizhige), via
<https://github.com/garychowcmu/daizhigev20>.  The collection carries no
explicit licence; the underlying works are long out of copyright (the latest,
the *Xing'an huilan*, dates to 1834), but the *digitisation* has no stated
terms.  We record this honestly rather than asserting a licence the source does
not give.  See DATA_LICENSES.md.

Texts are in simplified characters, as Daizhige distributes them.  Segmentation
quality varies by work and is recorded per provision in `meta["segmentation"]`:
`article` (reliable), `entry` (reliable), `block` (coarse -- a paragraph-sized
chunk, not necessarily one legal unit).
"""

from __future__ import annotations

import os
import re
from typing import Iterator, Optional

from ..schema import Provision, Source, clean

DAIZHIGE = Source(
    name="殆知閣古代文獻藏書 (Daizhige)",
    url="https://github.com/garychowcmu/daizhigev20",
    license="unspecified (underlying works public domain by age)",
    availability="included",
    note="Simplified-character transcriptions; no licence stated by the compiler.",
)

# Full-width digits used by the Tang Code's article numbering.
FW = "０１２３４５６７８９"
FW_MAP = {c: str(i) for i, c in enumerate(FW)}


def _fw_int(s: str) -> int:
    return int("".join(FW_MAP.get(c, c) for c in s))


def _cjk_len(s: str) -> int:
    return sum(1 for c in s if "㐀" <= c <= "鿿")


# ---------------------------------------------------------------------------
# 唐律疏議 -- the Tang Code with its official commentary (653 CE)
# ---------------------------------------------------------------------------

TANG_JUAN = re.compile(r"^\s*●卷([一二三四五六七八九十百]+)\s*(\S+?)\s*（([０-９\d]+)条?）")
TANG_ART = re.compile(rf"^\s*([{FW}]+)．(.*)$")

CN_NUM = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7,
          "八": 8, "九": 9, "十": 10}


def _cn_int(s: str) -> int:
    if not s:
        return 0
    total, section, number = 0, 0, 0
    for ch in s:
        if ch in ("十",):
            section = (number or 1) * 10 + section
            number = 0
        elif ch in ("百",):
            section = (number or 1) * 100 + section
            number = 0
        elif ch in CN_NUM:
            number = CN_NUM[ch]
    return total + section + number


def parse_tang_code(path: str) -> Iterator[Provision]:
    """唐律疏議, the foundational code of East Asian law.

    Each article is numbered (１．through ５０２．) and followed by the statute
    text, which conventionally opens with 諸 ("in all cases where..."), then by
    the official 疏議 commentary marked 【疏】议曰, and sometimes by a
    question-and-answer section (問曰 / 答曰) working through a hard case.

    We keep the statute and its commentary in one provision but split them into
    separate fields, because they have different authority: the 律 is the law,
    the 疏 is the state's binding interpretation of it, and the 問答 is closer
    to a worked example.
    """
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = fh.read().split("\n")

    juan_no, division = 0, ""
    art_no: Optional[int] = None
    art_title = ""
    buf: list[str] = []
    out: list[Provision] = []

    def flush():
        nonlocal art_no, art_title, buf
        if art_no is None or not buf:
            art_no, buf = None, []
            return None
        body = "\n".join(x for x in buf if x.strip())
        statute_parts, commentary, qa = [], [], []
        mode = "statute"
        for ln in body.split("\n"):
            if ln.lstrip().startswith("【疏】"):
                mode = "commentary"
            elif ln.lstrip().startswith(("问曰", "問曰", "答曰")):
                mode = "qa"
            (statute_parts if mode == "statute" else
             commentary if mode == "commentary" else qa).append(ln)
        statute = clean("\n".join(statute_parts))
        n, t = art_no, art_title
        art_no, art_title, buf = None, "", []
        if not statute:
            return None
        return Provision(
            id=f"chinese.tanglv.{n}", tradition="chinese",
            work="唐律疏議 (Tang Code with Commentary)",
            citation=f"唐律疏議 art. {n} {t}".strip(),
            canonical=f"TL.{n}", language="lzh", text=statute,
            source=DAIZHIGE, era=(653, 653),
            path=[str(juan_no), str(n)], kind="provision",
            meta={"segmentation": "article", "title": t, "juan": juan_no,
                  "division": division,
                  "commentary": clean("\n".join(commentary)),
                  "qa": clean("\n".join(qa))},
        )

    for raw in lines:
        m = TANG_JUAN.match(raw)
        if m:
            p = flush()
            if p:
                out.append(p)
            juan_no = _cn_int(m.group(1))
            division = m.group(2)
            continue
        m = TANG_ART.match(raw)
        if m:
            p = flush()
            if p:
                out.append(p)
            art_no = _fw_int(m.group(1))
            art_title = m.group(2).strip()
            continue
        if art_no is not None:
            buf.append(raw)
    p = flush()
    if p:
        out.append(p)
    yield from out


# ---------------------------------------------------------------------------
# 大清律例 -- the Great Qing Code with substatutes (1740, here a later recension)
# ---------------------------------------------------------------------------

QING_LV = re.compile(r"^\s*『律』\s*([0-9]+)\.([0-9]+)\s*(.*)$")
QING_LI = re.compile(r"^\s*([0-9]+)\.([0-9]+)\s*$")


def parse_qing_code(path: str) -> Iterator[Provision]:
    """大清律例.

    The structure is the point.  Each 律 (statute) carries a train of 例
    (substatutes) numbered off it -- 1.00 is the statute, 1.01, 1.02 ... are the
    substatutes attached to it.  The 例 accumulated over the dynasty, many of
    them codifying decisions in particular cases, and by the nineteenth century
    they outnumbered the statutes several times over.

    That is a legal order growing by accretion of decided cases around a fixed
    code, recorded in the numbering.  We keep the relation in
    `meta["statute"]`.
    """
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = fh.read().split("\n")

    cur: Optional[tuple[int, int, str]] = None
    buf: list[str] = []
    out: list[Provision] = []

    def flush():
        nonlocal cur, buf
        if cur is None:
            return None
        major, minor, title = cur
        body = clean("\n".join(buf))
        cur, buf = None, []
        if _cjk_len(body) < 8:
            return None
        is_statute = minor == 0
        return Provision(
            id=f"chinese.daqing.{major}.{minor:02d}", tradition="chinese",
            work="大清律例 (Great Qing Code with Substatutes)",
            citation=f"大清律例 {major}.{minor:02d}" + (f" {title}" if title else ""),
            canonical=f"DQ.{major}.{minor:02d}", language="lzh",
            text=body, source=DAIZHIGE, era=(1646, 1870),
            path=[str(major), f"{minor:02d}"],
            kind="provision" if is_statute else "commentary",
            meta={"segmentation": "article",
                  "kind_zh": "律" if is_statute else "例",
                  "kind_en": "statute" if is_statute else "substatute",
                  "statute": f"DQ.{major}.00", "title": title},
        )

    for raw in lines:
        m = QING_LV.match(raw)
        if m:
            p = flush()
            if p:
                out.append(p)
            cur = (int(m.group(1)), int(m.group(2)), m.group(3).strip())
            continue
        m = QING_LI.match(raw)
        if m:
            p = flush()
            if p:
                out.append(p)
            cur = (int(m.group(1)), int(m.group(2)), "")
            continue
        if cur is not None:
            buf.append(raw)
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
# Generic block segmentation, for works without reliable article markers
# ---------------------------------------------------------------------------

JUAN_ANY = re.compile(r"^\s*[●]?\s*卷(?:之)?([一二三四五六七八九十百零〇\d]+)\s*(.*)$")
MEN = re.compile(r"^\s*(\S{1,6}门)\s*$")


def parse_blocks(path: str, *, work: str, prefix: str, tradition: str,
                 era: tuple[int, int], kind: str = "provision",
                 min_cjk: int = 30, max_chars: int = 1400,
                 skip_lines: int = 0) -> Iterator[Provision]:
    """Segment a work by 卷 (scroll) and then into paragraph-sized blocks.

    This is honest-but-coarse.  A block is not guaranteed to be one legal unit,
    and `meta["segmentation"] = "block"` records that.  It is good enough for
    retrieval and for training data, and not good enough to cite as "article
    N" of anything -- which is why these provisions carry positional citations
    rather than article numbers.
    """
    with open(path, encoding="utf8", errors="replace") as fh:
        lines = fh.read().split("\n")[skip_lines:]

    juan, juan_title, section = 0, "", ""
    idx = 0
    buf: list[str] = []
    out: list[Provision] = []

    def flush():
        nonlocal buf, idx
        body = clean("\n".join(buf))
        buf = []
        if _cjk_len(body) < min_cjk:
            return None
        idx += 1
        return Provision(
            id=f"{prefix}.{juan}.{idx}", tradition=tradition, work=work,
            citation=(f"{work} 卷{juan} §{idx}" if juan else f"{work} §{idx}"),
            canonical=f"{prefix.split('.')[-1].upper()}.{juan}.{idx}",
            language="lzh", text=body[:max_chars], source=DAIZHIGE, era=era,
            path=[str(juan), str(idx)], kind=kind,
            meta={"segmentation": "block", "juan_title": juan_title,
                  "section": section},
        )

    for raw in lines:
        m = JUAN_ANY.match(raw)
        if m and _cjk_len(raw) < 20:
            p = flush()
            if p:
                out.append(p)
            juan = _cn_int(m.group(1)) or (int(m.group(1)) if m.group(1).isdigit() else juan)
            juan_title = m.group(2).strip()
            idx = 0
            continue
        m = MEN.match(raw)
        if m:
            p = flush()
            if p:
                out.append(p)
            section = m.group(1)
            continue
        if not raw.strip():
            p = flush()
            if p:
                out.append(p)
            continue
        # Many of these works mark a new paragraph with leading ideographic
        # spaces rather than a blank line.  Treat that as a break too, or the
        # whole work collapses into a handful of enormous blocks.
        if raw.startswith(("\u3000\u3000", "  ")) and buf:
            p = flush()
            if p:
                out.append(p)
        buf.append(raw)
        if len("".join(buf)) > max_chars:
            p = flush()
            if p:
                out.append(p)
    p = flush()
    if p:
        out.append(p)
    yield from out


# ---------------------------------------------------------------------------
# driver
# ---------------------------------------------------------------------------

# (relative path, work title, id prefix, era, kind, skip)
BLOCK_WORKS: list[tuple[str, str, str, tuple[int, int], str, int]] = [
    ("史藏/职官/名公书判清明集.txt",
     "名公書判清明集 (Collected Decisions of Famous Judges)",
     "chinese.qingmingji", (1200, 1270), "case", 860),
    ("史藏/政书/刑案汇览三编.txt",
     "刑案匯覽三編 (Conspectus of Penal Cases, 3rd series)",
     "chinese.xinganhuilan", (1834, 1886), "case", 0),
    ("史藏/政书/大明律集解附例.txt",
     "大明律集解附例 (Ming Code with Commentary and Substatutes)",
     "chinese.daming", (1397, 1610), "provision", 0),
    ("史藏/政书/明代律例汇编.txt",
     "明代律例彙編 (Ming Statutes and Substatutes, compiled)",
     "chinese.mingbian", (1368, 1644), "provision", 0),
    ("史藏/政书/通典.txt", "通典 (Comprehensive Institutions)",
     "chinese.tongdian", (801, 801), "commentary", 0),
    ("子藏/法家/折狱龟鉴.txt", "折獄龜鑑 (Magic Mirror for Solving Cases)",
     "chinese.zheyu", (1133, 1133), "case", 0),
    ("子藏/法家/棠阴比事.txt", "棠陰比事 (Parallel Cases from under the Pear Tree)",
     "chinese.tangyin", (1211, 1211), "case", 0),
    ("子藏/法家/疑狱集.txt", "疑獄集 (Collection of Doubtful Cases)",
     "chinese.yiyu", (950, 1040), "case", 0),
    ("子藏/法家/韩非子.txt", "韓非子 (Han Feizi)",
     "chinese.hanfeizi", (-280, -233), "commentary", 0),
    ("子藏/法家/商子.txt", "商君書 (Book of Lord Shang)",
     "chinese.shangjunshu", (-350, -250), "commentary", 0),
    ("子藏/法家/管子.txt", "管子 (Guanzi)",
     "chinese.guanzi", (-400, -200), "commentary", 0),
    ("子藏/法家/邓析子.txt", "鄧析子 (Dengxizi)",
     "chinese.dengxizi", (-350, -200), "commentary", 0),
    ("医藏/洗冤集录.txt", "洗冤集錄 (Collected Cases of Injustice Rectified)",
     "chinese.xiyuan", (1247, 1247), "commentary", 0),
]


def harvest(root: str) -> Iterator[Provision]:
    """root = data/raw/sinica"""
    tang = os.path.join(root, "唐律疏议.txt")
    if os.path.exists(tang):
        yield from parse_tang_code(tang)

    qing = os.path.join(root, "大清律例.txt")
    if os.path.exists(qing):
        yield from parse_qing_code(qing)

    for rel, work, prefix, era, kind, skip in BLOCK_WORKS:
        p = os.path.join(root, os.path.basename(rel))
        if os.path.exists(p):
            yield from parse_blocks(p, work=work, prefix=prefix,
                                    tradition="chinese", era=era, kind=kind,
                                    skip_lines=skip)
