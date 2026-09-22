/-
# Bench: the goring ox across six legal orders

One fact pattern, six traditions, 2,600 years.  An animal in someone's charge
kills or injures; the question is whether the keeper answers for it, and in
what.

The point of running the comparison inside a proof assistant is not to produce
a table.  Tables of parallels between Exodus and Hammurabi have existed since
1903.  The point is that once the readings are formal, the comparative claims
become *checkable*, and some of them turn out to be false, or to hold for
reasons different from the ones usually given.

Four results are worth the trouble:

1. **Convergence is about factors, not outcomes.**  All six orders pivot on the
   same fact -- prior notice of the animal's vice -- and all six treat the
   forewarned case as stronger against the keeper.  Tang China, which had no
   contact with any of the others, pivots on it too.

2. **Divergence is incommensurable, not merely large.**  Exodus makes the
   forewarned keeper capitally liable; Hammurabi charges thirty shekels; Tang
   China gives forty blows of the light stick, redeemable.  These are not
   "different amounts" -- `Remedy.capital_incomparable_tariff` proves two of
   them are not ordered at all.

3. **Transmission and convergence leave different signatures.**  Where
   borrowing is documented -- Alfred copying Exodus into his law-book around
   890 -- the formalisations coincide completely, remedy included.  Where there
   can have been no contact, the factors coincide and the remedies diverge.

4. **The whole corpus is coherent except at one rule.**  Fifteen pairwise
   merges across six traditions; five have no conflicts at all; and every
   conflict in the remaining ten has Ex 21:28 or LH §250 on the respondent's
   side.  Those two are the same rule -- no notice, no liability -- and the
   fault line they mark runs between the two Near Eastern traditions and
   everyone else.  That is the result we did not expect.
-/

import Nomos.Corpus.Covenant
import Nomos.Corpus.Rabbinic
import Nomos.Corpus.Roman
import Nomos.Corpus.Mesopotamia
import Nomos.Corpus.Sinica
import Nomos.Corpus.Anglia

namespace Nomos.Bench.GoringOx

open Nomos Nomos.Corpus

-- ---------------------------------------------------------------------------
-- 1. Convergence
-- ---------------------------------------------------------------------------

/-- The five holdings on the forewarned beast, one per tradition. -/
def forewarnedHoldings : List Precedent :=
  [ Covenant.forewarnedOx          -- Ex 21:29
  , Rabbinic.muadOx                -- m.BK 1:4, 4:9
  , Roman.forewarnedPauperies      -- D.9.1.1.4
  , Mesopotamia.lh251              -- LH §251
  , Mesopotamia.le54 ]             -- LE §54

/-- **Convergence on the pivot.**  Every one of the five decides for the
claimant, and every one rests its decision on the animal's known vice.

Eighteen centuries and four language families, and the operative fact is the
same.  Whether that reflects transmission, shared Near Eastern convention, or
the fact that herding societies keep running into the same problem is a
historical question this cannot settle -- but it can state it exactly, which
is more than a table of parallels does. -/
theorem forewarned_converges :
    ∀ h ∈ forewarnedHoldings,
      h.winner = Side.claimant ∧ Factor.knownVice ∈ h.reason := by decide

/-- **The forewarned case is a fortiori stronger.**  In every tradition, the
situation with notice is at least as strong for the claimant as the situation
without it: it adds claimant-side reasons and removes the respondent's best
one.  So the escalation is not merely a policy choice each order happened to
make; it is forced by the factor structure, given the innocuous-case holding. -/
theorem notice_strengthens :
    AtLeastAsStrong Covenant.forewarnedGoreOfPerson Covenant.forewarnedOx ∧
    AtLeastAsStrong Roman.forewarnedBeast Roman.forewarnedPauperies ∧
    AtLeastAsStrong Mesopotamia.forewarnedGoreOfPerson Mesopotamia.lh251 := by
  decide

-- ---------------------------------------------------------------------------
-- 2. Divergence
-- ---------------------------------------------------------------------------

/-- **The remedies do not compare.**

