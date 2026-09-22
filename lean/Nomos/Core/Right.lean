/-
# Rights, as things reconstructed from liabilities

The organising conjecture of this project is that a right is not an extra fact
about the world lying alongside the liability rules, but a *pattern in* them:
to have a right to φ is (i) not to be answerable to anyone for doing φ, and
(ii) for others to become answerable to you if they interfere.  Consent, on
this picture, is the paradigm operation: it removes an exposure, and in doing
so hands a privilege to the person consented to.

This module makes that precise and then proves the conjecture's sharpest form:

> **`privilege_is_waiver`** -- every privilege is the waiver of some order.

That is, given any order in which `q` is at liberty against `p` as to `φ`,
there is an order differing from it only at that point in which `q` was not,
and the first is the waiver of the second.  Privilege and waiver are two
descriptions of one arrangement.  Nothing is lost by taking liability as
primitive and reading rights off it -- which is fortunate, because the earliest
texts in the corpus give us nothing else.

Hammurabi §57 is the case to keep in mind.  It does not say that a field-owner
has a right that his crop not be eaten.  It says that a shepherd who pastures
his flock on another's field *without the owner's leave* pays twenty gur of
grain for every ten gan.  Everything a modern lawyer would want to say about
the field-owner's right is recoverable from that sentence, and
`Hammurabi57.owner_has_right` below recovers it.

## Hohfeld

The eight incidents are defined in the usual way (Hohfeld 1913, 1917) and the
correlativity and opposition tables come out as theorems.  Most are `rfl` or
one line.  That is not a sign the formalisation is trivial; it is Hohfeld's
actual thesis.  He claimed that the eight terms name two relations seen from
either end together with their negations, and a formalisation in which the
tables need real work would have got him wrong.
-/

import Nomos.Core.Liability
import Nomos.Core.Standard

namespace Nomos

/-- A normative frame: states of a legal order, what each state exposes whom
to, which acts interfere with which, and how acts move between states.

Splitting states from the frame is what lets powers and immunities -- the
"second square" of Hohfeld's table, about changing positions rather than
occupying them -- be defined at all. -/
structure Frame where
  State : Type
  /-- `exposes s p q φ` : in state `s`, `p`'s doing `φ` makes `p` answerable
      to `q`.  This is the single primitive of the whole module. -/
  exposes : State → Party → Party → Act → Prop
  /-- `interferes ψ φ` : doing `ψ` obstructs the doing of `φ`. -/
  interferes : Act → Act → Prop
  /-- How an act changes the state of the order.  Most acts change nothing;
      the ones that do are the exercises of powers. -/
  effect : Party → Act → State → State

namespace Frame

variable (F : Frame)

-- ── first square: duty / claim / privilege / no-claim ────────────────────

/-- `p` owes `q` a duty not to do `φ`. -/
def Duty (s : F.State) (p q : Party) (φ : Act) : Prop := F.exposes s p q φ

/-- `q` has a claim against `p` that `p` not do `φ`. -/
def Claim (s : F.State) (q p : Party) (φ : Act) : Prop := F.exposes s p q φ

/-- `p` is at liberty, as against `q`, to do `φ`. -/
def Privilege (s : F.State) (p q : Party) (φ : Act) : Prop := ¬ F.exposes s p q φ

/-- `q` has no claim against `p` in respect of `φ`. -/
def NoClaim (s : F.State) (q p : Party) (φ : Act) : Prop := ¬ F.exposes s p q φ

-- ── second square: power / liability / immunity / disability ─────────────

/-- `p`'s doing `φ` alters whether `a` is exposed to `b` for `ψ`: `p` has a
power over that relation. -/
def Power (s : F.State) (p : Party) (φ : Act) (a b : Party) (ψ : Act) : Prop :=
  F.exposes (F.effect p φ s) a b ψ ≠ F.exposes s a b ψ

/-- Hohfeld's *liability*: susceptibility to having one's position changed.
Named `Subjection` here to keep it clear of the tort sense of "liability" that
`Nomos.Core.Liability` uses, which is the sense the rest of the library means. -/
def Subjection (s : F.State) (a b : Party) (ψ : Act) (p : Party) (φ : Act) : Prop :=
  F.Power s p φ a b ψ

def Disability (s : F.State) (p : Party) (φ : Act) (a b : Party) (ψ : Act) : Prop :=
  ¬ F.Power s p φ a b ψ

def Immunity (s : F.State) (a b : Party) (ψ : Act) (p : Party) (φ : Act) : Prop :=
  ¬ F.Power s p φ a b ψ

-- ── Hohfeld's tables ─────────────────────────────────────────────────────

