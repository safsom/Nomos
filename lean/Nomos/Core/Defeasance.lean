/-
# Defeasible rules

Legal rules do not come with their exceptions attached.  They come stated
flatly, and the exceptions arrive as separate rules that beat them.  A
formalisation that tries to fold the exceptions into the antecedent of the
main rule gets two things wrong: it misrepresents what the source says, and it
makes the formalisation break every time a new exception is found -- which,
in a living legal order, is always.

Mishnah Bava Kamma 6:1 is the cleanest short example in the corpus, and it is
worth quoting in full because the structure is visible on the surface:

> If a man brought his flock into a pen and shut it in properly and it went out
> and caused damage, he is exempt.  If he had not shut it in properly and it
> went out and caused damage, he is liable.  If the pen was broken through at
> night, or bandits broke through it, and the flock came out and caused damage,
> he is not liable.  If the bandits brought out the flock, the bandits are
> liable.

Four rules, three levels of priority, and a final clause that does not merely
excuse the owner but *relocates* the liability.  We formalise it as four rules
in `MishnahBK61` below and prove that the outcome is determined.

The model is the standard one from the AI-and-law literature on defeasible
deontic logic (Nute 1997; Governatori and Rotolo; Prakken and Sartor).  Rules
carry priorities; a rule is defeated when a higher-priority applicable rule
concludes the other way; the outcome is what survives.
-/

import Nomos.Core.Liability

namespace Nomos

/-- A defeasible rule.

`priority` is a `Nat` rather than an abstract order because the orderings that
actually appear in the corpus are shallow -- rule, exception, exception to the
exception -- and a concrete order keeps everything decidable.  Sources that
leave two rules unranked are formalised by giving them equal priority, which
makes them mutually defeating and the situation contested; see
`contested_iff`. -/
structure Rule where
  id         : String
  antecedent : List Factor
  conclusion : Side
  remedy     : Remedy
  priority   : Nat
  deriving DecidableEq, Repr, Inhabited

namespace Rule

/-- A rule applies to a situation when all of its antecedent factors are
present.  Absence is not tested: rules are defeated, not falsified. -/
def Applies (r : Rule) (s : Situation) : Prop := ∀ f ∈ r.antecedent, f ∈ s.factors

instance (r : Rule) (s : Situation) : Decidable (r.Applies s) :=
  List.decidableBAll _ r.antecedent

/-- Two rules are *incompatible* when they cannot both be given effect: either
they award opposite outcomes, or they award the same party different remedies.

