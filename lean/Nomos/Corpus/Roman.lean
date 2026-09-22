/-
# Roman law: the Twelve Tables, the *lex Aquilia*, and the Digest

Rome supplies what no other ancient tradition in this corpus does at scale: a
continuous record of *professional* legal reasoning about concrete facts,
preserved with attributions, over four centuries.  Digest book 9 alone -- the
title *si quadrupes pauperiem fecisse dicatur* followed by *ad legem Aquiliam*
-- covers the same ground as Exodus 21 and Mishnah Bava Kamma, and covers it
with named jurists disagreeing.

What makes it valuable here is not the doctrine but the form.  The jurists
extend rules to new facts by *utilis actio* and withhold them by distinction,
which is the reason model operating in the open.  When Ulpian writes that the
*actio de pauperie* lies where the beast acted *commota feritate* but ceases
where the harm arose *propter culpam mulionis*, he is stating an antecedent and
a defeater in one sentence.

Text: the Latin Library's edition of the *Corpus Iuris Civilis* (public
domain), via the CLTK mirror.  Translations in the comments are ours and are
offered as glosses, not as scholarly editions.
-/

import Nomos.Reasoning.Precedent
import Nomos.Core.Defeasance

namespace Nomos.Corpus.Roman

open Nomos

-- ---------------------------------------------------------------------------
-- Situations
-- ---------------------------------------------------------------------------

/-- A four-footed beast does damage of its own motion. -/
def pauperiesSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.behavedAnomalously]⟩

/-- The beast was known to be vicious: *bos cornu petere solitus*. -/
def forewarnedBeast : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.knownVice, Factor.noPrecaution]⟩

/-- The harm arose not from the beast's own wildness but from the driver's
fault, or from overloading, or from the badness of the ground. -/
def driversFault : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.respondentActedDirectly, Factor.noPrecaution]⟩

/-- Aquilian killing: a slave or herd animal wrongfully killed. -/
def aquilianKilling : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly, Factor.intentToHarm]⟩

/-- Aquilian damage short of killing: burning, breaking, spoiling. -/
def aquilianDamage : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly]⟩

/-- The claimant brought the harm on himself. -/
def claimantsOwnFault : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly, Factor.claimantAtFault]⟩

/-- A madman does damage: there can be no *culpa* where there is no mind. -/
def madmansAct : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly, Factor.behavedAnomalously]⟩

/-- A thing deposited gratuitously perishes without fraud. -/
def depositum : Situation :=
  ⟨[Factor.harmOccurred, Factor.gratuitousService, Factor.properPrecaution]⟩

/-- A thing lent for the borrower's sole use perishes. -/
def commodatum : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentBenefited]⟩

/-- Self-defence against a robber. -/
def selfDefence : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentActedDirectly, Factor.defensive,
    Factor.claimantAtFault]⟩

-- ---------------------------------------------------------------------------
-- Holdings
-- ---------------------------------------------------------------------------

/-- **D.9.1.1pr** (Ulpian, 18 *ad ed.*).  "*Si quadrupes pauperiem fecisse
dicetur, actio ex lege duodecim tabularum descendit: quae lex voluit aut dari
id quod nocuit, id est id animal quod noxiam commisit, aut aestimationem noxiae
offerre.*"

"If a four-footed beast is said to have done damage, an action descends from
the law of the Twelve Tables: which law willed that either the thing that did
the harm be handed over -- that is, the animal that committed the wrong -- or
that the assessment of the harm be offered."

The remedy is an election, and it is the oldest election in the corpus: the
Twelve Tables are traditionally dated to 451-449 BCE.  Exodus 21:29-30 has the
same shape, and so does nothing else. -/
def pauperies : Precedent :=
  { cite := "D.9.1.1pr (Ulpian) = XII Tab."
  , situation := pauperiesSituation
  , winner := Side.claimant
  , remedy := Remedy.orElse
                (Remedy.surrender ⟨"the offending beast", ResKind.livestock⟩)
                (Remedy.compensate Loss.damage)
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument] }

/-- **D.9.1.1.4** (Ulpian).  "*Itaque, ut Servius scribit, tunc haec actio locum
habet, cum commota feritate nocuit quadrupes, puta si equus calcitrosus calce
percusserit, aut bos cornu petere solitus petierit ... quod si propter loci
iniquitatem aut propter culpam mulionis, aut si plus iusto onerata quadrupes in
aliquem onus everterit, haec actio cessabit damnique iniuriae agetur.*"

"And so, as Servius writes, this action has place when the beast has done harm
with its wildness roused -- say if a kicking horse has struck with its hoof, or
an ox accustomed to gore has gored ... but if it was because of the badness of
the place, or the driver's fault, or because a beast loaded beyond what is
right has tipped its load onto someone, this action will cease and the action
for wrongful damage will be brought."

