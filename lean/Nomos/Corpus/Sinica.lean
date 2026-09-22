/-
# Chinese law: the Tang Code and its successors

## Why this tradition is the control

Every other tradition in this corpus shares a neighbourhood.  Mesopotamia,
Israel, Greece and Rome borrowed from one another, argued with one another, and
in places descend from one another; the rabbinic material is a commentary on
one of them.  A factor vocabulary that fits all of them might be fitting a
family resemblance rather than anything about law.

The Tang Code (唐律疏議, promulgated 653 CE) is the control case.  It was
written by a state with no contact with Rome, Babylon or Israel, in a script
and a philosophical vocabulary with no common ancestor.  If the same factors
describe its rules, that is evidence they track legal structure.  If they do
not, the comparative programme is in trouble and we would want to know.

They do.  Three of its articles map onto the corpus's existing fact patterns
without strain, and one of them arrives at a rule the Near East had reached
independently two thousand years earlier.

## What the Tang Code gives us

* **Art. 207** (畜產蹋人, "domestic animals kicking people") is the goring ox.
  It requires the keeper to mark and tether dangerous animals, punishes
  failure, and escalates sharply if the animal is loosed deliberately.  The
  official commentary quotes the 雜令 (Miscellaneous Ordinances) on what
  marking and tethering means: *an animal that gores -- cut off both horns; one
  that kicks -- hobble its feet; one that bites -- cut off both ears.*

  Compare LH §251, which holds the owner liable where "he did not blunt its
  horns or tie up his ox".  **Blunt the horns or tie it up.**  Two legal
  orders, two thousand years and five thousand kilometres apart, prescribing
  the same two physical precautions in the same order.

* **Art. 206** (犬殺傷畜產) holds the owner of a dog that kills another's
  animal liable for the full depreciation, but where *other* animals kill each
  other, for **half** -- 償減價之半.  That is Exodus 21:35's division of the
  live ox's price and the carcass, Eshnunna §53's identical rule, and the
  Mishnah's *ḥatzi nezek*, arrived at independently.  The commentary even works
  the arithmetic: a horse worth ten bolts of silk, hide and flesh worth two,
  so the depreciation is eight and the payment four.

  And the dog is singled out for the *reason* the Mishnah singles out the
  tooth: 以犬能噬，主須制之 -- "because a dog can bite, the owner must restrain
  it."  Species propensity, known in advance, raising the standard.

* **Art. 204** (官私畜毀食官私物) is grazing trespass: the animal's owner makes
  good what was destroyed, and the property owner who kills the beast *登時*,
  in the very act, is treated leniently.

## What it gives us that nothing else does

**Qing Code art. 44**, 斷罪無正條 ("deciding a case where there is no exact
provision"), is a *statutory rule about reasoning by analogy*:

> 凡律令該載不盡事理，若斷罪無正條者，引律比附，應加應減，定擬罪名，申該上司
> 議定奏聞。若輒斷決，致罪有出入者，以故失論。

"Where the statutes do not exhaustively cover the matter, and there is no exact
provision for deciding the case, cite a statute by analogy (比附), determine
the appropriate increase or decrease, settle the designation of the offence,
and report it upward for deliberation and memorial to the throne.  If an
official decides it outright and the penalty thereby comes out too heavy or too
light, he is punished as for deliberate or negligent misjudgment."

That is the problem `Nomos.Reasoning.Analogy.no_strengthening` formalises,
recognised and legislated about.  The Qing drafters saw that analogical
extension does not fix a quantum -- 應加應減, "the appropriate increase or
decrease", is exactly the gap -- and their answer was procedural rather than
logical: extend if you must, but report it upward, and be personally liable if
you get it wrong.

The Sages said *dayyo*: do not exceed the premise.  The Qing said: you may
exceed it, but not alone and not unaccountably.  Two independent institutional
responses to the same soundness gap, neither of which had heard of the other.

Text: 殆知閣 (Daizhige) transcriptions, simplified characters.  A caution: the
transcription silently drops some rare characters -- 觝 (gore) and 齧 (bite)
are missing from the commentary on art. 207, though the sense survives in
截兩角 / 絆足 / 截兩耳 (horns, feet, ears).  Translations in the comments are
ours.
-/

import Nomos.Reasoning.Precedent
import Nomos.Core.Defeasance

namespace Nomos.Corpus.Sinica

open Nomos

-- ---------------------------------------------------------------------------
-- Situations
-- ---------------------------------------------------------------------------

/-- An animal known to be dangerous injures a person; the keeper did not mark
or tether it as the ordinances require. -/
def unmarkedDangerousBeast : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.knownVice, Factor.noPrecaution]⟩

