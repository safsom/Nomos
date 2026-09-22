/-
# The remedy algebra

What a legal order *does* about a wrong is more varied than "pay damages", and
the variety is legally load-bearing.  Three features of the corpus force the
design here:

1. **Election.** Roman noxal liability gives the defendant a choice --
   *aut noxae dedere aut aestimationem offerre*, surrender the animal or pay the
   assessment (D.9.1.1pr).  Exodus 21:30 has the same shape: the owner of a
   forewarned goring ox is capitally liable, *unless* a ransom is laid on him,
   in which case he pays it.  A remedy type without a disjunction cannot state
   either rule.  Hence `orElse`.

2. **Incommensurability.** Ancient tariffs are stated in units that do not
   convert: gur of barley per gan of land, shekels of silver, oxen, days of
   corvée, strokes.  Normalising them to a single numeraire is an interpretive
   act, and a destructive one -- the fact that Hammurabi prices a life in
   silver while Exodus refuses to is evidence, not noise.  So the ordering on
   remedies is *partial* by construction.

3. **Lower bounds, not values.**  This is the technical heart.  Analogical
   extension of a rule from a lighter case to a heavier one licenses the
   conclusion that the heavier case attracts *at least* the lighter case's
   remedy.  It does not fix a value.  The rabbinic tradition names this
   restriction *dayyo* ("it is sufficient for the derived case to be like the
   case from which it derives", m.Bava Kamma 2:5), and treats it as a
   constraint on the validity of the inference itself.  We take the same view:
   `AtLeast` is the relation analogy transfers, and `Nomos.Reasoning.Analogy`
   proves that nothing stronger is entailed.
-/

import Nomos.Core.Party

namespace Nomos

/-- The interest whose impairment is being measured.  Kept as an opaque
description rather than a number: "the damage" is a legal category whose
quantification is a separate, later question, and many rules in the corpus
refer to it without quantifying it. -/
structure Loss where
  descr : String
  deriving DecidableEq, Repr, Inhabited

namespace Loss
def ofRes (r : Res) : Loss := ⟨r.name⟩
def damage : Loss := ⟨"the damage"⟩
/-- Half the damage.  Exodus 21:35 expresses this as a division of the live
ox's price and the carcass; the Mishnah names it *ḥatzi nezek*.  Writing them
as the same term is a substantive claim of continuity, and one the sources
support -- see `Nomos.Bench.GoringOx.half_damages_inherited`. -/
def halfDamage : Loss := ⟨"half the damage"⟩
/-- A quarter of the damage.  m.Bava Kamma 5:1 uses it for the case of the
gored pregnant cow whose calf may or may not have been in utero: half of half,
because two independent uncertainties compound. -/
def quarterDamage : Loss := ⟨"a quarter of the damage"⟩
def value  : Loss := ⟨"the value of the thing"⟩

/-- `PartOf a b` : `a` is a proper or improper part of `b`, so making good `b`
makes good `a` a fortiori.  Only the fractional relations the sources actually
use are listed; the point is not to build an arithmetic of loss but to record
the handful of comparisons the texts themselves draw. -/
inductive PartOf : Loss → Loss → Prop where
  | refl (l : Loss) : PartOf l l
  | half : PartOf halfDamage damage
  | quarter : PartOf quarterDamage halfDamage
  | quarter_of_whole : PartOf quarterDamage damage

end Loss

/-- What the order requires of the bearer of a liability. -/
inductive Remedy where
  /-- No burden.  The Mishnah's *patur*, the Digest's *cessat actio*. -/
  | exempt
  /-- Return the very thing. -/
  | restore (r : Res)
  /-- Make good the loss. -/
  | compensate (l : Loss)
  /-- A statutory multiple: double, fourfold, the *duplum* and *quadruplum*. -/
  | multiple (k : Nat) (l : Loss)
  /-- A fixed tariff, independent of the actual loss. -/
  | tariff (q : Quantity)
  /-- Restitution in a specified kind, e.g. Exodus 22:4's "of the best of his
      own field".  Not reducible to `compensate`: the specification of quality
      is doing legal work. -/
  | inKind (spec : String)
  /-- Noxal surrender: hand over the offending animal or slave. -/
  | surrender (r : Res)
  /-- The bearer elects between two remedies. -/
  | orElse (a b : Remedy)
  /-- Both, cumulatively. -/
  | both (a b : Remedy)
  /-- Corporal sanction, with an ordinal severity within a named kind. -/
  | corporal (severity : Nat) (kind : String)
  /-- Capital sanction. -/
  | capital
  deriving DecidableEq, Repr, Inhabited

namespace Remedy

/-- One step of "is at least as heavy as".

Each clause records a substantive judgement, so they are worth reading:

* `exempt_bot` -- exemption is the bottom.  Nothing is lighter than nothing.
* `tariff_mono` -- tariffs compare only within a unit (see `Quantity.le`).
* `multiple_mono`, `multiple_compensate` -- a higher multiple of the same loss
  is heavier, and any multiple ≥ 1 is at least simple compensation.
* `both_left`/`both_right` -- a cumulative remedy is at least each conjunct.
* `orElse_left`/`orElse_right` -- an election is at most each disjunct, because
  the bearer will take the lighter one.  This is why `orElse` appears on the
  *right* of these steps and `both` on the left.
* `capital_corporal`, `corporal_mono` -- within the corporal dimension only.

Deliberately absent: any step relating money to blood.  The corpus disagrees
about whether they are comparable, and we let it disagree. -/
inductive Step : Remedy → Remedy → Prop where
  | exempt_bot (r : Remedy) : Step r exempt
  | tariff_mono {q q' : Quantity} : Quantity.le q' q → Step (tariff q) (tariff q')
  | multiple_mono {k j : Nat} {l : Loss} : j ≤ k → Step (multiple k l) (multiple j l)
  | multiple_compensate {k : Nat} {l : Loss} : 1 ≤ k → Step (multiple k l) (compensate l)
  | compensate_multiple_one {l : Loss} : Step (compensate l) (multiple 1 l)
  | compensate_mono {a b : Loss} : Loss.PartOf b a → Step (compensate a) (compensate b)
  | both_left (a b : Remedy) : Step (both a b) a
  | both_right (a b : Remedy) : Step (both a b) b
  | orElse_left (a b : Remedy) : Step a (orElse a b)
  | orElse_right (a b : Remedy) : Step b (orElse a b)
  | capital_corporal (s : Nat) (k : String) : Step capital (corporal s k)
  | corporal_mono {s s' : Nat} {k : String} : s' ≤ s → Step (corporal s k) (corporal s' k)

/-- "At least as heavy as": the reflexive-transitive closure of `Step`.

`AtLeast a b` reads "remedy `a` is at least as onerous as remedy `b`". -/
inductive AtLeast : Remedy → Remedy → Prop where
  | refl (a : Remedy) : AtLeast a a
  | tail {a b c : Remedy} : AtLeast a b → Step b c → AtLeast a c

namespace AtLeast

theorem of_step {a b : Remedy} (h : Step a b) : AtLeast a b :=
  AtLeast.tail (AtLeast.refl a) h

theorem trans {a b c : Remedy} (h₁ : AtLeast a b) (h₂ : AtLeast b c) : AtLeast a c := by
  induction h₂ with
  | refl => exact h₁
  | tail _ s ih => exact AtLeast.tail ih s

/-- Every remedy is at least exemption: the order has a bottom. -/
theorem to_exempt (a : Remedy) : AtLeast a exempt :=
  of_step (Step.exempt_bot a)

end AtLeast

/-- `a` is *strictly* heavier than `b`. -/
def Heavier (a b : Remedy) : Prop := AtLeast a b ∧ ¬ AtLeast b a

/-- Two remedies are incommensurable when neither dominates the other.  This is
the normal case across traditions, and the reason the project reports
convergence and divergence separately rather than scoring similarity. -/
def Incomparable (a b : Remedy) : Prop := ¬ AtLeast a b ∧ ¬ AtLeast b a

/-- Whether a remedy imposes anything at all. -/
def isNull : Remedy → Bool
  | exempt => true
  | orElse a b => isNull a || isNull b     -- the bearer may elect to do nothing
  | both a b => isNull a && isNull b
  | _ => false

-- ---------------------------------------------------------------------------
-- Proving incomparability
-- ---------------------------------------------------------------------------

/-!
`AtLeast` is generated inductively, so showing that one remedy *is* at least as
heavy as another is easy -- exhibit the chain.  Showing that it is *not* needs
an invariant preserved by every step.  Two suffice for everything the corpus
throws up, and both have a legal reading.
-/

/-- True when some branch the bearer may elect involves no corporal or capital
sanction: the bearer can discharge the remedy without blood.

Preserved downward by `Step`, because every way of making a remedy lighter
either keeps an existing bloodless branch or introduces one. -/
def someBranchBloodless : Remedy → Bool
  | capital => false
  | corporal _ _ => false
  | orElse a b => someBranchBloodless a || someBranchBloodless b
  | both a b => someBranchBloodless a && someBranchBloodless b
  | _ => true

/-- True when the remedy is reachable from a purely corporal starting point:
it is corporal, capital, exemption, or an election one of whose branches is.

Note what this excludes: a bare money payment, and any cumulative remedy.  A
legal order that begins from "he shall be put to death" can descend to "unless
a ransom be laid on him" (Ex 21:30) -- an election -- but cannot descend to a
bare tariff, because an election is not the same obligation as its cheaper
branch. -/
def fromCorporal : Remedy → Bool
  | exempt => true
  | capital => true
  | corporal _ _ => true
  | orElse a b => fromCorporal a || fromCorporal b
  | _ => false

theorem Step.someBranchBloodless {a b : Remedy} (h : Step a b) :
    someBranchBloodless a = true → someBranchBloodless b = true := by
  cases h <;> simp_all [Nomos.Remedy.someBranchBloodless]

theorem Step.fromCorporal {a b : Remedy} (h : Step a b) :
    fromCorporal a = true → fromCorporal b = true := by
  cases h <;> simp_all [Nomos.Remedy.fromCorporal]

theorem AtLeast.someBranchBloodless {a b : Remedy} (h : AtLeast a b) :
    someBranchBloodless a = true → someBranchBloodless b = true := by
  induction h with
  | refl => exact id
  | tail _ s ih => exact fun ha => Step.someBranchBloodless s (ih ha)

theorem AtLeast.fromCorporal {a b : Remedy} (h : AtLeast a b) :
    fromCorporal a = true → fromCorporal b = true := by
  induction h with
  | refl => exact id
  | tail _ s ih => exact fun ha => Step.fromCorporal s (ih ha)

/-- **Blood and money do not compare.**

A capital sanction and a money tariff are incomparable in the remedy order:
neither is at least as heavy as the other.  This is not a gap to be filled by
choosing an exchange rate.  It is the formal statement of a real and repeated
disagreement between legal orders -- Exodus 21:29 makes the owner of a
forewarned goring ox capitally liable where LH §251 makes him liable for half
a mina of silver -- and a comparison that declared one heavier would be
asserting something neither order asserts. -/
theorem capital_incomparable_tariff (q : Quantity) :
    Incomparable capital (tariff q) := by
  constructor
  · intro h
    have := AtLeast.fromCorporal h (by simp [fromCorporal])
    simp [fromCorporal] at this
  · intro h
    have := AtLeast.someBranchBloodless h (by simp [someBranchBloodless])
    simp [someBranchBloodless] at this

/-- The same for corporal sanctions short of death. -/
theorem corporal_incomparable_tariff (s : Nat) (k : String) (q : Quantity) :
    Incomparable (corporal s k) (tariff q) := by
  constructor
  · intro h
    have := AtLeast.fromCorporal h (by simp [fromCorporal])
    simp [fromCorporal] at this
  · intro h
    have := AtLeast.someBranchBloodless h (by simp [someBranchBloodless])
    simp [someBranchBloodless] at this

/-- Tariffs in different units do not compare either, which is why
`Quantity.le` requires unit identity.  Twenty gur of barley and thirty shekels
of silver are both money remedies and still not ordered. -/
theorem tariff_incomparable_of_unit_ne {q r : Quantity} (h : q.unit ≠ r.unit) :
    ¬ Step (tariff q) (tariff r) := by
  intro hs
  cases hs with
  | tariff_mono hle => exact h (hle.1.symm)

/-- Convenience constructors matching common corpus idioms. -/
def double (l : Loss) : Remedy := multiple 2 l
def fourfold (l : Loss) : Remedy := multiple 4 l
def fivefold (l : Loss) : Remedy := multiple 5 l
/-- The classic noxal election. -/
def noxal (animal : Res) (l : Loss) : Remedy := orElse (surrender animal) (compensate l)

end Remedy

end Nomos
