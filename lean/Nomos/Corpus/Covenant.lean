/-
# The Covenant Code (Exodus 21-22)

The densest short body of tort law surviving from the ancient Near East.  In
roughly forty verses it settles the goring ox, the open pit, the straying
beast, the spreading fire, deposit, hire and loan -- the same list the Mishnah
would organise a millennium later and the praetor's edict a few centuries after
that.

Text: *The Holy Scriptures: A New Translation* (Jewish Publication Society,
1917), public domain, via the Sefaria export.  Verse numbering follows the
Hebrew (Masoretic) division, which for chapter 22 runs one verse ahead of most
English Bibles: what is Ex 22:4 here is Ex 22:5 in the KJV tradition.

Every holding below records, in its `cite` field, the verse it comes from, and
the doc-comment quotes the verse.  Where the translation is doing interpretive
work that matters to the formalisation, the comment says so.
-/

import Nomos.Reasoning.Precedent
import Nomos.Core.Defeasance

namespace Nomos.Corpus.Covenant

open Nomos

-- ---------------------------------------------------------------------------
-- Situations
-- ---------------------------------------------------------------------------

/-- An animal in its owner's charge kills a person, with nothing known against
it beforehand. -/
def innocuousGoreOfPerson : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.behavedAnomalously]⟩

/-- The same, where the beast was known to be vicious, the owner was warned,
and he did not confine it. -/
def forewarnedGoreOfPerson : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.knownVice, Factor.warned, Factor.noPrecaution]⟩

/-- One man's ox kills another's, nothing known against it. -/
def innocuousGoreOfBeast : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.behavedAnomalously]⟩

/-- The same, forewarned. -/
def forewarnedGoreOfBeast : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.knownVice, Factor.noPrecaution]⟩

/-- A beast is let loose and feeds in another's field. -/
def grazingTrespass : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.withoutLeave,
    Factor.inPublicOrClaimantsGround]⟩

/-- A pit is dug and left uncovered; a beast falls in. -/
def uncoveredPit : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.respondentActedDirectly, Factor.noPrecaution]⟩

/-- Fire is kindled and spreads. -/
def spreadingFire : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly,
    Factor.respondentsInstrument]⟩

/-- A thing deposited gratuitously is lost without the keeper's hand in it. -/
def gratuitousDepositLost : Situation :=
  ⟨[Factor.harmOccurred, Factor.gratuitousService, Factor.properPrecaution]⟩

/-- A borrowed beast dies or is hurt, the owner not being present. -/
def borrowedBeastLost : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentBenefited, Factor.deviationFromTerms]⟩

/-- The same, but the owner was present. -/
def borrowedBeastOwnerPresent : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentBenefited, Factor.claimantConsented]⟩

-- ---------------------------------------------------------------------------
-- Holdings
-- ---------------------------------------------------------------------------

/-- **Ex 21:28.** "And if an ox gore a man or a woman, that they die, the ox
shall be surely stoned, and its flesh shall not be eaten; but the owner of the
ox shall be quit."

The owner is *naqi*, quit: no liability in damages.  He loses the ox, but he
loses it to destruction, not to the victim's family, so the loss lies where it
falls and this is a holding for the respondent. -/
def oxGoresPerson : Precedent :=
  { cite := "Ex 21:28"
  , situation := innocuousGoreOfPerson
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.behavedAnomalously] }

/-- **Ex 21:29.** "But if the ox was wont to gore in time past, and warning
hath been given to its owner, and he hath not kept it in, but it hath killed a
man or a woman; the ox shall be stoned, and its owner also shall be put to
death."

Three conditions, all three of which the later traditions also isolate: a
propensity, notice of it, and a failure to confine.  The sanction is capital.
**Ex 21:30** immediately qualifies it -- "if there be laid on him a ransom,
then he shall give for the redemption of his life whatsoever is laid upon him"
-- which converts the remedy into an election, formalised in
`forewarnedOxWithRansom`. -/
def forewarnedOx : Precedent :=
  { cite := "Ex 21:29"
  , situation := forewarnedGoreOfPerson
  , winner := Side.claimant
  , remedy := Remedy.capital
  , reason := [Factor.knownVice, Factor.warned, Factor.noPrecaution] }

/-- **Ex 21:29-30 together.**  The capital sanction with the ransom clause:
an election, and the bearer takes the lighter branch. -/
def forewarnedOxWithRansom : Precedent :=
  { forewarnedOx with
    cite := "Ex 21:29-30"
  , remedy := Remedy.orElse Remedy.capital
                (Remedy.inKind "the ransom laid upon him") }

/-- **Ex 21:32.** "If the ox gore a bondman or a bondwoman, he shall give unto
their master thirty shekels of silver, and the ox shall be stoned."