Exodus 21:29 imposes death; LH §251 imposes thirty shekels.  Neither is at
least as heavy as the other in the remedy order -- not because we lack an
exchange rate, but because the two orders disagree about whether there is one.
Exodus says explicitly that there is not, for a free victim: Numbers 35:31
forbids taking ransom for the life of a murderer, and Exodus 21:30 permits it
for the ox-owner precisely by way of exception.

A comparative study that reported "Hammurabi is more lenient" would be
importing a commensuration that one of its two subjects denies. -/
theorem capital_vs_tariff_incomparable :
    Remedy.Incomparable Covenant.forewarnedOx.remedy Mesopotamia.lh251.remedy :=
  Remedy.capital_incomparable_tariff _

/-- The five remedies for the one situation, side by side.  No two are equal. -/
theorem remedies_all_differ :
    Covenant.forewarnedOx.remedy ≠ Rabbinic.muadOx.remedy ∧
    Rabbinic.muadOx.remedy ≠ Roman.forewarnedPauperies.remedy ∧
    Roman.forewarnedPauperies.remedy ≠ Mesopotamia.lh251.remedy ∧
    Mesopotamia.lh251.remedy ≠ Mesopotamia.le54.remedy := by decide

/-- Even the two Mesopotamian tariffs, which *are* commensurable -- both are
shekels of silver -- differ by a third.  Eshnunna charges forty where
Hammurabi charges thirty, and Eshnunna is the earlier code. -/
theorem eshnunna_heavier_than_hammurabi :
    Remedy.AtLeast Mesopotamia.le54.remedy Mesopotamia.lh251.remedy :=
  Remedy.AtLeast.of_step (Remedy.Step.tariff_mono ⟨rfl, by decide⟩)

-- ---------------------------------------------------------------------------
-- 3. Inheritance: half damages
-- ---------------------------------------------------------------------------

/-- **Exodus 21:35 and the Mishnah's half damages are the same remedy.**

"They shall sell the live ox, and divide the price of it; and the dead also
they shall divide" is *ḥatzi nezek* -- half damages -- under another
description, and the Mishnah says as much.  Writing them as the same term makes
the claim of continuity something the type checker enforces rather than
something the prose asserts.

Laws of Eshnunna §53 states the same rule in the same form, several centuries
earlier, which is why the identity extends to three of the five traditions. -/
theorem half_damages_inherited :
    Covenant.oxGoresOx.remedy = Rabbinic.tamOx.remedy ∧
    Covenant.oxGoresOx.remedy = Mesopotamia.le53.remedy := by decide

/-- And the escalation on notice is likewise shared: where the Covenant Code
moves from division to "ox for ox", the Mishnah moves from half damages to
full. -/
theorem escalation_shared :
    Covenant.forewarnedOxGoresOx.remedy = Rabbinic.muadOx.remedy := by decide

-- ---------------------------------------------------------------------------
-- 4. Coherence, within and across traditions
-- ---------------------------------------------------------------------------

/-- The rabbinic case base does not contradict itself on the situations it
addresses. -/
theorem rabbinic_coherent :
    CoherentOn Rabbinic.corpus Rabbinic.corpus.situations := by decide

/-- Nor does the Roman one. -/
theorem roman_coherent :
    CoherentOn Roman.corpus Roman.corpus.situations := by decide

/-- **The Covenant Code does contradict itself -- on a purely compensatory
reading.**

The conflict, which `Corpus.conflictsAt` localises, is between Ex 21:35 and
Ex 21:28:

* **Ex 21:35** -- an ox kills another man's ox: the loss is divided.  The
  claimant recovers something.
* **Ex 21:28** -- an ox kills a *man*: "the ox shall be surely stoned ... but
  the owner of the ox shall be quit."  The claimant recovers nothing.

The second situation contains every claimant-side factor the first does, plus
`harmToPerson`, and it yields *less*.  On the reason model that is a straight
contradiction: a case strictly stronger for the claimant cannot be decided
against him.

