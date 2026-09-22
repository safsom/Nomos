/-
# English law: from Alfred's Domboc to the Animals Act 1971

## The one line of transmission we can actually trace

Everywhere else in this corpus, a parallel between two traditions is a puzzle:
borrowing, shared convention, or convergent invention, and usually no way to
tell.  The English line is different, because at one point the borrowing is
documented and explicit.

When Alfred issued his law-book around 890, he prefaced it not with a statement
of royal authority but with **a translation of Exodus 20-23** -- the Decalogue
and then the Covenant Code, in Old English, as the first thing in the book.
The goring ox came with it.  So the rule that an ox which kills is destroyed,
and that its owner answers if he knew it was dangerous, enters English law by
being copied out of the Hebrew Bible into a West Saxon king's statute.

Seven centuries later the common law has an action on the case requiring proof
that the defendant knew of the animal's vicious propensity -- the *scienter*
action, confirmed in *May v Burdett* (1846) -- and in 1971 Parliament codifies
it as a statutory liability for damage done by an animal with "characteristics
not normally found in animals of the same species ... known to that keeper".

*Bos cornu petere solitus.*  *Wont to gore in time past.*  *Mu'ad.*
畜產及噬犬.  Characteristics known to that keeper.

That is the through-line this module exists to make checkable, and
`Nomos.Bench.GoringOx` states it as a theorem.

## Provenance

Two sources here are shipped with real text: **Magna Carta**, in the Latin of
the Lincoln exemplar, from the Latin Library.  Everything else -- the
Anglo-Saxon codes, Glanvill, Bracton, the nineteenth-century cases and the 1971
Act -- is carried as **citation plus editorial restatement**, in the same way
and for the same reason as `Corpus/Mesopotamia.lean`: the build environment
could not reach Early English Laws, Bracton Online, BAILII or
legislation.gov.uk, and paraphrasing from memory while calling it a translation
would be worse than useless.

`python -m nomos.fetch.restricted` will fetch them from anywhere with ordinary
network access.  Until it has been run, treat the restatements below as our
reading of what these authorities hold, not as their words.  Chapter numbers in
the Anglo-Saxon codes follow Liebermann's *Gesetze der Angelsachsen* and should
be checked; the editions disagree.
-/

import Nomos.Reasoning.Precedent
import Nomos.Corpus.Covenant

namespace Nomos.Corpus.Anglia

open Nomos

-- ---------------------------------------------------------------------------
-- Situations
-- ---------------------------------------------------------------------------

/-- An animal kills a person; nothing was known against it. -/
def innocuousBeastKills : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.behavedAnomalously]⟩

/-- The keeper knew of the vicious propensity and did not restrain it. -/
def scienterSituation : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.harmToPerson,
    Factor.knownVice, Factor.noPrecaution]⟩

/-- Cattle stray from the defendant's land onto the highway and cause harm. -/
def cattleOnHighway : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.inPublicOrClaimantsGround, Factor.behavedAnomalously,
    Factor.customaryPractice]⟩

/-- Something the defendant brought onto his land for his own purposes escapes
and does damage. -/
def escapeFromLand : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
    Factor.respondentBenefited, Factor.inPublicOrClaimantsGround]⟩

/-- A free man is injured by another; the amends are fixed by the victim's
rank. -/
def injuryByRank : Situation :=
  ⟨[Factor.harmOccurred, Factor.harmToPerson, Factor.respondentActedDirectly,
    Factor.intentToHarm, Factor.claimantSuperiorInStatus]⟩

/-- A free man is amerced; the question is how far the penalty may reach. -/
def amercement : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentHeldOffice,
    Factor.respondentActedDirectly]⟩

-- ---------------------------------------------------------------------------
-- Holdings
-- ---------------------------------------------------------------------------

/-- **Æthelberht of Kent, c. 600** (editorial restatement).

The earliest law in English, and a pure tariff code: amends (*bót*) for
injuries, graded throughout by the rank of the person injured.  Nothing in it
is about fault; everything is about status and body part.

It is the cleanest illustration in the corpus of `claimantSuperiorInStatus`
doing all the work with no other factor present. -/
def aethelberht : Precedent :=
  { cite := "Æthelberht (c. 600) [editorial restatement; text not shipped]"
  , situation := injuryByRank
  , winner := Side.claimant
  , remedy := Remedy.inKind "bót at the tariff for the injury, multiplied by the victim's rank"
  , reason := [Factor.harmToPerson, Factor.claimantSuperiorInStatus] }

/-- **Alfred, Domboc, Mosaic prologue (c. 890)** (editorial restatement).

Alfred opens his law-book with Exodus 20-23 in Old English.  The goring-ox
provisions come across substantially intact: the ox that kills is to be stoned
and its flesh not eaten, and where the owner knew of the beast's habit and did
not confine it, he answers with his own life unless a *wergild* is accepted.