*Bos cornu petere solitus* -- "an ox accustomed to gore" -- is Exodus 21:29's
"wont to gore in time past" and the Mishnah's *mu'ad*, arrived at
independently.  The second half is a defeater: where the human act is the real
cause, the noxal action gives way to the Aquilian one. -/
def forewarnedPauperies : Precedent :=
  { cite := "D.9.1.1.4 (Ulpian, citing Servius)"
  , situation := forewarnedBeast
  , winner := Side.claimant
  , remedy := Remedy.orElse
                (Remedy.surrender ⟨"the offending beast", ResKind.livestock⟩)
                (Remedy.compensate Loss.damage)
  , reason := [Factor.respondentsInstrument, Factor.knownVice] }

/-- The same fragment's defeater: the noxal action ceases where the fault was
the driver's, and the Aquilian action lies instead.  Formalised as a
higher-priority rule in `theory` below. -/
def noxalCeasesForCulpa : Rule :=
  { id := "D.9.1.1.4 -- haec actio cessabit damnique iniuriae agetur"
  , antecedent := [Factor.respondentActedDirectly, Factor.noPrecaution]
  , conclusion := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , priority := 1 }

def pauperiesRule : Rule :=
  { id := "D.9.1.1pr -- actio de pauperie"
  , antecedent := [Factor.harmOccurred, Factor.respondentsInstrument]
  , conclusion := Side.claimant
  , remedy := Remedy.orElse
                (Remedy.surrender ⟨"the offending beast", ResKind.livestock⟩)
                (Remedy.compensate Loss.damage)
  , priority := 0 }

def theory : Theory := ⟨"D.9.1 (actio de pauperie)", [pauperiesRule, noxalCeasesForCulpa]⟩

/-- Where the driver was at fault, the noxal rule is defeated and the Aquilian
one prevails: the remedy is compensation, not an election.  The owner loses the
option of abandoning the beast, which is the whole practical point of the
distinction. -/
theorem culpa_defeats_noxal : theory.Defeated pauperiesRule driversFault :=
  ⟨noxalCeasesForCulpa, by simp [theory], by decide, by decide, by decide⟩

/-- **D.9.1.1.11** (Ulpian).  "*Cum arietes vel boves commisissent et alter
alterum occidit, Quintus Mucius distinxit, ut si quidem is perisset qui
adgressus erat, cessaret actio, si is, qui non provocaverat, competeret actio.*"

"When rams or oxen have fought and one has killed the other, Quintus Mucius
drew a distinction: if the one that perished was the aggressor, the action
fails; if it was the one that had not provoked, the action lies."

Quintus Mucius Scaevola died in 82 BCE, so this distinction is roughly
contemporary with the earliest rabbinic material and reaches the same result as
m.Bava Kamma's treatment of the provoked animal. -/
def fightingRams : Precedent :=
  { cite := "D.9.1.1.11 (Ulpian, citing Q. Mucius)"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
                   Factor.claimantAtFault]⟩
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.claimantAtFault] }

/-- **D.9.2.2pr** (Gaius, 7 *ad ed. provinc.*).  "*Lege Aquilia capite primo
cavetur: ut qui servum servamve alienum alienamve quadrupedem vel pecudem
iniuria occiderit, quanti id in eo anno plurimi fuit, tantum aes dare domino
damnas esto.*"

Chapter 1 of the *lex Aquilia* (c. 286 BCE): whoever wrongfully kills another's
slave or herd animal shall be condemned to pay the owner the highest value the
thing had in that year.  The backward-looking valuation is unusual and
deliberate -- it compensates the owner for a loss measured at its greatest, not
at the moment of the wrong. -/
def aquilianChapterOne : Precedent :=
  { cite := "D.9.2.2pr (Gaius) -- lex Aquilia c.1"
  , situation := aquilianKilling
  , winner := Side.claimant
  , remedy := Remedy.inKind "the highest value the thing bore in that year"
  , reason := [Factor.respondentActedDirectly, Factor.intentToHarm] }

/-- **D.9.2.27.5** (Ulpian).  Chapter 3 of the *lex Aquilia*: for burning,
breaking or spoiling anything other than a slave or herd animal killed, the
value in the last thirty days. -/
def aquilianChapterThree : Precedent :=
  { cite := "D.9.2.27.5 (Ulpian) -- lex Aquilia c.3"
  , situation := aquilianDamage
  , winner := Side.claimant
  , remedy := Remedy.inKind "the value of the thing in the last thirty days"
  , reason := [Factor.respondentActedDirectly] }

/-- **D.9.2.44pr** (Ulpian, 42 *ad Sab.*).  "*In lege Aquilia et levissima
culpa venit.*"  "Under the lex Aquilia even the slightest fault counts."