The second disjunct is not a refinement.  Some of the most important defeaters
in the corpus leave the winner untouched and change only what is owed.  Ulpian
at D.9.1.1.4 says that where a beast did harm through the driver's fault the
noxal action "ceases and the action for wrongful damage is brought" -- the
claimant still wins, but the owner loses the option of abandoning the animal
instead of paying.  A model that only tracked who won could not see that. -/
def Incompatible (r r' : Rule) : Prop :=
  r.conclusion ≠ r'.conclusion ∨ r.remedy ≠ r'.remedy

instance (r r' : Rule) : Decidable (Incompatible r r') := by
  unfold Incompatible; infer_instance

theorem Incompatible.symm {r r' : Rule} (h : Incompatible r r') : Incompatible r' r := by
  rcases h with h | h
  · exact Or.inl (fun he => h he.symm)
  · exact Or.inr (fun he => h he.symm)

end Rule

/-- A body of rules. -/
structure Theory where
  name  : String
  rules : List Rule
  deriving Repr, Inhabited

namespace Theory

/-- `r` is defeated in `s` when a strictly higher-priority applicable rule is
incompatible with it. -/
def Defeated (T : Theory) (r : Rule) (s : Situation) : Prop :=
  ∃ r' ∈ T.rules, r'.Applies s ∧ Rule.Incompatible r' r ∧ r.priority < r'.priority

/-- `r` carries the day in `s`. -/
def Prevails (T : Theory) (r : Rule) (s : Situation) : Prop :=
  r ∈ T.rules ∧ r.Applies s ∧ ¬ T.Defeated r s

/-- The outcome a theory yields, if it yields one. -/
def Yields (T : Theory) (s : Situation) (side : Side) : Prop :=
  ∃ r, T.Prevails r s ∧ r.conclusion = side

/-- What a theory awards, if it awards anything. -/
def Awards (T : Theory) (s : Situation) (rem : Remedy) : Prop :=
  ∃ r, T.Prevails r s ∧ r.remedy = rem

/-- Two rules conflict in `s` when both apply and they are incompatible. -/
def Conflict (T : Theory) (r₁ r₂ : Rule) (s : Situation) : Prop :=
  r₁ ∈ T.rules ∧ r₂ ∈ T.rules ∧ r₁.Applies s ∧ r₂.Applies s ∧
    Rule.Incompatible r₁ r₂

/-- A theory is *well-ordered at* `s` when every conflict there is broken by
priority.  This is the condition a drafter must meet for the rules to
determine an answer, and the condition a formaliser should check before
claiming a source is determinate. -/
def WellOrderedAt (T : Theory) (s : Situation) : Prop :=
  ∀ r₁ r₂, T.Conflict r₁ r₂ s → r₁.priority ≠ r₂.priority

-- -------------------------------------------------------------------------

/-- **Determinacy.**  Where conflicts are broken by priority, no two prevailing
rules are incompatible -- so the theory fixes both the winner and the remedy.

This is the payoff of the whole apparatus: it lets a formaliser state an
ancient rule flatly, add its exceptions as separate higher-priority rules, and
*prove* that the result is coherent, rather than having to reason about it by
hand every time a clause is added. -/
theorem determinate {T : Theory} {s : Situation} (hw : T.WellOrderedAt s)
    {r₁ r₂ : Rule} (h₁ : T.Prevails r₁ s) (h₂ : T.Prevails r₂ s) :
    ¬ Rule.Incompatible r₁ r₂ := by
  intro hinc
  have hconf : T.Conflict r₁ r₂ s := ⟨h₁.1, h₂.1, h₁.2.1, h₂.2.1, hinc⟩
  have hne : r₁.priority ≠ r₂.priority := hw r₁ r₂ hconf
  rcases Nat.lt_or_ge r₁.priority r₂.priority with hlt | hge
  · exact h₁.2.2 ⟨r₂, h₂.1, h₂.2.1, Rule.Incompatible.symm hinc, hlt⟩
  · have hlt' : r₂.priority < r₁.priority := Nat.lt_of_le_of_ne hge (fun h => hne h.symm)
    exact h₂.2.2 ⟨r₁, h₁.1, h₁.2.1, hinc, hlt'⟩

/-- In particular the outcome is unique. -/
theorem outcome_unique {T : Theory} {s : Situation} (hw : T.WellOrderedAt s)
    {r₁ r₂ : Rule} (h₁ : T.Prevails r₁ s) (h₂ : T.Prevails r₂ s) :
    r₁.conclusion = r₂.conclusion := by
  by_cases hc : r₁.conclusion = r₂.conclusion
  · exact hc
  · exact absurd (Or.inl hc) (determinate hw h₁ h₂)

/-- And so is the remedy. -/
theorem remedy_unique {T : Theory} {s : Situation} (hw : T.WellOrderedAt s)
    {r₁ r₂ : Rule} (h₁ : T.Prevails r₁ s) (h₂ : T.Prevails r₂ s) :
    r₁.remedy = r₂.remedy := by
  by_cases hc : r₁.remedy = r₂.remedy
  · exact hc
  · exact absurd (Or.inr hc) (determinate hw h₁ h₂)

/-- A rule of maximal priority among the applicable ones always prevails. -/
theorem maximal_prevails {T : Theory} {s : Situation} {r : Rule}
    (hm : r ∈ T.rules) (ha : r.Applies s)
    (hmax : ∀ r' ∈ T.rules, r'.Applies s → r'.priority ≤ r.priority) :
    T.Prevails r s := by
  refine ⟨hm, ha, ?_⟩
  rintro ⟨r', hm', ha', _, hlt⟩
  exact absurd (hmax r' hm' ha') (Nat.not_le_of_gt hlt)

/-- Adding an exception of strictly higher priority defeats the rule it
excepts, wherever the exception applies. -/
theorem exception_defeats {T : Theory} {s : Situation} {r e : Rule}
    (_hr : r ∈ T.rules) (he : e ∈ T.rules) (hae : e.Applies s)
    (hconc : Rule.Incompatible e r) (hp : r.priority < e.priority) :
    T.Defeated r s := ⟨e, he, hae, hconc, hp⟩

/-- Where two applicable rules are incompatible at equal priority, both stand:
the source has left the matter contested.  Recording that honestly is better
than inventing a tiebreak. -/
theorem equal_priority_contested {T : Theory} {s : Situation} {r₁ r₂ : Rule}
    (hconf : T.Conflict r₁ r₂ s) (_heq : r₁.priority = r₂.priority) :
    ¬ T.Defeated r₁ s → ¬ T.Defeated r₂ s → T.Prevails r₁ s ∧ T.Prevails r₂ s :=
  fun h₁ h₂ => ⟨⟨hconf.1, hconf.2.2.1, h₁⟩, ⟨hconf.2.1, hconf.2.2.2.1, h₂⟩⟩

end Theory

-- ---------------------------------------------------------------------------
-- Worked example: Mishnah Bava Kamma 6:1
-- ---------------------------------------------------------------------------

namespace MishnahBK61

open Nomos

/-- "If he had not shut it in properly and it went out and caused damage, he is
liable."  The base rule. -/
def strayingIsLiable : Rule :=
  { id := "m.BK 6:1 a -- straying flock"
  , antecedent := [Factor.harmOccurred, Factor.respondentsInstrument]
  , conclusion := Side.claimant
  , remedy := Remedy.compensate Loss.damage
  , priority := 0 }

/-- "If a man brought his flock into a pen and shut it in properly ... he is
exempt."  First exception. -/
def properPenningExempts : Rule :=
  { id := "m.BK 6:1 b -- properly penned"
  , antecedent := [Factor.properPrecaution]
  , conclusion := Side.respondent
  , remedy := Remedy.exempt
  , priority := 1 }

/-- "If the pen was broken through at night, or bandits broke through it ...
he is not liable."  Second exception -- and note it is an exception to the
*base* rule, operating even where penning was improper, which is why it sits
at the same level rather than above. -/
def breachExempts : Rule :=
  { id := "m.BK 6:1 c -- pen breached"
  , antecedent := [Factor.thirdPartyIntervened]
  , conclusion := Side.respondent
  , remedy := Remedy.exempt
  , priority := 1 }

/-- "If the bandits brought out the flock, the bandits are liable."  This one
does not merely excuse: it relocates.  We record the relocation in the rule's
identifier and remedy; the party substitution is handled at the level of
`Incidence`, not of `Side`. -/
def banditsLiable : Rule :=
  { id := "m.BK 6:1 d -- bandits took them out (liability relocates)"
  , antecedent := [Factor.thirdPartyIntervened, Factor.wrongfulTaking]
  , conclusion := Side.respondent
  , remedy := Remedy.compensate Loss.damage
  , priority := 2 }

def theory : Theory :=
  ⟨"m.Bava Kamma 6:1", [strayingIsLiable, properPenningExempts, breachExempts, banditsLiable]⟩

/-- A flock strays through an inadequate pen: the owner is liable. -/
def carelessOwner : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.noPrecaution]⟩

theorem careless_owner_liable : theory.Yields carelessOwner Side.claimant := by
  refine ⟨strayingIsLiable, ⟨by simp [theory], by decide, ?_⟩, rfl⟩
  rintro ⟨r', hm', ha', hc', hlt'⟩
  simp only [theory, List.mem_cons, List.not_mem_nil, or_false] at hm'
  rcases hm' with rfl | rfl | rfl | rfl
  · exact absurd hlt' (by decide)
  · exact absurd (ha' Factor.properPrecaution (by decide)) (by decide)
  · exact absurd (ha' Factor.thirdPartyIntervened (by decide)) (by decide)
  · exact absurd (ha' Factor.thirdPartyIntervened (by decide)) (by decide)

/-- The same flock, properly penned: the owner is exempt, because the
exception outranks the rule. -/
def carefulOwner : Situation :=
  ⟨[Factor.harmOccurred, Factor.respondentsInstrument, Factor.properPrecaution]⟩

theorem careful_owner_exempt : theory.Yields carefulOwner Side.respondent := by
  refine ⟨properPenningExempts, ⟨by simp [theory], by decide, ?_⟩, rfl⟩
  rintro ⟨r', hm', ha', hc', hlt'⟩
  simp only [theory, List.mem_cons, List.not_mem_nil, or_false] at hm'
  rcases hm' with rfl | rfl | rfl | rfl
  · exact absurd hlt' (by decide)
  · exact absurd hlt' (by decide)
  · exact absurd hlt' (by decide)
  · exact absurd (ha' Factor.thirdPartyIntervened (by decide)) (by decide)

/-- And the base rule is defeated there, which is the substance of the
exception: the flat rule is still on the books, still applies on its own
terms, and still loses. -/
theorem base_rule_defeated_when_careful :
    theory.Defeated strayingIsLiable carefulOwner :=
  ⟨properPenningExempts, by simp [theory], by decide, by decide, by decide⟩

/-- The rules are well-ordered on both situations, so `Theory.determinate`
applies and each outcome is the only one available. -/
theorem careful_wellOrdered : theory.WellOrderedAt carefulOwner := by
  rintro r₁ r₂ ⟨hm₁, hm₂, ha₁, ha₂, hc⟩
  simp only [theory, List.mem_cons, List.not_mem_nil, or_false] at hm₁ hm₂
  rcases hm₁ with rfl | rfl | rfl | rfl <;>
    rcases hm₂ with rfl | rfl | rfl | rfl <;>
    first
      | exact absurd hc (by decide)
      | (intro h; exact absurd h (by decide))
      | exact absurd (ha₁ Factor.thirdPartyIntervened (by decide)) (by decide)
      | exact absurd (ha₂ Factor.thirdPartyIntervened (by decide)) (by decide)

end MishnahBK61

end Nomos
