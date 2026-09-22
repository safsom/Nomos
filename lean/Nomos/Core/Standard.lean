/-
# Vague standards

"Reasonable efforts."  "Due diligence."  "Such care as a prudent man would
take."  *Diligentia quam suis rebus.*  *Shemirah me'ulah.*  Every developed
legal order runs on terms of this kind, and no order defines them.

The usual reaction in formal legal modelling is to treat this as a defect to be
repaired -- pick a threshold, fit a classifier, learn an embedding.  We think
that is the wrong move, and this module implements the alternative.

**The proposal.**  A vague standard is not a predicate awaiting definition.  It
is a pair:

1. a *comparative* that is perfectly determinate -- "this precaution is at
   least as careful as that one" is a judgement lawyers make confidently and
   agree about, far more confidently than they agree about "this precaution is
   reasonable";
2. a *record* of which conduct has been held to satisfy and which to fail.

The standard's content at any moment is exactly what those two things force,
and no more.  Conduct above something held sufficient is sufficient; conduct
below something held insufficient is insufficient; everything else is open.
The open region is not a gap in our model of the law.  It is a gap in the law,
and it is where adjudication does its work.

**What this buys.**  Three things, all of them theorems below.

* `not_settled_both_ways` -- a coherent record never contradicts itself, and
  coherence is a finite, checkable condition on the record alone.  We never
  need to know where the threshold "really" is.
* `decide_open_preserves_coherent` -- a court facing an open case may decide it
  either way without contradicting the record.  This is legal indeterminacy
  stated exactly, rather than deplored.
* `settled_monotone` -- the settled region only grows.  Law accretes.

**Why it matters for the corpus.**  Standards are the single hardest thing to
formalise from an ancient text, because the texts state them and never gloss
them.  Hammurabi §§236-240 make a boatman liable for a collision but excuse
him where the other boat was at fault; the Digest's *diligentia* vocabulary
runs to dozens of gradations; m.Bava Metzia 7:8 grades four bailees by the care
each owes.  On the model here, none of these needs a definition to be
formalised.  Each needs a comparative and a list of decided cases -- which is
precisely what the sources supply.
-/

import Nomos.Core.Factor

namespace Nomos

/-- A vague standard over a space `C` of conduct.

The two order axioms are carried in the structure rather than imposed by a
typeclass, because different standards in the same legal order may order the
same conduct differently: what counts as careful enough for a gratuitous
depositary is not what counts for a hirer, and the comparative itself differs,
not only the threshold. -/
structure Standard (C : Type) where
  name : String
  /-- "At least as diligent / careful / extensive as." -/
  atLeastAsGood : C → C → Prop
  refl  : ∀ c, atLeastAsGood c c
  trans : ∀ a b c, atLeastAsGood a b → atLeastAsGood b c → atLeastAsGood a c
  /-- Conduct held to satisfy the standard, with citations carried alongside in
      the corpus data rather than in the type. -/
  sufficient : List C
  /-- Conduct held to fall short. -/
  insufficient : List C

namespace Standard

variable {C : Type}

/-- The record does not contradict itself: nothing held to fall short is at
least as good as something held to suffice. -/
def Coherent (S : Standard C) : Prop :=
  ∀ a ∈ S.sufficient, ∀ b ∈ S.insufficient, ¬ S.atLeastAsGood b a

/-- Conduct settled to satisfy: it is at least as good as something already
held sufficient. -/
def SettledSufficient (S : Standard C) (c : C) : Prop :=
  ∃ a ∈ S.sufficient, S.atLeastAsGood c a

/-- Conduct settled to fall short: something already held insufficient is at
least as good as it. -/
def SettledInsufficient (S : Standard C) (c : C) : Prop :=
  ∃ b ∈ S.insufficient, S.atLeastAsGood b c

/-- Neither settled.  The region where the standard has no content yet. -/
def Unsettled (S : Standard C) (c : C) : Prop :=
  ¬ SettledSufficient S c ∧ ¬ SettledInsufficient S c

