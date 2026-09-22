# Data provenance and licences

Nothing in `data/` is uniformly licensed. Check this file before
redistributing anything derived from it.

## Shipped with the repository

### Roman law — Latin originals

* **Works**: Digesta Iustiniani (books 1–50), Codex Iustinianus (1–12),
  Gaius' *Institutiones* (1–4), Lex XII Tabularum.
* **Source**: [The Latin Library](https://www.thelatinlibrary.com/) via the
  CLTK mirror <https://github.com/cltk/lat_text_latin_library>
* **Licence**: Public Domain Mark 1.0 (see
  `data/raw/latin_library/LICENSE.md`)
* **Note**: Also fetched but not yet parsed into the corpus: the Theodosian
  Code, Gratian's *Decretum*, the Decretals of Gregory IX, and Magna Carta.
  They are in `data/raw/latin_library/` if you want them.

### Rabbinic and biblical texts — English translations

* **Source**: <https://github.com/Sefaria/Sefaria-Export-Archive> at commit
  `1af9cdcb` (2020-07-08), the last export that shipped text in-repo. The
  current export lives in a GCS bucket; see the Sefaria-Export README.
* **Licences, per version** (each provision records its own):

  | text | version | licence |
  |---|---|---|
  | Exodus | JPS 1917, *The Holy Scriptures: A New Translation* | Public Domain |
  | Mishnah, Seder Nezikin | Mishnah Yomit, Dr Joshua Kulp | CC-BY |
  | Talmud Bavli, Bava Kamma / Metzia / Batra | William Davidson Edition | **CC-BY-NC** |
  | Tosefta Bava Kamma | Sefaria Community Translation | unspecified |

* **The non-commercial restriction is real.** The Davidson Talmud is 11,741 of
  the 40,194 provisions. Anything derived from it inherits CC-BY-NC. To build
  a corpus without it:

  ```bash
  python -m nomos.build_corpus --no-nc
  ```

  That flag also drops texts whose licence is merely *unstated*, since
  Sefaria's `merged` files silently mix NC-licensed versions in.

### Chinese texts

* **Works**: 唐律疏議 (Tang Code, 653), 大清律例 (Great Qing Code), 大明律集解附例
  and 明代律例彙編 (Ming), 名公書判清明集 (Song judgments, 13th c.), 刑案匯覽三編
  (Qing case reports, 1834–86), 通典 (801), 折獄龜鑑 / 棠陰比事 / 疑獄集 (case
  collections), 韓非子 / 商君書 / 管子 / 鄧析子 (Legalists), 洗冤集錄 (forensic
  manual, 1247).
* **Source**: 殆知閣古代文獻藏書 (Daizhige), mirrored at
  <https://github.com/garychowcmu/daizhigev20>
* **Licence**: **unspecified.** The underlying works are long out of copyright —
  the latest, 刑案匯覽三編, is from 1886 — but the *digitisation* carries no
  stated terms. We record that rather than asserting a licence the compiler
  does not give. If you need certainty, re-fetch from
  [ctext.org](https://ctext.org/), which states its terms.

**Three caveats that matter.**

1. **Dropped characters.** The Daizhige transcription silently omits some rare
   graphs. In the commentary on Tang Code art. 207, 觝 (gore) and 齧 (bite) are
   missing: the text reads 畜產人者，截兩角 where it should read 畜產**觝**人者.
   The sense survives from 截兩角 / 絆足 / 截兩耳 (horns, feet, ears), but do
   not quote these transcriptions as readings. Check against ctext.
2. **Simplified characters.** Daizhige distributes in simplified script. The
   works were written in traditional.
3. **Segmentation quality varies**, and every provision records which it got in
   `meta["segmentation"]`:
   * `article` — reliable. The Tang Code's 502 numbered articles and the Qing
     Code's 律/例 units. Cite these.
   * `block` — coarse. A paragraph-sized chunk, not necessarily one legal unit.
     Good enough for retrieval and training data; **not** good enough to cite as
     "article N" of anything, which is why these carry positional citations.

### Latin canon law and Magna Carta

Decretals of Gregory IX (*Liber Extra*, 1234) and Magna Carta (1215), both from
the Latin Library, Public Domain Mark 1.0. The Decretals' citations here are
`X <book>.<chapter>` and **omit the title**, so they are not standard *Liber
Extra* citations (`X 1.2.3`); treat them as positional.

## Not shipped

Hammurabi, Eshnunna, the Hittite laws and Gortyn appear in
`lean/Nomos/Corpus/Mesopotamia.lean`, and the Anglo-Saxon codes, Glanvill,
Bracton, *May v Burdett*, *Cox v Burbidge*, *Rylands v Fletcher* and the
Animals Act 1971 appear in `lean/Nomos/Corpus/Anglia.lean`, **as citations plus
editorial restatements**, with `text: null` and `text_available: false`.

The restatements are ours. They are a paraphrase of what each provision does,
not a rendering of what it says, and they are marked
`[editorial restatement; text not shipped]` everywhere they appear. **Do not
cite them as translations.** The build environment could not reach Avalon,
Wikisource or sacred-texts, and writing out translations from memory would have
produced something that looked like evidence and was not.

To fill them in:

```bash
python -m nomos.fetch.restricted --list     # what and where
python -m nomos.fetch.restricted            # fetch
```

The tariff figures in particular (LH §251's half-mina, LE §54's forty shekels,
LH §57's rate per unit of land) differ between editions and numbering schemes.
Check them against R. Yaron, *The Laws of Eshnunna* (2nd edn, 1988) and Roth,
*Law Collections from Mesopotamia and Asia Minor*, before relying on them. The
*structure* of those rules — which conditions they turn on — we are confident
about; the numbers are the part most worth verifying.

## Editorial additions

The factor assignments, the ratio (`reason`) of each holding, the fact-pattern
groupings and the restatements are all editorial. They are claims about the
sources and they can be wrong. Every one carries the citation it rests on so it
can be checked, which is the point of shipping citations rather than prose.

## A note on the built corpus

`data/corpus/provisions.jsonl.gz` is a **build artefact**, reproducible from
`data/raw/` with `make corpus` in about a minute. It ships gzipped. Readers in
`nomos.schema` handle `.jsonl` and `.jsonl.gz` transparently.

## Code

MIT, `LICENSE`.
