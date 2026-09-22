/-
# Precedential constraint

This module formalises the *reason model* of precedential constraint due to
Horty (2011) and Horty & Bench-Capon (2012), in the form:

> A case base forces an outcome in a new fact situation when some precedent
> with that outcome is such that (i) everything the precedent relied on is
> present in the new situation, and (ii) the new situation raises no
> counter-reason that the precedent had not already overcome.

The condition is an *a fortiori* one.  It does not say that the cases are
similar; it says that the new case is at least as strong for the winner as the
old one was.  That asymmetry is what makes precedent a constraint rather than a
resemblance heuristic, and it is the reason this model, rather than a
similarity metric, is the backbone of the project.

## Why this is the right target for an ancient corpus

The model was built to reconstruct Anglo-American case law, so using it on
Hammurabi needs a word of defence.  The defence is that the model's primitives
-- a fact situation described by one-sided reasons, an outcome, and a subset of
reasons actually relied upon -- are not peculiar to common law.  They are what
you get whenever a tradition (a) decides concrete disputes, (b) records which
features of the dispute mattered, and (c) treats past decisions as authority
for later ones.  The rabbinic material satisfies all three explicitly: Mishnah
Bava Kamma 1:1 states four paradigm cases, distinguishes them pairwise, and
then extracts *ha-tzad ha-shaveh she-bahen*, "the common feature among them",
precisely in order to license extension to cases not enumerated.  That is
reason-model constraint, described from the inside, around 200 CE.