/-- Record a new decision. -/
def holdSufficient (S : Standard C) (c : C) : Standard C :=
  { S with sufficient := c :: S.sufficient }

def holdInsufficient (S : Standard C) (c : C) : Standard C :=
  { S with insufficient := c :: S.insufficient }

-- -------------------------------------------------------------------------

/-- Anything actually held sufficient is settled sufficient. -/
theorem sufficient_settled {S : Standard C} {c : C} (h : c ∈ S.sufficient) :
    SettledSufficient S c := ⟨c, h, S.refl c⟩

theorem insufficient_settled {S : Standard C} {c : C} (h : c ∈ S.insufficient) :
    SettledInsufficient S c := ⟨c, h, S.refl c⟩

/-- The sufficient region is closed upward. -/
theorem settled_sufficient_up {S : Standard C} {c d : C}
    (h : SettledSufficient S c) (hd : S.atLeastAsGood d c) : SettledSufficient S d := by
  obtain ⟨a, ha, hca⟩ := h
  exact ⟨a, ha, S.trans d c a hd hca⟩

/-- The insufficient region is closed downward. -/
theorem settled_insufficient_down {S : Standard C} {c d : C}
    (h : SettledInsufficient S c) (hd : S.atLeastAsGood c d) : SettledInsufficient S d := by
  obtain ⟨b, hb, hbc⟩ := h
  exact ⟨b, hb, S.trans b c d hbc hd⟩

/-- **A coherent record never settles the same conduct both ways.**

Note what is *not* assumed: that the comparative is total, that a threshold
exists, or that the standard is determinate anywhere outside the settled
region.  Coherence of the finite record is enough. -/
theorem not_settled_both_ways {S : Standard C} (hco : Coherent S) (c : C) :
    ¬ (SettledSufficient S c ∧ SettledInsufficient S c) := by
  rintro ⟨⟨a, ha, hca⟩, ⟨b, hb, hbc⟩⟩
  exact hco a ha b hb (S.trans b c a hbc hca)

/-- **Deciding an open case either way preserves coherence.**

This is the precise sense in which a vague standard leaves a court free.  Not
"the court may do as it likes" -- outside the open region it may not -- but
"within the open region, no decision contradicts the record". -/
theorem decide_open_preserves_coherent {S : Standard C} (hco : Coherent S)
    {c : C} (hopen : Unsettled S c) :
    Coherent (S.holdSufficient c) ∧ Coherent (S.holdInsufficient c) := by
  constructor
  · intro a ha b hb hab
    rcases List.mem_cons.mp ha with rfl | ha'
    · exact hopen.2 ⟨b, hb, hab⟩
    · exact hco a ha' b hb hab
  · intro a ha b hb hab
    rcases List.mem_cons.mp hb with rfl | hb'
    · exact hopen.1 ⟨a, ha, hab⟩
    · exact hco a ha b hb' hab

/-- **The settled region only grows.**  Recording a decision never unsettles
anything that was settled. -/
theorem settled_monotone {S : Standard C} {c d : C} :
    (SettledSufficient S d → SettledSufficient (S.holdSufficient c) d) ∧
    (SettledInsufficient S d → SettledInsufficient (S.holdInsufficient c) d) := by
  constructor
  · rintro ⟨a, ha, h⟩; exact ⟨a, List.mem_cons_of_mem _ ha, h⟩
  · rintro ⟨b, hb, h⟩; exact ⟨b, List.mem_cons_of_mem _ hb, h⟩

/-- A decision in the open region genuinely adds content: the conduct decided
becomes settled, and it was not settled before. -/
theorem decide_open_adds {S : Standard C} {c : C} (hopen : Unsettled S c) :
    ¬ SettledSufficient S c ∧ SettledSufficient (S.holdSufficient c) c :=
  ⟨hopen.1, ⟨c, List.mem_cons_self _ _, S.refl c⟩⟩

/-- **Vagueness is not ignorance.**  If conduct is open on the record, then
both extensions of the record are coherent -- so the record, which is all the
legal order has said, does not determine the answer.  Two tribunals may decide
the same open case oppositely and neither has made a mistake about the law.