The one place the Covenant Code does put a price on a human life, and it does
so only where the life is a slave's -- which is why the sanction can be a
tariff rather than a capital one.  The comparison with Ex 21:29 is the
sharpest internal evidence that the code's refusal to price the free victim is
deliberate. -/
def oxGoresSlave : Precedent :=
  { cite := "Ex 21:32"
  , situation := ⟨forewarnedGoreOfPerson.factors⟩
  , winner := Side.claimant
  , remedy := Remedy.both (Remedy.tariff (Quantity.shekels 30))
                          (Remedy.inKind "the ox shall be stoned")
  , reason := [Factor.knownVice, Factor.harmToPerson] }

/-- **Ex 21:35.** "And if one man's ox hurt another's, so that it dieth; then
they shall sell the live ox, and divide the price of it; and the dead also they
shall divide."

Division, not compensation.  The loss is split between two faultless owners.
The Mishnah will call this *ḥatzi nezek*, half damages, and we write it with
the same `Loss` term to make the continuity checkable: see
`Nomos.Bench.GoringOx.half_damages_inherited`. -/
def oxGoresOx : Precedent :=
  { cite := "Ex 21:35"
  , situation := innocuousGoreOfBeast
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.halfDamage
  , reason := [Factor.respondentsInstrument] }

/-- **Ex 21:36.** "Or if it be known that the ox was wont to gore in time past,
and its owner hath not kept it in; he shall surely pay ox for ox, and the dead
beast shall be his own."  Full compensation once notice is established. -/
def forewarnedOxGoresOx : Precedent :=
  { cite := "Ex 21:36"
  , situation := forewarnedGoreOfBeast
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.knownVice, Factor.noPrecaution] }

/-- **Ex 22:4** (MT; = 22:5 in most English Bibles).  "If a man cause a field
or vineyard to be eaten, and shall let his beast loose, and it feed in another
man's field; of the best of his own field, and of the best of his own vineyard,
shall he make restitution."

The remedy is `inKind` and not `compensate`, because the specification of
quality -- *meitav*, "of the best" -- is doing legal work.  The Mishnah reads
it as a general rule of assessment for all damages (m.BK 1:1, "with the best of
his land"), which it could not do if the phrase were mere emphasis. -/
def grazing : Precedent :=
  { cite := "Ex 22:4"
  , situation := grazingTrespass
  , winner := Side.claimant
  , remedy := Remedy.inKind "of the best of his own field and of the best of his own vineyard"
  , reason := [Factor.respondentsInstrument, Factor.withoutLeave] }

/-- **Ex 21:33-34.** "And if a man shall open a pit, or if a man shall dig a
pit and not cover it, and an ox or an ass fall therein, the owner of the pit
shall make it good; he shall give money unto the owner of them, and the dead
beast shall be his." -/
def pit : Precedent :=
  { cite := "Ex 21:33-34"
  , situation := uncoveredPit
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.respondentActedDirectly, Factor.noPrecaution] }

/-- **Ex 22:5** (MT).  "If fire break out, and catch in thorns ... he that
kindled the fire shall surely make restitution." -/
def fire : Precedent :=
  { cite := "Ex 22:5"
  , situation := spreadingFire
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.respondentActedDirectly] }

/-- **Ex 22:9-10** (MT).  A beast given to keep dies, is hurt or is driven away
unseen: "the oath of the LORD shall be between them both ... and he shall not
make restitution."  The gratuitous keeper is excused on oath. -/
def gratuitousKeeper : Precedent :=
  { cite := "Ex 22:9-10"
  , situation := gratuitousDepositLost
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.gratuitousService, Factor.properPrecaution] }

/-- **Ex 22:13** (MT).  "And if a man borrow aught of his neighbour, and it be
hurt, or die, the owner thereof not being with it, he shall surely make
restitution."  The borrower -- who has the whole benefit -- bears the whole
risk.  This is the Roman *commodatum* rule (D.13.6.5.2) arrived at
independently, and it is the clearest early statement of the principle that
liability tracks benefit. -/
def borrower : Precedent :=
  { cite := "Ex 22:13"
  , situation := borrowedBeastLost
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.value
  , reason := [Factor.respondentBenefited] }

/-- **Ex 22:14** (MT).  "If the owner thereof be with it, he shall not make it
good."  Presence is treated as assumption of the risk. -/
def borrowerOwnerPresent : Precedent :=
  { cite := "Ex 22:14"
  , situation := borrowedBeastOwnerPresent
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.claimantConsented] }

/-- The Covenant Code as a case base. -/
def corpus : Corpus :=
  { name := "Covenant Code (Exodus 21-22)"
  , cases := [oxGoresPerson, forewarnedOx, forewarnedOxWithRansom, oxGoresSlave,
              oxGoresOx, forewarnedOxGoresOx, grazing, pit, fire,
              gratuitousKeeper, borrower, borrowerOwnerPresent] }

/-- Every holding rests only on factors actually present and actually
favouring its winner.  Machine-checked, which is the point: the formalisation
cannot quietly smuggle in a reason the text does not support. -/
theorem corpus_sound : corpus.Sound := by decide

end Nomos.Corpus.Covenant
