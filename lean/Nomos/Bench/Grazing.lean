/-
# Bench: the shepherd's sheep on the neighbour's field

The scenario this project started from.  A man keeps animals; the animals get
into someone else's crop and eat it; what happens?

It is the best test case available, for a reason worth stating.  It is
*mundane*.  Nothing about it is culturally particular, it has no theological
freight, and every agrarian society has had to settle it.  So when four legal
orders settle it differently, the difference is about law rather than about
anything else.

## The four answers

| | |
|---|---|
| **LH §57** (c. 1750 BCE) | the field-owner harvests his crop, *and* the shepherd hands over grain at a fixed rate per unit of land |
| **Ex 22:4** | restitution "of the best of his own field and of the best of his own vineyard" |
| **m.BK 1:1** (*shen*) | restitution "with the best of his land" -- the Mishnah reads its general measure of damages out of Ex 22:4 |
| **唐律疏議 art. 204** (653 CE) | the animal's owner makes good what was destroyed; and the field-owner who kills the beast *in the very act* is punished three degrees below deliberate killing, and still pays for the animal |

Four structural observations, all of them checkable below.

**One.** Every order makes the keeper answer.  None of them treats a straying
animal as the field-owner's bad luck.  `all_hold_the_keeper` states it.

**Two.** Three of the four specify the *quality* of the restitution rather than
its amount -- "of the best".  This is why `Remedy.inKind` exists as a separate
constructor from `Remedy.compensate`: a rule that says *meitav* is doing legal
work that "pay the damage" would lose, and the Mishnah's whole measure of
damages is built on that phrase.

**Three.** Hammurabi's remedy is *cumulative* where the others are not: the
field-owner keeps his crop **and** takes the grain.  That is a penalty on top
of restitution, and `Remedy.both` is what lets us say so.

**Four.** Only the Tang Code addresses self-help, and it addresses it by
*pricing* it.  The field-owner may kill the trespassing beast, but he pays for
it -- at a reduced rate.  None of the Near Eastern codes in the corpus regulates
the question at all, which is a gap in them rather than in the model.

## What is missing

Rome.  The Digest treats grazing under the *actio de pastu pecoris* and at
D.19.5.14.3, and neither is formalised here: the fragments are about the form
of action rather than the allocation, and reading an allocation out of them
would be our construction rather than the jurists'.  A genuine gap, and the
first thing to fill.
-/

import Nomos.Corpus.Covenant
import Nomos.Corpus.Rabbinic
import Nomos.Corpus.Mesopotamia
import Nomos.Corpus.Sinica

namespace Nomos.Bench.Grazing

open Nomos Nomos.Corpus

/-- The four grazing holdings. -/
def witnesses : List Precedent :=
  [ Mesopotamia.lh57      -- LH §57
  , Covenant.grazing      -- Ex 22:4
  , Rabbinic.avTooth      -- m.BK 1:1, the tooth
  , Sinica.art204 ]       -- 唐律疏議 art. 204

/-- **Every order holds the keeper.**  Four legal systems, no two of which need
have heard of each other, and not one leaves the loss on the field-owner. -/
theorem all_hold_the_keeper :
    ∀ h ∈ witnesses, h.winner = Side.claimant := by decide

/-- **And every one of them rests it on the same fact**: the animal was the
respondent's to control.  Not fault, not intent, not notice -- custody. -/
theorem all_rest_on_custody :
    ∀ h ∈ witnesses, Factor.respondentsInstrument ∈ h.reason := by decide

/-- **Exodus and the Mishnah give the same remedy in the same form.**  Both
specify quality rather than quantity, and the Mishnah says openly that it is
reading its measure out of Exodus.  This is transmission, and it leaves the
signature transmission leaves: the remedy terms coincide. -/
theorem mishnah_reads_exodus :
    Covenant.grazing.remedy = Remedy.inKind
      "of the best of his own field and of the best of his own vineyard" ∧
    Rabbinic.avTooth.remedy = Remedy.inKind "with the best of his land" := by decide

/-- **Hammurabi's remedy is cumulative and the others are not.**

The field-owner harvests his crop *and* receives grain.  Structurally that is
restitution plus a penalty, and the penalty has no counterpart in the other
three.  Whether it is a penalty for the trespass or a rough measure of
consequential loss is exactly the kind of question the formalisation makes
askable and does not answer. -/
def isCumulative : Remedy → Bool
  | Remedy.both _ _ => true
  | _ => false

theorem hammurabi_is_cumulative :
    isCumulative Mesopotamia.lh57.remedy = true ∧
    isCumulative Covenant.grazing.remedy = false ∧
    isCumulative Rabbinic.avTooth.remedy = false ∧
    isCumulative Sinica.art204.remedy = false := by decide

/-- **The keeper's benefit is what distinguishes grazing from goring.**

The Mishnah's distinction between *shen* (tooth) and *keren* (horn) is that the
grazing animal eats for its own good and so its keeper gains, while the goring
animal takes nothing.  The Tang Code draws the same line -- 毀食, "destroys and
eats" -- and the Roman *utilitas* doctrine runs on the same idea in the law of
bailment.

So `respondentBenefited` appears in the grazing situations and not in the
goring ones, across traditions. -/
theorem benefit_marks_grazing :
    Factor.respondentBenefited ∈ Sinica.beastEatsProperty.factors ∧
    Factor.respondentBenefited ∈ Rabbinic.toothSituation.factors ∧
    Factor.respondentBenefited ∉ Rabbinic.oxSituation.factors ∧
    Factor.respondentBenefited ∉ Covenant.forewarnedGoreOfPerson.factors := by decide

/-- **Only the Tang Code prices self-help.**

The field-owner who kills the trespassing beast on the spot is partly excused
and still pays.  Compare Ex 22:2, which permits killing a burglar only while he
is breaking in -- the same *in flagrante* limit, applied to a different wrong.

The other three orders in this bench say nothing at all about it, so the
question is `Open` under each of them.  That is the model reporting a gap in
the sources, not a gap in itself. -/
theorem self_help_is_open_elsewhere :
    Open Covenant.corpus Sinica.killedInTheAct ∧
    Open Mesopotamia.corpus Sinica.killedInTheAct ∧
    ¬ Open Sinica.tangCode Sinica.killedInTheAct := by decide

/-- The consent hinge, which is where `Nomos.Core.Right` comes in.

LH §57's liability turns on the shepherd having acted *without the owner's
consent*.  Remove that and the rule does not apply -- which is what makes the
field-owner's position a right rather than merely a protected interest, and is
the reconstruction `Corpus/Mesopotamia` and `Core/Right.Hammurabi57` carry
out. -/
theorem consent_is_the_hinge :
    Factor.withoutLeave ∈ Mesopotamia.lh57.reason ∧
    Factor.withoutLeave ∈ Covenant.grazing.reason := by decide

end Nomos.Bench.Grazing
