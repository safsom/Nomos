/-
# Mishnah Bava Kamma and Bava Metzia

The rabbinic material is the reason this project is tractable at all.  Every
other ancient collection in the corpus gives outcomes without reasons.  This
one gives the reasoning, in a form so close to the factor model that the
translation is almost mechanical -- and it gives it in the second and third
centuries CE, which is worth pausing over.

Three passages carry most of the weight:

* **m.Bava Kamma 1:1** enumerates four paradigm categories of damage,
  distinguishes each from the others, and then extracts what they share in
  order to license extension.  We render the argument as a
  `Reasoning.Analogy.CommonDenominator` and prove, from the Mishnah's own
  distinctions, that its generalisation does not follow from its paradigms.

* **m.Bava Kamma 2:5** records R. Tarfon arguing a fortiori for full damages
  and the Sages answering *dayyo* -- "it is enough that the inferred law be as
  strict as that from which it is inferred".  We show both awards respect the
  precedent, so the dispute is not about what follows.

* **m.Bava Metzia 7:8** grades four classes of bailee by liability, tracking
  who benefits.  Roman law reached the same result independently through the
  doctrine of *utilitas contrahentium* (D.13.6.5.2); see `Nomos.Bench`.

Text: *Mishnah Yomit* translation by Dr. Joshua Kulp (CC-BY), via the Sefaria
export.  Transliterations follow the translation used.
-/

import Nomos.Reasoning.Analogy
import Nomos.Corpus.Covenant

namespace Nomos.Corpus.Rabbinic

open Nomos

-- ---------------------------------------------------------------------------
-- m.Bava Kamma 1:1 -- the four paradigms
-- ---------------------------------------------------------------------------

/-!
"There are four primary causes of injury: the ox and the pit and the
crop-destroying beast and fire.  [The distinctive feature of] the ox is not
like [that of] the crop-destroying beast, nor is [the distinctive feature of]
either of these, which are alive, like [that of] fire, which is not alive; nor
is [the distinctive feature of] any of these, whose way it is to go forth and
do injury, like [that of] the pit, whose way it is not to go forth and do
injury.  What they have in common is that it is their way to do injury and that
you are responsible for caring over them; and if one of them did injury whoever
[is responsible] for the injury must make restitution [to the damaged party]
with the best of his land."

The structure is: four paradigms, pairwise distinctions, a common denominator,
then a general rule.  Rendering it requires us to say which factor carries each
paradigm's distinctiveness, and that is an interpretive choice we should state
openly:

* **ox** (*keren*, horn) -- `intentToHarm`.  The classical distinction between
  horn and tooth is that the goring animal means the injury and gains nothing
  by it, where the grazing animal eats for its own good.
* **crop-destroying beast** (*shen*, tooth) -- `respondentBenefited`.  The
  classical distinction between tooth and horn is precisely that the animal
  (and so its owner) *gains* by eating.
* **fire** -- `respondentActedDirectly`.  Fire is not alive; someone kindled
  it, so the human act is immediate.
* **pit** -- `noPrecaution`.  The pit's distinctiveness in the Mishnah's own
  words is that "its way is not to go forth": it is a static hazard, and what
  is culpable is leaving it so.

Other readings are defensible.  What matters formally is only that each
paradigm carry *some* factor the others lack, which is exactly what the
Mishnah's middle section is at pains to establish.
-/

def oxSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.intentToHarm]⟩

def toothSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.respondentBenefited]⟩

def fireSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.respondentActedDirectly]⟩

def pitSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.noPrecaution]⟩

/-- The remedy m.BK 1:1 lays down for all four: restitution "with the best of
his land" (*meitav*), which the Mishnah reads out of Ex 22:4. -/
def meitav : Remedy := Remedy.inKind "with the best of his land"

def avOx : Precedent :=
  { cite := "m.BK 1:1 (ox / keren)", situation := oxSituation
  , winner := Side.claimant, remedy := meitav
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument, Factor.intentToHarm] }

def avTooth : Precedent :=
  { cite := "m.BK 1:1 (crop-destroying beast / shen)", situation := toothSituation
  , winner := Side.claimant, remedy := meitav
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument, Factor.respondentBenefited] }

def avFire : Precedent :=
  { cite := "m.BK 1:1 (fire / esh)", situation := fireSituation
  , winner := Side.claimant, remedy := meitav
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument, Factor.respondentActedDirectly] }

