/-
# Analogical extension, and its limits

Precedent tells you *who wins*.  Analogy is also asked to tell you *how much* --
and this is where ancient and modern legal reasoning alike run into a problem
that has a clean formal statement.

The rabbinic tradition isolated the problem and named the answer.  The
inference *kal va-chomer* (a fortiori: "light and heavy") argues that what
holds in a lighter case holds all the more in a heavier one.  The restriction
*dayyo* -- "it is enough for that which is derived to be like that from which
it derives" (m.Bava Kamma 2:5) -- forbids the conclusion from exceeding its
premise.  The Mishnah's dispute between the Sages and R. Tarfon over the
forewarned ox turns on exactly this, and the Sages' position is the one
formalised here.

The result below (`dayyo`, `no_strengthening`) says the restriction is not a
piece of rabbinic conservatism but a soundness condition:

> **Analogical extension transfers a lower bound, never a value.**

A precedent awarding remedy `r` in a lighter case, applied a fortiori to a
heavier one, entails that the heavier case attracts *at least* `r`.  It does
not entail any particular amount above `r`, because the award function that
gives exactly `r` everywhere is consistent with the precedent.  Any pipeline
that autoformalises a rule by analogy and emits a specific quantum has
therefore overclaimed, and `no_strengthening` is what tells you so.

The second result (`common_denominator_underdetermines`) concerns the other
classical rabbinic inference, *binyan av* / *ha-tzad ha-shaveh*: generalising
from paradigm cases by taking what they share.  Mishnah Bava Kamma 1:1 runs
this argument explicitly for the four categories of damage.  The theorem says
the generalisation is ampliative: the shared features, precisely *because* the
Mishnah has shown each paradigm to contribute something the others lack, do not
force the general rule.  The Mishnah's closing move -- "what they have in
common is ... and if one of them did injury, whoever is responsible must make
restitution" -- is a legislative act that the paradigms motivate but do not
compel.  That is a claim about legal reasoning, and here it is a theorem.
-/

import Nomos.Reasoning.Precedent

namespace Nomos

/-- What an order awards in each situation.  Total by construction, matching
the commitment in `Nomos.Core.Liability` that every harm is allocated. -/
abbrev Award := Situation → Remedy

namespace Award

/-- An award function *respects* a case base when every situation bound a
fortiori by a precedent receives at least that precedent's remedy.

Note that this is a constraint from below only.  Nothing here caps an award.
That asymmetry is the formal shadow of `dayyo`. -/
def Respects (a : Award) (Γ : Corpus) : Prop :=
  ∀ h ∈ Γ.cases, ∀ s : Situation, AtLeastAsStrong s h → Remedy.AtLeast (a s) h.remedy

/-- The constant award: give every situation exactly what the precedent gave.
This is the *dayyo* award -- the one that extends the rule and adds nothing. -/
def constant (r : Remedy) : Award := fun _ => r

theorem constant_respects_singleton (h : Precedent) :
    (constant h.remedy).Respects ⟨"dayyo", [h]⟩ := by
  intro c hc s _
  have : c = h := by simpa using List.mem_singleton.mp hc
  subst this
  exact Remedy.AtLeast.refl _

end Award

-- ---------------------------------------------------------------------------
-- kal va-chomer and dayyo
-- ---------------------------------------------------------------------------

/-- **Kal va-chomer.**  A fortiori transfer: a situation at least as strong as
a precedent attracts at least that precedent's remedy, under any award
respecting the record. -/
theorem kal_vachomer {a : Award} {Γ : Corpus} (hr : a.Respects Γ)
    {h : Precedent} (hm : h ∈ Γ.cases) {t : Situation}
    (hs : AtLeastAsStrong t h) : Remedy.AtLeast (a t) h.remedy :=
  hr h hm t hs

/-- **Dayyo.**  The lower bound delivered by `kal_vachomer` is tight: the
constant award realises it, so nothing above it is entailed. -/
theorem dayyo (h : Precedent) (t : Situation) :
    ∃ a : Award, a.Respects ⟨"dayyo", [h]⟩ ∧ a t = h.remedy :=
  ⟨Award.constant h.remedy, Award.constant_respects_singleton h, rfl⟩

/-- **No strengthening.**  If `r` is strictly heavier than the precedent's
remedy, then `r` is not entailed in any situation -- not even in one that is a
fortiori stronger than the precedent.

This is the formal reason a court extending a rule to a graver case must
either award the same quantum or give an independent reason for more.  It is
also a hard constraint on autoformalisation: a system that reads "if an ox
gores a slave, thirty shekels" and emits "therefore if it gores a free man,
*more than* thirty shekels" has produced an unsound formalisation, however
plausible the reading. -/
theorem no_strengthening (h : Precedent) (t : Situation) {r : Remedy}
    (hstrict : Remedy.Heavier r h.remedy) :
    ¬ (∀ a : Award, a.Respects ⟨"dayyo", [h]⟩ → Remedy.AtLeast (a t) r) := by
  intro hall
  obtain ⟨a, hresp, hat⟩ := dayyo h t
  have h1 : Remedy.AtLeast (a t) r := hall a hresp
  rw [hat] at h1
  exact hstrict.2 h1

-- ---------------------------------------------------------------------------
-- binyan av and ha-tzad ha-shaveh
-- ---------------------------------------------------------------------------