/-- The keeper loosed it deliberately, knowing what it would do. -/
def deliberateRelease : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.knownVice, Factor.noPrecaution, Factor.intentToHarm]⟩

/-- A dog -- an animal whose biting is a known propensity of its kind -- kills
another's beast. -/
def dogKillsBeast : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.knownVice]⟩

/-- Two beasts fight and one dies.  Neither keeper is at fault and the animals
acted out of character. -/
def beastsFight : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.behavedAnomalously]⟩

/-- An animal destroys or eats another's property. -/
def beastEatsProperty : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.respondentBenefited, Factor.inPublicOrClaimantsGround]⟩

/-- The owner of the damaged property kills the beast in the very act. -/
def killedInTheAct : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly, Factor.defensive,
    Factor.claimantAtFault]⟩

/-- An official's own beasts are loosed and damage property. -/
def officialLoosesBeasts : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.noPrecaution,
    Factor.respondentHeldOffice]⟩

-- ---------------------------------------------------------------------------
-- Holdings
-- ---------------------------------------------------------------------------

/-- **TL art. 207** (畜產蹋人).

> 諸畜產及噬犬有[觝]蹋人，而標幟羈絆不如法，若狂犬不殺者，笞四十；以故殺傷人
> 者，以過失論。若故放令殺傷人者，減鬥殺傷一等。

"In all cases where domestic animals or biting dogs gore or kick people, and
the marking and tethering is not according to law, or where a rabid dog is not
killed: forty blows with the light stick.  Where on that account [the animal]
kills or injures a person, it is dealt with as accidental killing or injury.
Where [the keeper] deliberately looses it so that it kills or injures a person,
[the penalty is] one degree below killing or injuring in an affray."

Two remedies in one article, so two holdings.  This is the first: failure to
mark and tether, with injury following, is punished as accidental homicide --
which under Tang law is redeemable by payment (依其罪從贖法). -/
def art207Negligent : Precedent :=
  { cite := "唐律疏議 art. 207 (畜產蹋人) -- failure to mark and tether"
  , situation := unmarkedDangerousBeast
  , winner := Side.claimant
  , remedy := Remedy.orElse (Remedy.corporal 1 "笞 (light stick)")
                            (Remedy.inKind "redemption at the statutory rate (贖)")
  , reason := [Factor.knownVice, Factor.noPrecaution] }

/-- **TL art. 207**, second limb: deliberate release, punished one degree below
an affray killing.  Intent moves the case out of the accidental register
entirely. -/
def art207Deliberate : Precedent :=
  { cite := "唐律疏議 art. 207 (畜產蹋人) -- deliberate release (故放)"
  , situation := deliberateRelease
  , winner := Side.claimant
  , remedy := Remedy.corporal 8 "徒/流 (penal servitude or exile), one degree below affray killing"
  , reason := [Factor.knownVice, Factor.intentToHarm, Factor.noPrecaution] }

/-- **TL art. 206** (犬殺傷畜產), first limb.

> 諸犬自殺傷他人畜產者，犬主償其減價。

"Where a dog of itself kills or injures another's animal, the dog's owner
compensates the depreciation."  The commentary gives the reason: 以犬能噬，主須
制之 -- because a dog can bite, the owner must restrain it.  Propensity known
from the kind, so full liability. -/
def art206Dog : Precedent :=
  { cite := "唐律疏議 art. 206 (犬殺傷畜產) -- dog"
  , situation := dogKillsBeast
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.respondentsInstrument, Factor.knownVice] }

/-- **TL art. 206**, second limb -- the one worth the journey.

> 餘畜自相殺傷者，償減價之半。

"Where other animals kill or injure one another, [the owner] compensates **half**
the depreciation."

The commentary works an example: A's ox kills B's horse; the horse was worth
ten bolts of silk, the hide and flesh two, so the depreciation is eight and A
pays B four.

This is Exodus 21:35 ("they shall sell the live ox and divide the price of it;
and the dead also they shall divide"), Eshnunna §53, and the Mishnah's *ḥatzi
nezek*.  Four legal orders, no contact between the Chinese one and the other
three, the same answer.  `Nomos.Bench.GoringOx.half_damages_four_traditions`
proves the remedy terms are identical. -/
def art206Other : Precedent :=
  { cite := "唐律疏議 art. 206 (犬殺傷畜產) -- other beasts, half damages"
  , situation := beastsFight
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.halfDamage
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument] }

/-- **TL art. 204** (官私畜毀食官私物).

> 諸官私畜產，毀食官私之物，登時殺傷者，各減故殺傷三等，償所減價；畜主備所毀。