def avPit : Precedent :=
  { cite := "m.BK 1:1 (pit / bor)", situation := pitSituation
  , winner := Side.claimant, remedy := meitav
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument, Factor.noPrecaution] }

def avot : List Precedent := [avOx, avTooth, avFire, avPit]

/-- *Ha-tzad ha-shaveh she-bahen* -- "the common feature among them": "it is
their way to do injury and ... you are responsible for caring over them". -/
def commonDenominator : CommonDenominator avot :=
  { shared := [Factor.harmOccurred, Factor.respondentsInstrument]
  , shared_nonempty := by decide
  , shared_in_each := by decide
  , irredundant := by decide }

/-- **The Mishnah's generalisation is ampliative.**

The four paradigms, together with the Mishnah's own demonstration that each is
distinctive, do not force any outcome in the situation consisting of just the
common feature.  The closing rule -- "if one of them did injury whoever is
responsible must make restitution" -- is therefore legislation, not deduction.

This is not a criticism of the Mishnah.  It is a description of what the
Mishnah is doing, and the Mishnah's care in establishing the distinctions is
precisely what makes the description provable. -/
theorem generalisation_is_ampliative (side : Side) :
    ¬ Forces ⟨"m.BK 1:1 paradigms", avot⟩ ⟨commonDenominator.shared⟩ side :=
  common_denominator_underdetermines commonDenominator side

/-- The rule the Mishnah actually lays down, recorded as the new holding it is. -/
def generalRule : Precedent :=
  generalise avot commonDenominator Side.claimant meitav
    "m.BK 1:1 (general rule: the common feature)"

/-- Once stated, it settles the case the paradigms left open. -/
theorem general_rule_settles :
    Forces (Corpus.add ⟨"m.BK 1:1 paradigms", avot⟩ generalRule)
      ⟨commonDenominator.shared⟩ Side.claimant :=
  generalise_forces avot commonDenominator Side.claimant meitav _ (by decide)

-- ---------------------------------------------------------------------------
-- m.Bava Kamma 1:4 and 2:5 -- tam, mu'ad, and dayyo
-- ---------------------------------------------------------------------------

/-- Horn damage in the public domain by an innocuous (*tam*) ox: half damages.
Common ground between R. Tarfon and the Sages. -/
def hornInPublicSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.behavedAnomalously]⟩

/-- The same, in the injured party's own domain: an additional reason for the
claimant, and so a fortiori stronger. -/
def hornInPrivateSituation : Situation :=
  ⟨[Factor.inPublicOrClaimantsGround, Factor.harmOccurred,
    Factor.respondentsInstrument, Factor.behavedAnomalously]⟩

/-- **m.BK 1:4 / 2:5 common ground.**  "If it gored, pushed, bit, lay down, or
kicked in the public domain its owner pays only half damages." -/
def hornInPublic : Precedent :=
  { cite := "m.BK 2:5 (agreed: horn in the public domain)"
  , situation := hornInPublicSituation
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.halfDamage
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument] }

/-- The private-domain case is a fortiori stronger for the claimant: it adds a
reason and takes none away.  This is R. Tarfon's premise, and the Sages do not
deny it. -/
theorem private_is_stronger : AtLeastAsStrong hornInPrivateSituation hornInPublic := by
  decide

/-- **The Sages' award.**  Extend the rule and add nothing: half damages in the
private domain too.  "It is enough if the inferred law is as strict as that
from which it is inferred." -/
theorem sages_admissible :
    ∃ a : Award, a.Respects ⟨"dayyo", [hornInPublic]⟩ ∧
      a hornInPrivateSituation = Remedy.compensate Loss.halfDamage :=
  dayyo hornInPublic hornInPrivateSituation

/-- **R. Tarfon's award.**  Full damages everywhere.  This also respects the
precedent, because full damages is at least half damages. -/
theorem tarfon_admissible :
    (Award.constant (Remedy.compensate Loss.damage)).Respects ⟨"dayyo", [hornInPublic]⟩ := by
  intro c hc s _
  have hce : c = hornInPublic := by simpa using List.mem_singleton.mp hc
  subst hce
  exact Remedy.AtLeast.of_step (Remedy.Step.compensate_mono Loss.PartOf.half)

/-- **The dispute is not about entailment.**