One clause, and it sets the standard at its most demanding.  What it does not
do is say what counts as slight fault, which is exactly the shape
`Nomos.Core.Standard` is built for. -/
def levissimaCulpa : Precedent :=
  { cite := "D.9.2.44pr (Ulpian)"
  , situation := aquilianDamage
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.respondentActedDirectly] }

/-- **D.9.2.5.2** (Ulpian).  "*Si furiosus damnum dederit, an legis Aquiliae
actio sit? Et Pegasus negavit: quae enim in eo culpa sit, cum suae mentis non
sit?*"  A madman cannot be at fault, having no mind of his own; and the same,
Ulpian adds, for an infant, and for a beast, and for a falling tile. -/
def madman : Precedent :=
  { cite := "D.9.2.5.2 (Ulpian, citing Pegasus)"
  , situation := madmansAct
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.behavedAnomalously] }

/-- **D.50.17.203** (Pomponius).  "*Quod quis ex culpa sua damnum sentit, non
intellegitur damnum sentire.*"  "Loss a man suffers through his own fault is
not regarded as loss suffered."  The most compact statement of contributory
fault in the corpus, and one the Digest's compilers placed among the general
maxims rather than in the law of delict. -/
def ownFault : Precedent :=
  { cite := "D.50.17.203 (Pomponius)"
  , situation := claimantsOwnFault
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.claimantAtFault] }

/-- **D.9.2.4pr** (Gaius).  "*Itaque si servum tuum latronem insidiantem mihi
occidero, securus ero: nam adversus periculum naturalis ratio permittit se
defendere.*"  Self-defence: natural reason permits a man to defend himself
against danger. -/
def defence : Precedent :=
  { cite := "D.9.2.4pr (Gaius)"
  , situation := selfDefence
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.defensive, Factor.claimantAtFault] }

/-- **D.13.6.5.2** (Ulpian, 28 *ad ed.*).  "*In contractibus interdum dolum
solum, interdum et culpam praestamus: dolum in deposito ... sed ubi utriusque
utilitas vertitur ...*"

"In contracts we are answerable sometimes for fraud alone, sometimes for fault
as well: for fraud alone in deposit -- since no advantage accrues to the person
with whom the thing is deposited, only fraud is fairly charged to him ... but
where the advantage of both is in play ..."

This is the doctrine of *utilitas contrahentium*: the standard of care tracks
who benefits.  Mishnah Bava Metzia 7:8 grades four bailees on the same
principle, and neither tradition can have borrowed it from the other. -/
def depositGratuitous : Precedent :=
  { cite := "D.13.6.5.2, D.16.3.1.35 (Ulpian) -- utilitas contrahentium"
  , situation := depositum
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.gratuitousService, Factor.properPrecaution] }

/-- The borrower under *commodatum*, having the whole advantage, answers for
everything short of irresistible force. -/
def commodatumBorrower : Precedent :=
  { cite := "D.13.6.5.2 (Ulpian) -- commodatum"
  , situation := commodatum
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.value
  , reason := [Factor.respondentBenefited] }

/-- **XII Tab. 8.2.**  "*Si membrum rup[s]it, ni cum eo pacit, talio esto.*"
"If he has broken a limb, and does not settle with him, let there be
retaliation."  Talion as a default that composition displaces -- the same
structure as Exodus 21:30's ransom clause. -/
def talio : Precedent :=
  { cite := "XII Tab. 8.2"
  , situation := ⟨[Factor.harmOccurred, Factor.harmToPerson,
                   Factor.respondentActedDirectly, Factor.intentToHarm]⟩
  , winner := Side.claimant
  , remedy := Remedy.orElse (Remedy.corporal 5 "talio")
                            (Remedy.inKind "such composition as is agreed")
  , reason := [Factor.harmToPerson, Factor.intentToHarm] }

/-- **XII Tab. 8.3.**  "*Manu fustive si os fregit libero, CCC, si servo, CL
poenam subito; si iniuriam faxsit, viginti quinque poenae asses sunto.*"
Fixed tariffs: 300 asses for a free man's broken bone, 150 for a slave's, 25
for lesser affront. -/
def fixedPenalties : Precedent :=
  { cite := "XII Tab. 8.3"
  , situation := ⟨[Factor.harmOccurred, Factor.harmToPerson,
                   Factor.respondentActedDirectly]⟩
  , winner := Side.claimant
  , remedy := Remedy.tariff (Quantity.asses 300)
  , reason := [Factor.harmToPerson, Factor.respondentActedDirectly] }

def corpus : Corpus :=
  { name := "Roman law (XII Tables, lex Aquilia, Digest)"
  , cases := [pauperies, forewarnedPauperies, fightingRams, aquilianChapterOne,
              aquilianChapterThree, levissimaCulpa, madman, ownFault, defence,
              depositGratuitous, commodatumBorrower, talio, fixedPenalties] }

theorem corpus_sound : corpus.Sound := by decide

end Nomos.Corpus.Roman