theorem claim_correlative_duty (s : F.State) (p q : Party) (φ : Act) :
    F.Claim s q p φ ↔ F.Duty s p q φ := Iff.rfl

theorem privilege_correlative_noClaim (s : F.State) (p q : Party) (φ : Act) :
    F.Privilege s p q φ ↔ F.NoClaim s q p φ := Iff.rfl

theorem privilege_opposite_duty (s : F.State) (p q : Party) (φ : Act) :
    F.Privilege s p q φ ↔ ¬ F.Duty s p q φ := Iff.rfl

theorem noClaim_opposite_claim (s : F.State) (p q : Party) (φ : Act) :
    F.NoClaim s q p φ ↔ ¬ F.Claim s q p φ := Iff.rfl

theorem subjection_correlative_power (s : F.State) (a b p : Party) (ψ φ : Act) :
    F.Subjection s a b ψ p φ ↔ F.Power s p φ a b ψ := Iff.rfl

theorem immunity_correlative_disability (s : F.State) (a b p : Party) (ψ φ : Act) :
    F.Immunity s a b ψ p φ ↔ F.Disability s p φ a b ψ := Iff.rfl

theorem immunity_opposite_subjection (s : F.State) (a b p : Party) (ψ φ : Act) :
    F.Immunity s a b ψ p φ ↔ ¬ F.Subjection s a b ψ p φ := Iff.rfl

/-- Duty and privilege are jointly exhaustive and mutually exclusive: for any
pair and act, exactly one holds.  This uses excluded middle, which is the right
place for it -- the claim is that the order either does or does not expose you,
with no third option, and that *is* a substantive commitment about legal
orders which some jurisprudential positions would deny. -/
theorem duty_or_privilege (s : F.State) (p q : Party) (φ : Act) :
    F.Duty s p q φ ∨ F.Privilege s p q φ :=
  Classical.em _

theorem not_duty_and_privilege (s : F.State) (p q : Party) (φ : Act) :
    ¬ (F.Duty s p q φ ∧ F.Privilege s p q φ) := fun h => h.2 h.1

-- ── rights ───────────────────────────────────────────────────────────────

/-- A right to φ, in the full (vested, Hohfeldian-composite) sense: the liberty
to do it and a claim against interference.

Both halves are needed and they come apart in the corpus.  A Roman citizen had
the liberty to walk on the public road but no claim against being jostled
(liberty without claim); a bailee in m.Bava Metzia 3:1 may have a claim to
possession against third parties while owing a duty to the bailor not to use
the thing (claim without liberty). -/
structure RightTo (s : F.State) (p : Party) (φ : Act) : Prop where
  liberty    : ∀ q, F.Privilege s p q φ
  protection : ∀ q ψ, F.interferes ψ φ → F.exposes s q p ψ

theorem right_implies_no_duty {s : F.State} {p : Party} {φ : Act}
    (h : F.RightTo s p φ) (q : Party) : ¬ F.Duty s p q φ := h.liberty q

end Frame

-- ---------------------------------------------------------------------------
-- Waiver
-- ---------------------------------------------------------------------------

namespace Frame

variable (F : Frame)

/-- `waive s p q φ` : the exposure relation that results when `p` releases `q`
from answerability for `φ`.  Only that one triple changes.

This is consent, leave, licence, *venia*, *reshut* -- the operation every legal
order in the corpus has, and the one Hammurabi §57 makes the hinge of the
grazing rule. -/
def waived (s : F.State) (p q : Party) (φ : Act) :
    Party → Party → Act → Prop :=
  fun a b ψ => if a = q ∧ b = p ∧ ψ = φ then False else F.exposes s a b ψ

theorem waived_removes (s : F.State) (p q : Party) (φ : Act) :
    ¬ F.waived s p q φ q p φ := by
  simp [waived]

theorem waived_preserves (s : F.State) (p q : Party) (φ : Act)
    {a b : Party} {ψ : Act} (hne : ¬ (a = q ∧ b = p ∧ ψ = φ)) :
    F.waived s p q φ a b ψ ↔ F.exposes s a b ψ := by
  simp [waived, hne]

/-- The exposure relation obtained by *withdrawing* a waiver: the same order
except that `q` is answerable to `p` for `φ`.  This is the counterfactual a
lawyer reaches for when explaining what consent did. -/
def unwaived (s : F.State) (p q : Party) (φ : Act) :
    Party → Party → Act → Prop :=
  fun a b ψ => if a = q ∧ b = p ∧ ψ = φ then True else F.exposes s a b ψ

theorem unwaived_exposes (s : F.State) (p q : Party) (φ : Act) :
    F.unwaived s p q φ q p φ := by simp [unwaived]