"Where public or private animals destroy or eat public or private property, and
[the owner of the property] kills or injures them **in the very act**, [the
penalty is] three degrees below deliberate killing or injuring, and he
compensates the depreciation; the animal's owner makes good what was
destroyed."

Grazing trespass with a self-help defence attached.  Note the structure: the
Code does not simply permit killing the trespassing beast, it *prices* the
permission -- the property owner still pays for the animal, but at a heavily
reduced rate.  Compare Ex 22:2's *in flagrante* limit on killing a thief. -/
def art204 : Precedent :=
  { cite := "唐律疏議 art. 204 (官私畜毀食官私物)"
  , situation := beastEatsProperty
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.respondentsInstrument, Factor.respondentBenefited] }

/-- The same article's self-help limb, from the other side: the property owner
who kills the beast in the act is partly excused but not wholly. -/
def art204SelfHelp : Precedent :=
  { cite := "唐律疏議 art. 204 -- killing the trespassing beast 登時"
  , situation := killedInTheAct
  , winner := Side.respondent
  , remedy := Remedy.compensate Loss.halfDamage
  , reason := [Factor.defensive, Factor.claimantAtFault] }

/-- **TL art. 209** (放畜損食官私物).

> 諸放官私畜產，損食官私物者，笞三十；贓重者，坐贓論。失者，減二等。各償所損。
> 若官畜損食官物者，坐而不償。

Loosing animals that damage property: thirty blows, with compensation.  The
last clause is a nice piece of drafting -- where *official* animals damage
*official* property, the official is punished but pays nothing, because the
state cannot owe itself. -/
def art209 : Precedent :=
  { cite := "唐律疏議 art. 209 (放畜損食官私物)"
  , situation := officialLoosesBeasts
  , winner := Side.claimant
  , remedy := Remedy.both (Remedy.corporal 1 "笞三十")
                          (Remedy.compensate Loss.damage)
  , reason := [Factor.noPrecaution, Factor.respondentHeldOffice] }

/-- **TL art. 203** (故殺官私馬牛).

> 諸故殺官私馬牛者，徒一年半。

Deliberately killing another's horse or ox: one and a half years' penal
servitude.  The commentary explains the singling out of these two animals:
牛為耕稼之本，馬即致遠供軍 -- "the ox is the foundation of ploughing and
sowing, the horse carries far and supplies the army."  Liability tracking
economic function rather than value. -/
def art203 : Precedent :=
  { cite := "唐律疏議 art. 203 (故殺官私馬牛)"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentActedDirectly,
                   Factor.intentToHarm]⟩
  , winner := Side.claimant
  , remedy := Remedy.both (Remedy.corporal 6 "徒一年半 (1.5 years' penal servitude)")
                          (Remedy.compensate Loss.damage)
  , reason := [Factor.respondentActedDirectly, Factor.intentToHarm] }

def tangCode : Corpus :=
  { name := "唐律疏議 (Tang Code, 653 CE)"
  , cases := [art207Negligent, art207Deliberate, art206Dog, art206Other,
              art204, art204SelfHelp, art209, art203] }

theorem tang_sound : tangCode.Sound := by decide

/-- The Tang corpus does not contradict itself on the situations it addresses.

Worth comparing with `Nomos.Bench.GoringOx.covenant_incoherent_on_own_situations`:
the Covenant Code does.  The difference is not that the Tang drafters were
cleverer.  It is that the Tang Code is doing one thing -- allocating penalties
and compensation on a single graded scale -- where Exodus 21 switches register
between compensation and pollution.  A factor model built for loss-allocation
fits a code that only allocates loss. -/
theorem tang_coherent : CoherentOn tangCode tangCode.situations := by decide

-- ---------------------------------------------------------------------------
-- The escalation structure, as a theorem
-- ---------------------------------------------------------------------------

/-- The Tang Code escalates on intent the way the Near Eastern codes escalate
on notice: the deliberate-release case is a fortiori stronger for the claimant
than the failure-to-tether case.

Note what this does *not* say.  It does not say the remedies are ordered --
they are not, and `Remedy.Incomparable` is the right relation between a
redeemable accidental-homicide penalty and penal servitude.  It says the *case*
is stronger, which is the claim the factor model licenses. -/
theorem intent_strengthens :
    AtLeastAsStrong deliberateRelease art207Negligent := by decide

/-- And the dog case is stronger for the claimant than the fighting-beasts
case, which is why one draws full damages and the other half.  The Tang
drafters and the Mishnah's editors reached for the same distinction: a
propensity known in advance raises the standard. -/
theorem propensity_strengthens :
    AtLeastAsStrong dogKillsBeast art206Other := by decide

end Nomos.Corpus.Sinica