The pipeline in `src/nomos/` uses this as its stopping condition: when a
provision turns on a standard and the situation is open, the correct
formalisation records the *gap*, not a guess. -/
theorem underdetermined {S : Standard C} (hco : Coherent S) {c : C}
    (hopen : Unsettled S c) :
    Coherent (S.holdSufficient c) ∧ Coherent (S.holdInsufficient c) :=
  decide_open_preserves_coherent hco hopen

end Standard

-- ---------------------------------------------------------------------------
-- A worked comparative: precaution against straying livestock
-- ---------------------------------------------------------------------------

/-- Degrees of precaution, ordered.  Drawn from m.Bava Kamma 6:1, which grades
penning ("shut it in properly" / "did not shut it in properly"), and from the
Digest's *custodia* vocabulary. -/
inductive Precaution where
  | none
  | token          -- a gesture: a low hurdle, an unlatched gate
  | ordinary       -- what a householder normally does
  | proper         -- *shemirah pechutah*: adequate to the ordinary risk
  | heightened     -- *shemirah me'ulah*: adequate to a known vice
  deriving DecidableEq, Repr, Inhabited

namespace Precaution

def rank : Precaution → Nat
  | none => 0 | token => 1 | ordinary => 2 | proper => 3 | heightened => 4

def atLeast (a b : Precaution) : Prop := b.rank ≤ a.rank

instance (a b : Precaution) : Decidable (atLeast a b) :=
  inferInstanceAs (Decidable (b.rank ≤ a.rank))

/-- The standard as m.Bava Kamma 6:1 leaves it.

The Mishnah's clear cases sit at the extremes: penning "properly" exempts, and
a merely token enclosure does not.  What the Mishnah does not say is what
proper penning *is*, nor whether the answer changes for an animal with a known
vice.  b.Bava Kamma 55b-56a is a sustained argument about precisely that gap --
whether *shemirah pechutah*, lesser guarding, suffices for an innocuous animal
while a forewarned one requires *shemirah me'ulah*.

We record the gap rather than closing it, and `ordinary_open` below states it
as a theorem. -/
def grazingStandard : Standard Precaution :=
  { name := "adequate penning (m.BK 6:1)"
  , atLeastAsGood := atLeast
  , refl := fun _ => Nat.le_refl _
  , trans := fun _ _ _ hab hbc => Nat.le_trans hbc hab
  , sufficient := [proper]
  , insufficient := [token] }

theorem grazing_coherent : Standard.Coherent grazingStandard := by
  intro a ha b hb hab
  have ha' : a = proper := by simpa [grazingStandard] using ha
  have hb' : b = token := by simpa [grazingStandard] using hb
  subst ha'; subst hb'
  exact absurd (show atLeast token proper from hab) (by decide)

/-- Heightened precaution is settled sufficient, a fortiori. -/
example : Standard.SettledSufficient grazingStandard heightened :=
  ⟨proper, by simp [grazingStandard], show atLeast heightened proper by decide⟩

/-- No precaution at all is settled insufficient, a fortiori from the token
case: anything the Mishnah's clear failure case already dominates fails too. -/
example : Standard.SettledInsufficient grazingStandard Precaution.none :=
  ⟨token, by simp [grazingStandard], show atLeast token Precaution.none by decide⟩

/-- Ordinary precaution is **open**: the Mishnah does not decide it.  This is
the formal statement of the question the Gemara goes on to argue about. -/
theorem ordinary_open : Standard.Unsettled grazingStandard ordinary := by
  constructor
  · rintro ⟨a, ha, h⟩
    have : a = proper := by simpa [grazingStandard] using ha
    subst this
    exact absurd (show atLeast ordinary proper from h) (by decide)
  · rintro ⟨b, hb, h⟩
    have : b = token := by simpa [grazingStandard] using hb
    subst this
    exact absurd (show atLeast token ordinary from h) (by decide)

end Precaution

end Nomos