The Roman material satisfies them too, though less self-consciously: the
Digest is an edited compilation of jurists' responses to concrete facts,
routinely reasoning by extension (*utilis actio*) and restriction from a
paradigm.  The codes proper -- Hammurabi, Eshnunna, the Hittite laws -- are
the hard case, because they record outcomes without reasons.  For those we
take the weakest reading available (reason = all of the winner's factors),
which claims the least and constrains the least.  See `Holding.reason`.

## References

* Horty, "Rules and reasons in the theory of precedent", *Legal Theory* 17
  (2011).
* Horty & Bench-Capon, "A factor-based definition of precedential constraint",
  *Artificial Intelligence and Law* 20 (2012).
* Rigoni, "An improved factor based approach to precedential constraint",
  *AI and Law* 23 (2015), for the treatment of unrelied-upon factors.
-/

import Nomos.Core.Liability

namespace Nomos

/-- A precedent is a holding that is being treated as authority.  We keep the
abbreviation so that the intent is visible at use sites. -/
abbrev Precedent := Holding

/-- The situation `s` is *at least as strong for the winner* of `h` as `h`'s own
situation was.

This is the a fortiori relation.  Unpacking the two clauses:

* `reason_present` -- every factor the tribunal in `h` actually relied on is
  also present in `s`.  If any is missing, the precedent is *distinguished on
  its ratio*.
* `no_new_counter` -- every factor in `s` that cuts against `h`'s winner was
  already present in `h`.  If `s` has a fresh counter-reason, the precedent did
  not adjudicate it, and is *distinguished on a new ground*.

Note the asymmetry: `s` may contain *additional* factors favouring the winner
without weakening the constraint.  More support never hurts. -/
structure AtLeastAsStrong (s : Situation) (h : Holding) : Prop where
  reason_present  : ∀ f ∈ h.reason, f ∈ s.factors
  no_new_counter  : ∀ f ∈ s.forSide h.winner.other, f ∈ h.situation.forSide h.winner.other

instance (s : Situation) (h : Holding) : Decidable (AtLeastAsStrong s h) := by
  refine @decidable_of_iff _ ((∀ f ∈ h.reason, f ∈ s.factors) ∧
      (∀ f ∈ s.forSide h.winner.other, f ∈ h.situation.forSide h.winner.other)) ?_ ?_
  · exact ⟨fun ⟨a, b⟩ => ⟨a, b⟩, fun ⟨a, b⟩ => ⟨a, b⟩⟩
  · exact instDecidableAnd

/-- A case base: the decisions a legal order has on record. -/
structure Corpus where
  name  : String
  cases : List Precedent
  deriving Repr, Inhabited

namespace Corpus

def empty (n : String) : Corpus := ⟨n, []⟩

def add (Γ : Corpus) (h : Precedent) : Corpus := ⟨Γ.name, h :: Γ.cases⟩

/-- Every holding on record is well-formed. -/
def Sound (Γ : Corpus) : Prop := ∀ h ∈ Γ.cases, h.WellFormed

instance (Γ : Corpus) : Decidable Γ.Sound :=
  List.decidableBAll _ Γ.cases

end Corpus

/-- `Γ` *forces* `side` in `s`: some precedent for `side` binds `s` a fortiori. -/
def Forces (Γ : Corpus) (s : Situation) (side : Side) : Prop :=
  ∃ h ∈ Γ.cases, h.winner = side ∧ AtLeastAsStrong s h

/-- The witness that does the forcing, when one exists. -/
def witness (Γ : Corpus) (s : Situation) (side : Side) : Option Precedent :=
  Γ.cases.find? (fun h => decide (h.winner = side) && decide (AtLeastAsStrong s h))

/-- A situation is *open* under `Γ` when nothing on record settles it.  This is
the interesting region: it is where courts make law rather than apply it, and
it is the target the autoformalisation pipeline is aimed at. -/
def Open (Γ : Corpus) (s : Situation) : Prop :=
  ¬ Forces Γ s Side.claimant ∧ ¬ Forces Γ s Side.respondent

/-- `Γ` is *coherent* when it never forces both outcomes in the same
situation.  We avoid the word "consistent" because a case base that forces
both outcomes is not logically inconsistent -- it is a legal order in
conflict, which is a real and common condition. -/
def Coherent (Γ : Corpus) : Prop :=
  ∀ s : Situation, ¬ (Forces Γ s Side.claimant ∧ Forces Γ s Side.respondent)

/-- Coherence restricted to a finite list of situations.

Full coherence quantifies over every situation and so is not decidable.  This
restriction is, and it is what one actually checks: whether the order
contradicts itself on the facts it has in fact addressed.  `Γ.situations`
supplies the natural list. -/
def CoherentOn (Γ : Corpus) (ss : List Situation) : Prop :=
  ∀ s ∈ ss, ¬ (Forces Γ s Side.claimant ∧ Forces Γ s Side.respondent)

instance (Γ : Corpus) (s : Situation) (side : Side) : Decidable (Forces Γ s side) :=
  List.decidableBEx _ Γ.cases

instance (Γ : Corpus) (ss : List Situation) : Decidable (CoherentOn Γ ss) :=
  List.decidableBAll _ ss

instance (Γ : Corpus) (s : Situation) : Decidable (Open Γ s) := by
  unfold Open; infer_instance

namespace Corpus

/-- The situations the corpus has actually addressed. -/
def situations (Γ : Corpus) : List Situation := Γ.cases.map Holding.situation

/-- Merge two case bases.  Doing this across traditions is the central
comparative operation, and `Nomos.Bench` shows it usually fails to be
coherent -- which is the point. -/
def merge (a b : Corpus) : Corpus :=
  ⟨a.name ++ " + " ++ b.name, a.cases ++ b.cases⟩

/-- The pairs of holdings that force opposite outcomes on a given situation.
This is the diagnostic a formaliser wants when `CoherentOn` fails: not that
something is wrong, but *which two rulings* are pulling against each other. -/
def conflictsAt (Γ : Corpus) (s : Situation) : List (Precedent × Precedent) :=
  let pro := Γ.cases.filter (fun h => decide (h.winner = Side.claimant) &&
                                      decide (AtLeastAsStrong s h))
  let con := Γ.cases.filter (fun h => decide (h.winner = Side.respondent) &&
                                      decide (AtLeastAsStrong s h))
  pro.flatMap (fun p => con.map (fun c => (p, c)))

end Corpus

-- ---------------------------------------------------------------------------
-- Basic structural results
-- ---------------------------------------------------------------------------

namespace AtLeastAsStrong

/-- A well-formed precedent binds its own situation.  Well-formedness is
needed and not decorative: a tribunal that purported to rely on a factor not
in the case would state a rule its own decision does not instantiate. -/
theorem self (h : Holding) (hw : h.WellFormed) : AtLeastAsStrong h.situation h :=
  { reason_present := fun f hf => (hw.2 f hf).1
    no_new_counter := fun _ hf => hf }

/-- Adding factors that favour the precedent's winner preserves the relation.
This is the core a fortiori step: extra support never defeats a precedent. -/
theorem add_supporting {s : Situation} {h : Holding} (hs : AtLeastAsStrong s h)
    (fs : List Factor) (hfs : ∀ f ∈ fs, f.side = h.winner) :
    AtLeastAsStrong (s.with_ fs) h := by
  refine ⟨?_, ?_⟩
  · intro f hf
    exact List.mem_append_right _ (hs.reason_present f hf)
  · intro f hf
    obtain ⟨hm, hside⟩ := Situation.mem_forSide hf
    -- `f` cuts against the winner, so it cannot have come from `fs`
    rcases List.mem_append.mp hm with hfsm | hsm
    · exact absurd (hfs f hfsm) (by rw [hside]; exact (Side.other_ne h.winner))
    · exact hs.no_new_counter f (Situation.mem_forSide_of hsm hside)

end AtLeastAsStrong

namespace Forces

/-- A well-formed precedent forces its own outcome in its own situation. -/
theorem of_mem {Γ : Corpus} {h : Precedent} (hm : h ∈ Γ.cases) (hw : h.WellFormed) :
    Forces Γ h.situation h.winner :=
  ⟨h, hm, rfl, AtLeastAsStrong.self h hw⟩

/-- Monotone in the case base: adding decisions never withdraws a constraint.
Law accumulates. -/
theorem mono_corpus {Γ : Corpus} {h : Precedent} {s : Situation} {side : Side}
    (hf : Forces Γ s side) : Forces (Γ.add h) s side := by
  obtain ⟨c, hc, hw, ha⟩ := hf
  exact ⟨c, List.mem_cons_of_mem _ hc, hw, ha⟩

/-- Monotone in the strength of the situation: if a situation is forced for a
side, so is any situation that adds only factors favouring that side. -/
theorem mono_situation {Γ : Corpus} {s : Situation} {side : Side}
    (hf : Forces Γ s side) (fs : List Factor) (hfs : ∀ f ∈ fs, f.side = side) :
    Forces Γ (s.with_ fs) side := by
  obtain ⟨c, hc, hw, ha⟩ := hf
  refine ⟨c, hc, hw, AtLeastAsStrong.add_supporting ha fs ?_⟩
  intro f hmem; rw [hw]; exact hfs f hmem

end Forces

-- ---------------------------------------------------------------------------
-- What precedent does to the deciding court
-- ---------------------------------------------------------------------------

/-- **Precedent binds.**  If the record already forces one outcome, deciding
the other way puts the order in conflict with itself -- the augmented record
forces both outcomes in that very situation. -/
theorem decision_against_precedent_incoherent
    {Γ : Corpus} {s : Situation} {side : Side}
    (hforced : Forces Γ s side)
    (c : Precedent) (hc : c.situation = s) (hcw : c.winner = side.other)
    (hcwf : c.WellFormed) :
    ¬ Coherent (Γ.add c) := by
  intro hco
  have h1 : Forces (Γ.add c) s side := Forces.mono_corpus hforced
  have h2 : Forces (Γ.add c) s side.other := by
    refine ⟨c, List.mem_cons_self _ _, hcw, ?_⟩
    have := AtLeastAsStrong.self c hcwf
    rwa [hc] at this
  cases side with
  | claimant => exact hco s ⟨h1, h2⟩
  | respondent => exact hco s ⟨h2, h1⟩

/-- **The gap is free.**  If the record settles nothing in `s`, then deciding
`s` either way leaves that situation settled exactly one way.  A court facing a
genuinely open question cannot decide it wrongly *as against precedent*,
because there is no precedent to be wrong against.

This is the formal residue of legal indeterminacy.  It is not a defect of the
model; it is the model's report that the content of the law, at that point, is
not yet fixed by what has been decided.  Everything the autoformalisation
pipeline does with analogy lives in this region. -/
theorem open_decision_settles_one_way
    {Γ : Corpus} {s : Situation} {side : Side}
    (hopen : ¬ Forces Γ s side.other)
    (c : Precedent) (hc : c.situation = s) (hcw : c.winner = side)
    (hcwf : c.WellFormed) :
    Forces (Γ.add c) s side ∧ ¬ Forces (Γ.add c) s side.other := by
  constructor
  · refine ⟨c, List.mem_cons_self _ _, hcw, ?_⟩
    have := AtLeastAsStrong.self c hcwf
    rwa [hc] at this
  · rintro ⟨d, hd, hdw, _⟩
    rcases List.mem_cons.mp hd with rfl | hd'
    · exact absurd (hcw ▸ hdw) (by simpa using (Side.other_ne side).symm)
    · exact hopen ⟨d, hd', hdw, by assumption⟩

/-- A precedent is *distinguishable* in a new situation exactly when the a
fortiori relation fails: either part of its ratio is absent, or the new case
raises a counter-reason the precedent never faced.  Courts have no third way of
escaping a precedent within this model, which is a substantive claim about
what distinguishing is. -/
theorem distinguishable_iff (s : Situation) (h : Holding) :
    ¬ AtLeastAsStrong s h ↔
      (∃ f ∈ h.reason, f ∉ s.factors) ∨
      (∃ f ∈ s.forSide h.winner.other, f ∉ h.situation.forSide h.winner.other) := by
  constructor
  · intro hn
    refine Classical.byContradiction (fun hcon => hn ⟨?_, ?_⟩)
    · exact fun f hf => Classical.byContradiction fun hnf => hcon (Or.inl ⟨f, hf, hnf⟩)
    · exact fun f hf => Classical.byContradiction fun hnf => hcon (Or.inr ⟨f, hf, hnf⟩)
  · rintro (⟨f, hf, hnf⟩ | ⟨f, hf, hnf⟩) hs
    · exact hnf (hs.reason_present f hf)
    · exact hnf (hs.no_new_counter f hf)

end Nomos