We formalise it with the same factors and the same remedy shape as
`Covenant.forewarnedOxWithRansom`, because it is the same rule -- copied, not
reinvented.  `Nomos.Bench.GoringOx.alfred_copies_exodus` makes the identity
machine-checked rather than asserted.

Chapter numbering in the prologue varies between editions; Liebermann's Af El.
21 is the goring ox.  Verify before citing. -/
def alfredGoringOx : Precedent :=
  { cite := "Alfred, Domboc, Mosaic prologue (Af El. ~21) [editorial restatement]"
  , situation := ⟨Covenant.forewarnedGoreOfPerson.factors⟩
  , winner := Side.claimant
  , remedy := Remedy.orElse Remedy.capital
                (Remedy.inKind "the ransom laid upon him")
  , reason := [Factor.knownVice, Factor.warned, Factor.noPrecaution] }

/-- **Magna Carta (1215) cl. 39.**

> *Nullus liber homo capiatur, vel imprisonetur, aut disseisiatur, aut
> utlagetur, aut exuletur, aut aliquo modo destruatur, nec super eum ibimus,
> nec super eum mittemus, nisi per legale judicium parium suorum vel per legem
> terre.*

"No free man shall be seized or imprisoned, or stripped of his rights or
possessions, or outlawed or exiled, or deprived of his standing in any other
way ... except by the lawful judgment of his equals or by the law of the land."

Not a liability rule, and included deliberately.  It is a rule about *who may
impose* liability, and the corpus has almost nothing else of that kind.  The
factor model has no vocabulary for it, which is itself worth recording: see the
note on `Nomos.Bench.GoringOx` about what the model does not see. -/
def magnaCarta39 : Precedent :=
  { cite := "Magna Carta (1215) cl. 39"
  , situation := ⟨[Factor.harmOccurred, Factor.harmToPerson,
                   Factor.respondentHeldOffice, Factor.respondentActedDirectly]⟩
  , winner := Side.claimant
  , remedy := Remedy.inKind "restoration; and no seizure save by lawful judgment of peers or by the law of the land"
  , reason := [Factor.respondentHeldOffice, Factor.harmToPerson] }

/-- **Magna Carta (1215) cl. 20.**

> *Liber homo non amercietur pro parvo delicto, nisi secundum modum delicti; et
> pro magno delicto amercietur secundum magnitudinem delicti, salvo
> contenemento suo.*

"A free man shall not be amerced for a trivial offence except in proportion to
the offence; and for a serious offence in proportion to its gravity, saving his
livelihood."

Proportionality, plus a floor: whatever the offence, the amercement may not
take the means of living.  Compare m.BK 1:1's *meitav* (assessment "with the
best of his land") and the Digest's *beneficium competentiae*.

Note who is who.  The free man being amerced is the *claimant* here: the clause
gives him a ground of complaint against the Crown's officers, and they are the
respondents.  Getting this backwards is the kind of error `Holding.WellFormed`
exists to catch, and it caught it here -- an earlier draft made the free man
the respondent and offered `respondentHeldOffice`, a claimant-side factor, as
his reason for winning. -/
def magnaCarta20 : Precedent :=
  { cite := "Magna Carta (1215) cl. 20"
  , situation := amercement
  , winner := Side.claimant
  , remedy := Remedy.inKind "amercement proportionate to the offence, saving the claimant's contenement"
  , reason := [Factor.respondentHeldOffice, Factor.harmOccurred] }

/-- **Bracton, *De legibus et consuetudinibus Angliae* (c. 1235)** (editorial
restatement).

Bracton reads the Roman *actio de pauperie* into English law, taking the
noxal structure -- the beast's owner answers, and may discharge by surrender --
from Justinian's *Institutes*.  How much of this ever took effect in the royal
courts is contested among legal historians; what is not contested is that he
wrote it down.

This is the point at which `Corpus/Roman.lean` and this module touch. -/
def bractonPauperies : Precedent :=
  { cite := "Bracton, De legibus (c. 1235) [editorial restatement; text not shipped]"
  , situation := ⟨[Factor.harmOccurred, Factor.respondentsInstrument,
                   Factor.behavedAnomalously]⟩
  , winner := Side.claimant
  , remedy := Remedy.orElse
                (Remedy.surrender ⟨"the offending beast", ResKind.livestock⟩)
                (Remedy.compensate Loss.damage)
  , reason := [Factor.harmOccurred, Factor.respondentsInstrument] }

/-- ***May v Burdett*** (1846) 9 QB 101 (editorial restatement).

The plaintiff was bitten by the defendant's monkey.  Held: a person who keeps
an animal knowing it to be dangerous is liable for the damage it does, and the
declaration need not allege negligence -- knowledge of the propensity is the
gist of the action.

This is the *scienter* action, and it is Exodus 21:29 and D.9.1.1.4 and
m.BK 1:4 and 唐律 art. 207, all of which the Queen's Bench had never heard
of. -/
def mayVBurdett : Precedent :=
  { cite := "May v Burdett (1846) 9 QB 101 [editorial restatement]"
  , situation := scienterSituation
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.knownVice, Factor.respondentsInstrument] }