/-- *Binyan av*: the rule a single paradigm case projects is its ratio. -/
def binyanAv (h : Precedent) : List Factor := h.reason

/-- *Ha-tzad ha-shaveh*, "the common feature among them": the argument form of
m.Bava Kamma 1:1.

The structure has three parts, and all three are legally load-bearing:

* `shared` -- the features common to every paradigm;
* `shared_in_each` -- they really are common;
* `irredundant` -- and each paradigm has something the shared set lacks.

The third is what the Mishnah spends its middle section establishing ("the
distinctive feature of the ox is not like that of the crop-destroying beast,
nor is either of these, which are alive, like fire, which is not alive...").
Its purpose is to show that no paradigm is dispensable.  Its consequence,
proved below, is that the generalisation does not follow from the paradigms. -/
structure CommonDenominator (ps : List Precedent) where
  shared          : List Factor
  shared_nonempty : shared ≠ []
  shared_in_each  : ∀ h ∈ ps, ∀ f ∈ shared, f ∈ h.reason
  irredundant     : ∀ h ∈ ps, ∃ f ∈ h.reason, f ∉ shared

/-- **The common denominator underdetermines the rule.**

Let `ps` be paradigm cases with a common denominator in the above sense.  Then
the situation consisting of exactly the shared features is *not* forced for any
side by the paradigms.  Generalising from them is an ampliative step.

The proof is immediate once `irredundant` is in hand, which is the point: the
Mishnah's own careful demonstration that each paradigm is distinctive is
exactly what blocks the paradigms from entailing the general rule.  A tradition
that argued less carefully would have a weaker case for the four categories and
a stronger claim to have deduced the rule; this one has the better argument and
the ampliative conclusion. -/
theorem common_denominator_underdetermines
    {ps : List Precedent} (cd : CommonDenominator ps) (side : Side) :
    ¬ Forces ⟨"paradigms", ps⟩ ⟨cd.shared⟩ side := by
  rintro ⟨h, hm, _, hstrong⟩
  obtain ⟨f, hf, hnf⟩ := cd.irredundant h hm
  exact hnf (hstrong.reason_present f hf)

/-- The generalisation the Mishnah actually adopts, stated as what it is: a new
holding, not a consequence of the old ones.  Adding it does force the shared
situation, which is why the move is worth making. -/
def generalise (ps : List Precedent) (cd : CommonDenominator ps)
    (side : Side) (remedy : Remedy) (cite : String) : Precedent :=
  { cite := cite
  , situation := ⟨cd.shared⟩
  , winner := side
  , remedy := remedy
  , reason := cd.shared.filter (fun f => decide (f.side = side)) }

theorem generalise_wellFormed (ps : List Precedent) (cd : CommonDenominator ps)
    (side : Side) (remedy : Remedy) (cite : String)
    (hne : cd.shared.filter (fun f => decide (f.side = side)) ≠ []) :
    (generalise ps cd side remedy cite).WellFormed := by
  refine ⟨hne, ?_⟩
  intro f hf
  obtain ⟨hm, hp⟩ := List.mem_filter.mp hf
  exact ⟨hm, of_decide_eq_true hp⟩

/-- Having generalised, the shared situation *is* settled -- by the new holding,
not by the paradigms. -/
theorem generalise_forces (ps : List Precedent) (cd : CommonDenominator ps)
    (side : Side) (remedy : Remedy) (cite : String)
    (hne : cd.shared.filter (fun f => decide (f.side = side)) ≠ []) :
    Forces (Corpus.add ⟨"paradigms", ps⟩ (generalise ps cd side remedy cite))
      ⟨cd.shared⟩ side := by
  refine ⟨generalise ps cd side remedy cite, List.mem_cons_self _ _, rfl, ?_⟩
  exact AtLeastAsStrong.self _ (generalise_wellFormed ps cd side remedy cite hne)

-- ---------------------------------------------------------------------------
-- Distinguishing as the dual of extension
-- ---------------------------------------------------------------------------

/-- The factors that block a precedent from applying: the parts of its ratio
that are missing, plus the counter-reasons it never faced.  This is what an
autoformalisation system should emit when it declines to extend a rule, and
what a judgment states when it distinguishes. -/
def grounds_of_distinction (s : Situation) (h : Holding) : List Factor × List Factor :=
  ( h.reason.filter (fun f => decide (f ∉ s.factors))
  , (s.forSide h.winner.other).filter
      (fun f => decide (f ∉ h.situation.forSide h.winner.other)) )

theorem distinction_nonempty_of_not_strong {s : Situation} {h : Holding}
    (hn : ¬ AtLeastAsStrong s h) :
    (grounds_of_distinction s h).1 ≠ [] ∨ (grounds_of_distinction s h).2 ≠ [] := by
  rcases (distinguishable_iff s h).mp hn with ⟨f, hf, hnf⟩ | ⟨f, hf, hnf⟩
  · left
    intro hemp
    have : f ∈ (grounds_of_distinction s h).1 :=
      List.mem_filter.mpr ⟨hf, decide_eq_true hnf⟩
    rw [hemp] at this
    exact absurd this (List.not_mem_nil f)
  · right
    intro hemp
    have : f ∈ (grounds_of_distinction s h).2 :=
      List.mem_filter.mpr ⟨hf, decide_eq_true hnf⟩
    rw [hemp] at this
    exact absurd this (List.not_mem_nil f)

end Nomos
