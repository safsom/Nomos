# Research notes

The formal architecture, dependencies, limitations, and theoretical positioning of Nomos.

---

## 1. The problem

Law resists formalisation for three structural reasons. First, vagueness: terms like "due care" or "undue hardship" possess no rigid definitions and will never acquire them. Second, legal reasoning is ampliative by design. Adjudication extends rules by analogy, distinguishes novel facts, and applies delayed exceptions. A formalism treating law as static propositions with fixed consequences models a non-existent system. Finally, there is no ground truth. Unlike mathematics, where autoformalisation is verifiable via proof, a well-typed formalisation of a statute can be syntactically perfect, fluent, and entirely legally incorrect without throwing a formal error.

Nomos hypothesizes that modeling legal reasoning as constraint by decided cases solves these issues. Vagueness becomes a measurable gap in the case record, analogical extension becomes a provable relational property, and formalisations become mechanically checkable against the coherence of surrounding case law.

---

## 2. Core commitments

Nomos relies on five core commitments. First, liability is the primitive. Private and commercial law operate on exposure to loss, not rights. Rights are exactly derived from liability arrays (via `privilege_is_waiver`). Consequently, public law—such as jurisdiction and procedure—falls outside this model. 

Second, facts are one-sided reasons. Following HYPO and CATO, a factor is a factual pattern favoring exactly one party. Facts cutting both ways are modeled as two distinct factors, a strictness required to make the *a fortiori* relation mathematically well-defined. 

Third, precedential constraint is *a fortiori*. A precedent binds a future case only if the new case is at least as strong for the winner. It must contain every fact the earlier tribunal relied upon and introduce no novel counter-reasons. Mere factual similarity does not constrain.

Fourth, vague standards are comparatives plus records. Standards are formalized strictly as an ordering on conduct combined with a historical ledger of what satisfied or failed the standard, leaving the boundary threshold intentionally undefined.

Finally, everything remains decidable. Constraint, coherence, and conflict detection are modeled as finite conditions over fact sets (computable via Lean's `decide`). This enables sub-15-second build times and allows the verifier to run efficiently inside LLM generation loops.

---

## 3. Positioning and dependencies

Nomos mechanises Horty and Bench-Capon's definitions of precedential constraint, which build on Ashley’s HYPO and Aleven’s CATO. It implements Hohfeld's eight incidents and opposition tables, but derives them computationally from liability rather than positing them as basic axioms (contrasting with Sergot 2001 or Markovich 2020). For its automated pipeline, it utilizes standard neural theorem proving methodologies, including retrieval-augmented generation and rejection sampling against a proof assistant.

Nomos differs fundamentally from legal DSLs like Catala. Where Catala targets statutory computation (e.g., tax law) to output definitive numerical values, Nomos targets adjudicative law, calculating precedential constraint where there is no mathematical output.

---

## 4. Why not deontic logic?

Despite the availability of mechanised modal and deontic logics, Nomos rejects `O(φ)` (obligation) formalisms for casuistic case law. Ancient codes state penalties ("if X happens, pay Y") rather than obligations ("you ought to do X"). Reconstructing obligations from penalties takes a contested interpretive stance. Furthermore, real legal rules arrive flat, with exceptions legislated later. Defeasible deontic logics require heavy machinery to handle this, whereas plain prioritized rules (`Core/Defeasance.lean`) achieve this efficiently and yield a determinacy theorem. Introducing modal semantics interposes abstraction without computational benefit, sacrificing the speed required for in-loop verification.

---

## 5. Current state and remaining work

The formalism currently validates 60 rules from six distinct legal traditions over 2,600 years in a unified factor vocabulary. The verifier successfully identifies human reasoning errors in hand-formalisations—such as backward party assignments—that standard schemas ignore. Thematically, Nomos demonstrates that analogical extension guarantees a lower bound but never a precise value (`no_strengthening`), and natively derives rights from liability.

Remaining work includes proving that a fine-tuned model can learn the cross-tradition mapping independently, which is currently constrained by the small 60-holding seed corpus. It also requires confirming the factor vocabulary scales to larger portions of law and expanding quantitative evaluation beyond the current 15-holding open/forced split.

---

## 6. Threats to validity

Several vulnerabilities exist in the approach. The shared factor vocabulary might reflect author bias rather than legal reality, though the Tang Code—sharing no ancestry with Western law—fits the vocabulary well and correctly surfaced an actual substantive legal contradiction regarding un-forewarned animals between Chinese and Babylonian law. Additionally, applying a common-law constraint model to ancient codes forces the weakest possible reading, assuming the winner's facts represent the entirety of the tribunal's reasoning.

The verifier is also susceptible to gaming: a generative system emitting minimal ratios (e.g., always citing *harm occurred*) passes syntax checks while saying nothing useful. Ratio-agreement on the open stratum is required to catch this. Furthermore, ancient law frequently shifts registers; Exodus 21:28, for instance, addresses ritual pollution, not compensation. The loss-allocation model risks flattening these distinct historical functions. Finally, segmentation of certain Chinese texts into discrete legal units remains historically uneven.

---

## 7. Open problems

Can a model trained on Roman and Rabbinic law accurately formalise the Tang Code zero-shot? Can tools like `Standard.Unsettled` predict where future litigation will occur, such as mapping Delaware efforts-clause disputes against court dockets? Automated coherence checking might also locate textual seams where a tradition fundamentally changes register. 

Other open questions include how the remedy algebra can effectively handle non-quantitative sanctions like enslavement or exile. It is also unclear whether the analogical bound theorem is a truth specifically about law or a broader mathematical truth about analogical inference. Finally, there is the empirical question of whether the "open region" theorem predicts commercial drafting behavior—do parties who define conduct actually litigate less than those who define adverbs?

---

## 8. Sources

**Precedent and case-based reasoning:** J. Horty (2011); J. Horty & T. Bench-Capon (2012); A. Rigoni (2015); K. Ashley (HYPO); V. Aleven (CATO).
**Rights and normative positions:** W. N. Hohfeld (1913, 1917); M. Sergot (2001); R. Markovich (2020).
**Deontic and defeasible logic:** D. Nute (1997); G. Governatori & A. Rotolo (2018).
**Computational law:** D. Merigoux et al. (Catala, 2021); S. Lawsky (2022).
**Commercial and corporate law:** F. Easterbrook & D. Fischel (1985); *Williams Cos. v. Energy Transfer Equity, L.P.* (Del. 2017); *Akorn, Inc. v. Fresenius Kabi AG* (Del. Ch. 2018).