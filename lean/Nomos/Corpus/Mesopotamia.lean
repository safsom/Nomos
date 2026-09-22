/-
# Mesopotamian law: Hammurabi and Eshnunna

## A note on provenance, which matters here more than elsewhere

Unlike the other corpus modules, this one is **not** backed by text shipped
with the repository.  The public-domain translations (Harper 1904, King 1915)
were not reachable from the environment in which this library was built, and
writing out translations from memory would be worse than useless -- it would
look like evidence.

So the holdings below are formalised from **citations plus our own editorial
restatements**, and the restatements are labelled as such.  They are our
paraphrase of what the provision does, not a rendering of what it says.  Each
carries a confidence marker in `data/seed/formalizations.jsonl`, and
`src/nomos/fetch/restricted.py` will fetch the actual public-domain
translations and attach them to these citations when run somewhere with
ordinary network access.

Anyone building on this should re-check the numbers.  The *structure* of the
rules -- which conditions the provisions turn on -- we are confident about; the
*tariffs* are exactly the kind of detail that differs between editions and
numbering schemes, and they are the part most worth verifying.

## Why these provisions

The Mesopotamian goring-ox rules are the reason the comparative question is
interesting at all.  Laws of Eshnunna §§53-55 and Laws of Hammurabi §§250-252
make the same three-part distinction as Exodus 21:28-32 -- no notice, notice
given, and a separate lower tariff where the victim is a slave -- and they do
it in the same order, two to five centuries earlier.  The relationship between
them is one of the oldest live questions in comparative legal history.  What
this library adds is not an answer but a way of stating the question precisely:
see `Nomos.Bench.GoringOx`.
-/

import Nomos.Reasoning.Precedent

namespace Nomos.Corpus.Mesopotamia

open Nomos

/-- An ox gores a free man in the street; nothing was known against it. -/
def innocuousGoreOfPerson : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.behavedAnomalously]⟩

/-- The ox was known to gore, the ward authorities had notified the owner, and
he neither blunted its horns nor confined it. -/
def forewarnedGoreOfPerson : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.knownVice, Factor.warned, Factor.noPrecaution]⟩

/-- A shepherd pastures his flock on another's field without leave. -/
def grazingWithoutLeave : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.withoutLeave,
    Factor.inPublicOrClaimantsGround, Factor.respondentBenefited]⟩

/-- A builder's house collapses and kills the householder. -/
def collapsedHouse : Situation :=
  ⟨[Factor.harmOccurred, Factor.harmToPerson, Factor.professedSkill,
    Factor.respondentActedDirectly, Factor.respondentBenefited]⟩

/-- **LH §250** (editorial restatement).  An ox gores a man in the street and
he dies: the case carries no penalty.

The parallel with Exodus 21:28 is close -- both exempt the owner of the
un-forewarned beast -- but not identical: Exodus destroys the ox, and
Hammurabi does not. -/
def lh250 : Precedent :=
  { cite := "LH §250 [editorial restatement; text not shipped]"
  , situation := innocuousGoreOfPerson
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.behavedAnomalously] }

/-- **LH §251** (editorial restatement).  The ox was known to gore, the ward
authorities notified the owner, and he did not blunt its horns or tie it up; it
gores a free man and he dies.  The owner pays one-half mina -- thirty shekels
-- of silver.

Thirty shekels is also Exodus 21:32's tariff for a gored slave.  Whether that
is coincidence, shared convention, or dependence is exactly the question
`Nomos.Bench.GoringOx` is built to state precisely. -/
def lh251 : Precedent :=
  { cite := "LH §251 [editorial restatement; text not shipped]"
  , situation := forewarnedGoreOfPerson
  , winner := Side.claimant
  , remedy := Remedy.tariff (Quantity.shekels 30)
  , reason := [Factor.knownVice, Factor.warned, Factor.noPrecaution] }

/-- **LH §252** (editorial restatement).  If the victim is a man's slave, the
owner pays one-third of a mina -- twenty shekels. -/
def lh252 : Precedent :=
  { cite := "LH §252 [editorial restatement; text not shipped]"
  , situation := forewarnedGoreOfPerson
  , winner := Side.claimant
  , remedy := Remedy.tariff (Quantity.shekels 20)
  , reason := [Factor.knownVice, Factor.warned] }

/-- **LH §57** (editorial restatement).  A shepherd who has not agreed with the
owner of a field, and pastures his flock there without the owner's consent:
the owner harvests his field, and the shepherd additionally gives over grain at
a stated rate per unit of land.

The rate (Harper: twenty gur per ten gan) is among the numbers most worth
re-checking against an edition. -/
def lh57 : Precedent :=
  { cite := "LH §57 [editorial restatement; text not shipped]"
  , situation := grazingWithoutLeave
  , winner := Side.claimant
  , remedy := Remedy.both
                (Remedy.inKind "the owner harvests his own field")
                (Remedy.tariff (Quantity.gur 20))
  , reason := [Factor.withoutLeave, Factor.respondentsInstrument] }

/-- **LH §229** (editorial restatement).  A builder who does not make his work
firm, so that the house collapses and kills the householder, is put to death.

The Covenant Code has no builder's rule; Roman law reaches the case through
*locatio conductio operis* and awards damages (see D.19.2 generally).  Three
orders, three remedies, one fact pattern. -/
def lh229 : Precedent :=
  { cite := "LH §229 [editorial restatement; text not shipped]"
  , situation := collapsedHouse
  , winner := Side.claimant
  , remedy := Remedy.capital
  , reason := [Factor.professedSkill, Factor.harmToPerson] }

/-- **LE §53** (editorial restatement).  An ox gores another ox and it dies:
the two owners divide the price of the live ox and the carcass of the dead one.

Exodus 21:35 gives the identical rule, in the identical form -- division of
both the living animal's price and the carcass.  Of all the parallels in the
corpus this is the closest, and it is the one hardest to attribute to
convergent invention. -/
def le53 : Precedent :=
  { cite := "LE §53 [editorial restatement; text not shipped]"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
                   Factor.behavedAnomalously]⟩
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.halfDamage
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument] }

/-- **LE §54** (editorial restatement).  The ox was a known gorer, the ward
authorities notified the owner, he did not keep it in check, and it gores a man
to death: the owner pays two-thirds of a mina -- forty shekels -- of silver. -/
def le54 : Precedent :=
  { cite := "LE §54 [editorial restatement; text not shipped]"
  , situation := forewarnedGoreOfPerson
  , winner := Side.claimant
  , remedy := Remedy.tariff (Quantity.shekels 40)
  , reason := [Factor.knownVice, Factor.warned, Factor.noPrecaution] }

def hammurabi : Corpus :=
  ⟨"Laws of Hammurabi [restatements]", [lh250, lh251, lh252, lh57, lh229]⟩

def eshnunna : Corpus :=
  ⟨"Laws of Eshnunna [restatements]", [le53, le54]⟩

def corpus : Corpus := Corpus.merge hammurabi eshnunna

theorem corpus_sound : corpus.Sound := by decide

end Nomos.Corpus.Mesopotamia