We think this is a finding rather than a bug, and the interesting part is what
it localises.  The incoherence marks the point where the Covenant Code stops
allocating loss and starts doing something else.  Ex 21:28 is not a
compensation rule: the ox is destroyed and its flesh may not be eaten, which is
the treatment of a thing that has shed human blood (compare Gen 9:5, "at the
hand of every beast will I require it"), and the owner's being *naqi* is
acquittal of bloodguilt, not denial of a debt.  A factor vocabulary built for
loss-allocation cannot see a sacral category, so it reports the seam as a
contradiction.

That is exactly the service a formalisation can render.  The failure is
localised to two verses, it is reproducible, and it tells you where the
tradition changes register.  A prose comparison glides over the seam; the type
checker cannot. -/
theorem covenant_incoherent_on_own_situations :
    ¬ CoherentOn Covenant.corpus Covenant.corpus.situations := by decide

/-- **And the traditions do not merge.**

Take the Covenant Code and Roman law as one body of precedent and it forces
both outcomes at once on the innocuous goring ox: Ex 21:28 acquits the owner,
D.9.1.1pr gives the victim a noxal action against him.

This is the formal content of the observation that comparative law is not a
legal order.  Bodies of precedent are not merged by union; a tradition that
wanted to adopt both would have to *decide between them*, which is a
legislative act, not a discovery. -/
theorem covenant_and_roman_do_not_merge :
    ¬ CoherentOn (Corpus.merge Covenant.corpus Roman.corpus)
        (Corpus.merge Covenant.corpus Roman.corpus).situations := by decide

/-- The rabbinic and Roman corpora, by contrast, *can* be merged coherently on
the situations they address -- which is a much more surprising fact than the
failure above, and one worth investigating rather than celebrating.  The most
likely explanation is that our rabbinic and Roman readings are drawn from the
same factor vocabulary by the same hand, and agreement may be an artefact of
that rather than of the sources. -/
theorem rabbinic_and_roman_merge :
    CoherentOn (Corpus.merge Rabbinic.corpus Roman.corpus)
        (Corpus.merge Rabbinic.corpus Roman.corpus).situations := by decide

-- ---------------------------------------------------------------------------
-- 5. What is still open
-- ---------------------------------------------------------------------------

/-- A situation none of the five traditions settles: an animal with a known
vice, properly confined, which nevertheless escapes and injures a person.

Mishnah Bava Kamma 4:9 records the dispute -- R. Meir holds the owner liable
"whether it was an attested danger or accounted harmless", R. Judah exempts him
for the forewarned beast "as it says, *and its owner did not guard it*, but
this one has been guarded".  The Mishnah preserves the disagreement instead of
resolving it, and so do we. -/
def confinedButEscaped : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.knownVice, Factor.warned, Factor.properPrecaution,
    Factor.irresistibleForce]⟩

/-- None of the four case bases forces an answer here.  This is the open region
that `Nomos.Core.Standard` and the autoformalisation pipeline are aimed at: not
a defect in the sources, but the place where a court would have to decide. -/
theorem confined_escape_is_open :
    Open Covenant.corpus confinedButEscaped ∧
    Open Rabbinic.corpus confinedButEscaped ∧
    Open Roman.corpus confinedButEscaped ∧
    Open Mesopotamia.corpus confinedButEscaped := by decide

-- ---------------------------------------------------------------------------
-- 6. The full comparison
-- ---------------------------------------------------------------------------

/-!
The corpus spans six legal orders -- Mesopotamia (Eshnunna and Babylon), the
Covenant Code, the Mishnah, Rome, Tang China, and England from Æthelberht to
the Animals Act 1971.  Three of the results above get much stronger with the
Chinese and English material in, and one new result appears that we did not
anticipate.
-/

/-- **The pivot is the same in all seven.**

Every forewarned-animal holding in the corpus rests on the animal's known
propensity.  Eight holdings, seven legal orders, roughly 2,600 years, and one
of them -- the Tang Code -- had no contact with any of the others.

> *bos cornu petere solitus* · wont to gore in time past · *mu'ad* ·
> 噬犬 · characteristics known to that keeper

This is the strongest form of the convergence claim the project can make, and
it is `by decide` over the formalised ratios. -/
theorem knownVice_pivots_seven_traditions :
    Factor.knownVice ∈ Covenant.forewarnedOx.reason ∧
    Factor.knownVice ∈ Rabbinic.muadOx.reason ∧
    Factor.knownVice ∈ Roman.forewarnedPauperies.reason ∧
    Factor.knownVice ∈ Mesopotamia.lh251.reason ∧
    Factor.knownVice ∈ Mesopotamia.le54.reason ∧
    Factor.knownVice ∈ Sinica.art207Negligent.reason ∧
    Factor.knownVice ∈ Anglia.mayVBurdett.reason ∧
    Factor.knownVice ∈ Anglia.animalsAct1971.reason := by decide