theorem unwaived_preserves (s : F.State) (p q : Party) (φ : Act)
    {a b : Party} {ψ : Act} (hne : ¬ (a = q ∧ b = p ∧ ψ = φ)) :
    F.unwaived s p q φ a b ψ ↔ F.exposes s a b ψ := by
  simp [unwaived, hne]

/-- **Every privilege is a waiver.**

If `q` is at liberty against `p` as to `φ`, then waiving that exposure in the
order `unwaived` -- which differs from the actual order at exactly that one
triple, and in which `q` was *not* at liberty -- gives back the actual order.

This is the conjecture stated at the top of the module, and it is what licenses
the project's method of reading ancient codes.  The codes state exposures.
Rights are the shape those exposures take, and nothing further has to be
posited to recover them. -/
theorem privilege_is_waiver (s : F.State) (p q : Party) (φ : Act)
    (h : F.Privilege s q p φ) (a b : Party) (ψ : Act) :
    (if a = q ∧ b = p ∧ ψ = φ then False else F.unwaived s p q φ a b ψ)
      ↔ F.exposes s a b ψ := by
  by_cases hc : a = q ∧ b = p ∧ ψ = φ
  · rw [if_pos hc]
    refine iff_of_false id ?_
    obtain ⟨h1, h2, h3⟩ := hc
    subst h1; subst h2; subst h3
    exact h
  · rw [if_neg hc]
    exact F.unwaived_preserves s p q φ hc

end Frame

-- ---------------------------------------------------------------------------
-- Worked reconstruction: Hammurabi §57
-- ---------------------------------------------------------------------------

/-!
### Reading a right out of a liability rule

Laws of Hammurabi §57 (Harper's numbering): if a shepherd has not come to an
agreement with the owner of a field to pasture sheep, and without the owner's
consent pastures them there, the owner harvests his field and the shepherd who
pastured without consent gives over, in addition, twenty gur of grain per ten
gan to the owner.

The provision states one exposure and one defeating condition.  Below we build
the smallest frame that says exactly that, and then *derive* the field-owner's
right, rather than stipulating it.
-/

namespace Hammurabi57

open Nomos

/-- The two states this rule distinguishes: leave given, or not. -/
inductive Leave where
  | withheld
  | given
  deriving DecidableEq, Repr, Inhabited

def shepherd : Party := ⟨"shepherd"⟩
def owner : Party := ⟨"field-owner"⟩
def graze : Act := ⟨"pasture the flock on the field"⟩
def harvest : Act := ⟨"harvest one's own field"⟩

/-- The frame LH §57 describes: grazing on this field exposes whoever does it
to the owner exactly when leave was withheld, and grazing interferes with
harvesting.

Note that the exposure is not indexed to the shepherd as an individual.  "The
shepherd" in the provision is a role, and the rule reaches anyone who pastures
without leave; making the frame name an individual would build an accidental
feature of the drafting into the formalisation. -/
def frame : Frame :=
  { State := Leave
  , exposes := fun s _a b ψ =>
      s = Leave.withheld ∧ b = owner ∧ ψ = graze
  , interferes := fun ψ φ => ψ = graze ∧ φ = harvest
  , effect := fun p ψ s => if p = owner ∧ ψ = ⟨"give leave"⟩ then Leave.given else s }

/-- Without leave, the shepherd is exposed: the rule as stated. -/
theorem exposed_without_leave :
    frame.exposes Leave.withheld shepherd owner graze :=
  ⟨rfl, rfl, rfl⟩

/-- With leave, he is not.  The consent clause is a waiver. -/
theorem privileged_with_leave :
    frame.Privilege Leave.given shepherd owner graze := by
  rintro ⟨h, _, _⟩
  exact absurd h (by decide)

/-- **The owner's right, derived.**  In the state the provision actually
addresses -- leave withheld -- the field-owner has a right to harvest his own
field in the full sense: he is answerable to nobody for harvesting, and anyone
who interferes by grazing is answerable to him.

Neither half is stated in the text.  Both follow from the one exposure the text
does state.  This is the inference the autoformalisation pipeline is being
asked to make at scale. -/
theorem owner_has_right : frame.RightTo Leave.withheld owner harvest := by
  constructor
  · rintro q ⟨_, _, h⟩
    exact absurd h (by decide)
  · rintro q ψ ⟨hψ, _⟩
    subst hψ
    exact ⟨rfl, rfl, rfl⟩

/-- The owner's power: giving leave moves the order to the state in which the
shepherd is privileged.  Consent is an exercise of a Hohfeldian power, and the
shepherd's position before it is exercised is a Hohfeldian subjection. -/
theorem owner_has_power_to_licence :
    frame.effect owner ⟨"give leave"⟩ Leave.withheld = Leave.given := by
  simp [frame, owner]

end Hammurabi57

end Nomos