Both positions are consistent with the shared precedent.  R. Tarfon's a
fortiori is valid and yields a *lower bound*; the Sages' *dayyo* is the refusal
to read a lower bound as a value.  `Nomos.Reasoning.Analogy.no_strengthening`
is the general form of the Sages' point.

Anyone building a system that autoformalises rules by analogy inherits this
dispute, whether or not they notice.  A system that emits a specific quantum
where the precedent fixes only a bound has silently taken R. Tarfon's side. -/
theorem dispute_is_about_bounds :
    (∃ a : Award, a.Respects ⟨"dayyo", [hornInPublic]⟩ ∧
        a hornInPrivateSituation = Remedy.compensate Loss.halfDamage) ∧
    (∃ a : Award, a.Respects ⟨"dayyo", [hornInPublic]⟩ ∧
        a hornInPrivateSituation = Remedy.compensate Loss.damage) :=
  ⟨sages_admissible, ⟨Award.constant (Remedy.compensate Loss.damage),
                      tarfon_admissible, rfl⟩⟩

/-- **m.BK 1:4.**  The forewarned (*mu'ad*) ox: "So also is a warned ox [an ox
that has gored before]" among the attested dangers, and by m.BK 4:9 "if the
beast was an attested danger he pays full damages, and if it was accounted
harmless he pays half damages." -/
def muadOx : Precedent :=
  { cite := "m.BK 1:4, 4:9 (mu'ad)"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
                   Factor.knownVice, Factor.warned, Factor.noPrecaution]⟩
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.knownVice, Factor.warned] }

/-- **m.BK 2:4.**  What makes an ox *mu'ad*: "one that people have given
testimony about [that it damaged] for three days" (R. Judah) or "three times"
(R. Meir).  The disagreement is about the threshold of a vague standard, and
is left open here rather than resolved. -/
def tamOx : Precedent :=
  { cite := "m.BK 1:4, 4:9 (tam)"
  , situation := hornInPublicSituation
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.halfDamage
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument] }

-- ---------------------------------------------------------------------------
-- m.Bava Metzia 7:8 -- the four bailees
-- ---------------------------------------------------------------------------

/-!
"There are four kinds of guardians: an unpaid guardian, a borrower, a paid
guardian and a hirer.  An unpaid guardian may take an oath [that he had not
been neglectful] in every case.  A borrower must make restitution in every
case.  A paid guardian or a hirer may take an oath if the beast was injured, or
taken captive or dead, but he must make restitution if it was lost or stolen."

Liability rises with benefit: none for the gratuitous keeper, intermediate for
the one paid, total for the borrower who has the whole use and gives nothing.
-/

def unpaidGuardian : Precedent :=
  { cite := "m.BM 7:8 (shomer chinam)"
  , situation := ⟨[Factor.harmOccurred, Factor.gratuitousService,
                   Factor.properPrecaution]⟩
  , winner := Side.respondent, remedy := Remedy.exempt
  , reason := [Factor.gratuitousService, Factor.properPrecaution] }

def paidGuardian : Precedent :=
  { cite := "m.BM 7:8 (shomer sachar / socher)"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentBenefited,
                   Factor.properPrecaution, Factor.wrongfulTaking]⟩
  , winner := Side.claimant, remedy := Remedy.compensate Loss.value
  , reason := [Factor.respondentBenefited, Factor.wrongfulTaking] }

def borrower : Precedent :=
  { cite := "m.BM 7:8 (sho'el)"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentBenefited]⟩
  , winner := Side.claimant, remedy := Remedy.compensate Loss.value
  , reason := [Factor.respondentBenefited] }

/-- The rabbinic case base. -/
def corpus : Corpus :=
  { name := "Mishnah (Bava Kamma, Bava Metzia)"
  , cases := avot ++ [generalRule, hornInPublic, muadOx, tamOx,
                      unpaidGuardian, paidGuardian, borrower] }

theorem corpus_sound : corpus.Sound := by decide

/-- The borrower's liability swallows the gratuitous keeper's exemption: a
situation exhibiting only `respondentBenefited` is forced for the claimant,
while one exhibiting `gratuitousService` and precaution is not. -/
theorem benefit_drives_liability :
    Forces corpus borrower.situation Side.claimant := by
  refine ⟨borrower, by simp [corpus, avot], rfl, ?_⟩
  exact AtLeastAsStrong.self borrower (by decide)

end Nomos.Corpus.Rabbinic