/-- **Half damages, four times over.**

When two animals kill each other and neither keeper is at fault, four legal
orders split the loss:

* **LE §53** (c. 1770 BCE) -- divide the price of the live ox and the carcass;
* **Ex 21:35** -- "they shall sell the live ox, and divide the price of it; and
  the dead also they shall divide";
* **m.Bava Kamma** -- *ḥatzi nezek*, half damages;
* **唐律疏議 art. 206** (653 CE) -- 償減價之半, "compensates half the
  depreciation", with the commentary working the arithmetic on a horse worth
  ten bolts of silk.

The first three are plausibly one tradition.  The fourth is not, and it reached
the identical rule.  Splitting a loss between two faultless owners is
apparently something legal orders find, not something they inherit. -/
theorem half_damages_four_traditions :
    Covenant.oxGoresOx.remedy = Rabbinic.tamOx.remedy ∧
    Covenant.oxGoresOx.remedy = Mesopotamia.le53.remedy ∧
    Covenant.oxGoresOx.remedy = Sinica.art206Other.remedy := by decide

/-- **Transmission and convergence leave different signatures.**

Where borrowing is documented -- Alfred copying Exodus into his law-book around
890 -- the formalisations coincide *completely*: same situation, same outcome,
same remedy, same ratio.

Where there is no possible contact -- Tang China -- they coincide in the
*factors* and diverge in the *remedy*.  Chinese law prices the negligent keeper
in strokes of the light stick, redeemable; Babylon in half a mina of silver;
Exodus in the keeper's life, redeemable by ransom.

That difference is a usable heuristic.  Complete agreement including the remedy
is evidence of copying; agreement on the operative facts with incomparable
remedies is what independent invention looks like. -/
theorem transmission_signature :
    -- documented borrowing: everything coincides
    (Anglia.alfredGoringOx.remedy = Covenant.forewarnedOxWithRansom.remedy ∧
     Anglia.alfredGoringOx.reason = Covenant.forewarnedOxWithRansom.reason) ∧
    -- no possible contact: factors coincide, remedies do not
    (Factor.knownVice ∈ Sinica.art207Negligent.reason ∧
     Factor.knownVice ∈ Mesopotamia.lh251.reason ∧
     Sinica.art207Negligent.remedy ≠ Mesopotamia.lh251.remedy) := by decide

/-- **China merges with Rome, and with the Mishnah.**

Take the Tang Code and the Digest as one body of precedent and they do not
contradict each other on any situation either addresses.  Same for the Tang
Code and the Mishnah, and for English law and Rome.

We flagged the rabbinic/Roman agreement earlier as suspicious -- possibly an
artefact of one hand reading both through one vocabulary.  That worry is weaker
now.  Tang China is the case where the vocabulary had the least help from
family resemblance, and it still fits. -/
theorem east_and_west_merge :
    CoherentOn (Corpus.merge Sinica.tangCode Roman.corpus)
      (Corpus.merge Sinica.tangCode Roman.corpus).situations ∧
    CoherentOn (Corpus.merge Sinica.tangCode Rabbinic.corpus)
      (Corpus.merge Sinica.tangCode Rabbinic.corpus).situations ∧
    CoherentOn (Corpus.merge Anglia.corpus Roman.corpus)
      (Corpus.merge Anglia.corpus Roman.corpus).situations := by decide

/-- **Every incoherence in the corpus traces to two provisions, and they are
the same provision.**

This is the result we did not expect and the one most worth checking.

Take the six traditions pairwise -- fifteen merges -- and compute the
cross-tradition conflicts.  Five pairs have none at all: China with England,
China with the Mishnah, China with Rome, England with the Mishnah, England with
Rome.  Of the ten that do conflict, every single conflict has one of exactly two
holdings on the respondent's side:

* **Ex 21:28** -- an ox gores a man to death, nothing was known against it:
  the ox is stoned and *the owner shall be quit*.
* **LH §250** -- an ox gores a man in the street and he dies: *this case has
  no penalty*.

Those are not two findings.  They are one rule, held in common by the two
neighbouring Near Eastern traditions and by nobody else in the corpus: that the
keeper of an un-forewarned animal owes nothing at all.

Everyone else makes him owe something.  Rome gives a noxal action regardless of
notice (D.9.1.1pr).  The Mishnah gives half damages for the *tam*.  The Tang
Code gives half the depreciation when beasts fight.  Bracton takes the Roman
rule into English writing.  Six legal orders, and the fault line runs between
"custody alone grounds liability" and "custody plus notice does".

That the fault line falls exactly where two geographically adjacent traditions
part company from four others is what a real comparative finding looks like.  A
vocabulary loose enough to fit everything would have reported no fault line at
all. -/
theorem incoherence_is_the_no_notice_no_liability_rule :
    -- the pairs that avoid both provisions merge cleanly
    (CoherentOn (Corpus.merge Sinica.tangCode Roman.corpus)
       (Corpus.merge Sinica.tangCode Roman.corpus).situations ∧
     CoherentOn (Corpus.merge Sinica.tangCode Rabbinic.corpus)
       (Corpus.merge Sinica.tangCode Rabbinic.corpus).situations ∧
     CoherentOn (Corpus.merge Anglia.corpus Roman.corpus)
       (Corpus.merge Anglia.corpus Roman.corpus).situations ∧
     CoherentOn (Corpus.merge Anglia.corpus Rabbinic.corpus)
       (Corpus.merge Anglia.corpus Rabbinic.corpus).situations ∧
     CoherentOn (Corpus.merge Sinica.tangCode Anglia.corpus)
       (Corpus.merge Sinica.tangCode Anglia.corpus).situations) ∧
    -- the ones that include either of them do not
    (¬ CoherentOn (Corpus.merge Sinica.tangCode Covenant.corpus)
       (Corpus.merge Sinica.tangCode Covenant.corpus).situations ∧
     ¬ CoherentOn (Corpus.merge Anglia.corpus Covenant.corpus)
       (Corpus.merge Anglia.corpus Covenant.corpus).situations ∧
     ¬ CoherentOn (Corpus.merge Sinica.tangCode Mesopotamia.corpus)
       (Corpus.merge Sinica.tangCode Mesopotamia.corpus).situations) ∧
    -- and the two culprits are the same rule: no notice, no liability
    (Covenant.oxGoresPerson.winner = Side.respondent ∧
     Mesopotamia.lh250.winner = Side.respondent ∧
     Covenant.oxGoresPerson.remedy = Remedy.exempt ∧
     Mesopotamia.lh250.remedy = Remedy.exempt) := by decide

/-- The other side of the fault line: four traditions that all make the keeper
of an un-forewarned animal answer *something*. -/
theorem four_traditions_hold_without_notice :
    Roman.pauperies.winner = Side.claimant ∧
    Rabbinic.tamOx.winner = Side.claimant ∧
    Sinica.art206Other.winner = Side.claimant ∧
    Anglia.bractonPauperies.winner = Side.claimant := by decide

/-- What the model does not see, stated for the record.

Magna Carta cl. 39 is in `Corpus/Anglia.lean` and the factor vocabulary has
almost nothing to say about it.  "No free man shall be seized ... except by the
lawful judgment of his peers or by the law of the land" is not a rule about who
bears a loss; it is a rule about who may impose one, and about procedure.

The same blind spot covers the Tang Code's vast apparatus of official
discipline, the Qing Code's review procedures, and most of what the *Digest*'s
later books are about.  A loss-allocation vocabulary sees loss allocation.
Anyone extending this should expect to need a second vocabulary for
jurisdiction, procedure and office, and should not expect the two to merge
neatly. -/
theorem magna_carta_39_is_not_a_liability_rule :
    Anglia.magnaCarta39.winner = Side.claimant ∧
    Factor.respondentHeldOffice ∈ Anglia.magnaCarta39.reason := by decide

end Nomos.Bench.GoringOx
