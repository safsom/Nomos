/-
# Liability

The kernel takes liability, not right, as primitive.  This follows the shape of
the sources rather than the shape of modern legal theory.  Hammurabi does not
say that the owner of a field has a right that his crop not be eaten; it says
that a shepherd who grazes his flock there without leave pays twenty gur of
grain for every ten gan (LH §57).  Exodus does not confer a right to bodily
security; it says that if an ox gores, the ox is stoned and, in the forewarned
case, the owner too (Ex 21:28-29).  The Mishnah's opening move in Bava Kamma is
to enumerate four *categories of damage*, not four rights.  Rights, in all
three, are reconstructed from liability rules, and `Nomos.Core.Right` performs
that reconstruction rather than assuming it.

The one substantive commitment made here is worth stating plainly:

> Every harm is allocated.  Exemption is not the absence of an allocation; it
> is an allocation to the victim.

That is `exempt_allocates_to_claimant` below.  It is the formal content of the
observation that a legal order which declines to shift a loss has thereby
decided who bears it, and it is why `Remedy.exempt` is a remedy rather than the
absence of one.
-/

import Nomos.Core.Party
import Nomos.Core.Remedy
import Nomos.Core.Factor

namespace Nomos

/-- A single normative relation: `bearer` is answerable to `claimant` in
`remedy`, on the authority of `ground`.

`ground` carries a citation (e.g. "LH §57", "D.9.2.27.5", "m.BK 6:1") rather
than a reason in the logical sense.  This is deliberate: the whole project is
about recovering the reasons, so baking a reason structure in at the kernel
would beg the question. -/
structure Incidence where
  bearer   : Party
  claimant : Party
  remedy   : Remedy
  ground   : String
  deriving DecidableEq, Repr, Inhabited

namespace Incidence

/-- An incidence that imposes nothing.  Note this is *not* the same as the
absence of an incidence: see `exempt_allocates_to_claimant`. -/
def exemption (bearer claimant : Party) (ground : String) : Incidence :=
  ⟨bearer, claimant, Remedy.exempt, ground⟩

def imposesNothing (i : Incidence) : Bool := i.remedy.isNull

/-- Who actually ends up bearing the loss.  If the remedy is null the loss
stays where it fell, on the claimant. -/
def restsOn (i : Incidence) : Party :=
  if i.imposesNothing then i.claimant else i.bearer

theorem exempt_allocates_to_claimant (b c : Party) (g : String) :
    (exemption b c g).restsOn = c := by
  simp [exemption, restsOn, imposesNothing, Remedy.isNull]

theorem substantive_allocates_to_bearer {i : Incidence}
    (h : i.imposesNothing = false) : i.restsOn = i.bearer := by
  simp [restsOn, h]

/-- Every incidence allocates the loss to exactly one party.  Trivial as a
proposition; the content is in the definition of `restsOn`, which makes the
allocation total by construction. -/
theorem allocation_total (i : Incidence) :
    i.restsOn = i.claimant ∨ i.restsOn = i.bearer := by
  by_cases h : i.imposesNothing
  · left; simp [restsOn, h]
  · right; simp [restsOn, h]

end Incidence

/-- The outcome a tribunal reaches on a fact situation.

`reason` is the subset of the winner's factors the tribunal actually relied
on -- the *ratio decidendi*, in the narrow sense Horty & Bench-Capon give it.
Recording it separately from `situation` is what distinguishes a precedent
(which constrains) from a mere decision (which does not).  Where a source does
not tell us what the reason was, the convention in `Nomos/Corpus/` is to take
the full set of the winner's factors, which is the weakest reading and so the
one that claims least. -/
structure Holding where
  cite      : String
  situation : Situation
  winner    : Side
  remedy    : Remedy
  reason    : List Factor
  deriving DecidableEq, Repr, Inhabited

namespace Holding

/-- The factors that told against the winner. -/
def opposing (h : Holding) : List Factor := h.situation.forSide h.winner.other

/-- The factors that told for the winner. -/
def supporting (h : Holding) : List Factor := h.situation.forSide h.winner

/-- A holding is *well-formed* when it rests on something, and when what it
rests on consists of factors actually present and actually favouring the
winner.

The first conjunct is not decoration.  A holding with an empty ratio binds
*every* fact situation that raises no counter-reason, because `AtLeastAsStrong`
asks only that the ratio be present and the empty set always is.  One such
holding in a case base would swallow the corpus.  It is also the degenerate
output a generation pipeline produces when it fails silently -- a model that
returns an empty object yields a holding that compiles, is vacuously
well-formed on the weaker definition, and is worthless.  Requiring
`reason ≠ []` turns that failure into a compile error. -/
def WellFormed (h : Holding) : Prop :=
  h.reason ≠ [] ∧ ∀ f ∈ h.reason, f ∈ h.situation.factors ∧ f.side = h.winner

instance (h : Holding) : Decidable (WellFormed h) :=
  inferInstanceAs (Decidable (_ ∧ _))

theorem reason_subset_supporting {h : Holding} (hw : WellFormed h) :
    ∀ f ∈ h.reason, f ∈ h.supporting := by
  intro f hf
  obtain ⟨hm, hs⟩ := hw.2 f hf
  exact Situation.mem_forSide_of hm hs

/-- The incidence a holding produces between two named parties. -/
def incidence (h : Holding) (claimant respondent : Party) : Incidence :=
  match h.winner with
  | Side.claimant => ⟨respondent, claimant, h.remedy, h.cite⟩
  | Side.respondent => ⟨respondent, claimant, Remedy.exempt, h.cite⟩

/-- A holding for the respondent leaves the loss on the claimant, whatever
remedy was nominally in issue. -/
theorem respondent_win_leaves_loss {h : Holding} (hw : h.winner = Side.respondent)
    (c r : Party) : (h.incidence c r).restsOn = c := by
  simp [incidence, hw, Incidence.restsOn, Incidence.imposesNothing, Remedy.isNull]

end Holding

end Nomos