/-- ***Cox v Burbidge*** (1863) 13 CB NS 430 (editorial restatement).

A horse strays from the highway and kicks a child.  Held: no liability, absent
proof that the owner knew the horse was vicious.  Straying onto the highway is
an ordinary incident of keeping animals in an England without fences, and the
law would not make it actionable.

The rule survived until *Searle v Wallbank* [1947] AC 341 and was abolished
only by the Animals Act 1971 s.8. -/
def coxVBurbidge : Precedent :=
  { cite := "Cox v Burbidge (1863) 13 CB NS 430 [editorial restatement]"
  , situation := cattleOnHighway
  , winner := Side.respondent
  , remedy := Remedy.exempt
  , reason := [Factor.behavedAnomalously, Factor.customaryPractice] }

/-- ***Rylands v Fletcher*** (1868) LR 3 HL 330 (editorial restatement).

A person who for his own purposes brings onto his land something likely to do
mischief if it escapes keeps it at his peril, and is answerable for the natural
consequences of its escape.

Strict liability attaching to a *non-natural use* undertaken for the
defendant's own benefit -- which is `respondentBenefited` doing the work that
`knownVice` does in the animal cases.  The two lines of authority ran in
parallel for a century. -/
def rylandsVFletcher : Precedent :=
  { cite := "Rylands v Fletcher (1868) LR 3 HL 330 [editorial restatement]"
  , situation := escapeFromLand
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.respondentBenefited, Factor.respondentsInstrument] }

/-- **Animals Act 1971 (UK) s.2(2)** (editorial restatement).

Where an animal does not belong to a dangerous species, its keeper is liable
if: the damage is of a kind the animal was likely to cause unless restrained,
or which if caused was likely to be severe; the likelihood was due to
characteristics not normally found in animals of the species, or not normally
found except at particular times or in particular circumstances; and **those
characteristics were known to the keeper**.

Three thousand years after Exodus 21:29, an Act of Parliament states the rule
in the same three parts: a propensity, abnormal for the kind, known to the
keeper. -/
def animalsAct1971 : Precedent :=
  { cite := "Animals Act 1971 (UK) s.2(2) [editorial restatement]"
  , situation := scienterSituation
  , winner := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , reason := [Factor.knownVice, Factor.respondentsInstrument,
               Factor.noPrecaution] }

def corpus : Corpus :=
  { name := "English law (Æthelberht to the Animals Act 1971)"
  , cases := [aethelberht, alfredGoringOx, magnaCarta39, magnaCarta20,
              bractonPauperies, mayVBurdett, coxVBurbidge, rylandsVFletcher,
              animalsAct1971] }

theorem corpus_sound : corpus.Sound := by decide

-- ---------------------------------------------------------------------------
-- Continuity, as theorems
-- ---------------------------------------------------------------------------

/-- **Alfred copied Exodus.**  The formalisations are identical in situation,
outcome, remedy and ratio -- which is what you would expect, because Alfred's
scribes were copying, not reasoning.

This is the control for every other convergence claim in the corpus.  Where
transmission is documented, the formalisations coincide exactly.  Where it is
not, they coincide in the factors and diverge in the remedy -- which is the
signature of independent invention rather than borrowing. -/
theorem alfred_copies_exodus :
    alfredGoringOx.situation = Covenant.forewarnedOxWithRansom.situation ∧
    alfredGoringOx.winner = Covenant.forewarnedOxWithRansom.winner ∧
    alfredGoringOx.remedy = Covenant.forewarnedOxWithRansom.remedy ∧
    alfredGoringOx.reason = Covenant.forewarnedOxWithRansom.reason := by decide

/-- **The scienter line is stable for 125 years.**  *May v Burdett* (1846) and
the Animals Act 1971 decide the same situation the same way on overlapping
ratios, across the whole transition from common-law action to statute. -/
theorem scienter_survives_codification :
    mayVBurdett.situation = animalsAct1971.situation ∧
    mayVBurdett.winner = animalsAct1971.winner ∧
    mayVBurdett.remedy = animalsAct1971.remedy := by decide

/-- And the statute binds the case: the 1971 Act's ratio is broader, so
anything *May v Burdett* would have caught, the Act catches. -/
theorem act_covers_the_case :
    AtLeastAsStrong animalsAct1971.situation mayVBurdett := by decide

/-- The English corpus is coherent on the situations it addresses, despite
spanning 1,400 years and two complete changes of legal system.  That is a
lower bar than it sounds -- the cases were selected along one doctrinal line --
but it is worth checking, and `Nomos.Bench.GoringOx` shows it fails as soon as
Exodus is added. -/
theorem english_coherent : CoherentOn corpus corpus.situations := by decide

end Nomos.Corpus.Anglia
