/-
# Parties, things, acts and quantities

The ontology is deliberately thin.  The corpus this library is meant to read
spans societies that disagree about almost everything an ontology could commit
to -- who counts as a person, what can be owned, whether an animal can be a
defendant.  Building any of that in would prejudge the comparative questions we
want to ask.  So `Party` is an opaque name, `Res` is an opaque name with a
kind, and the interesting structure lives entirely in the normative layer.

One substantive choice: we do *not* assume parties are persons.  Roman noxal
liability treats the animal as the thing surrendered, the Twelve Tables and
Exodus 21:28 both direct proceedings against the ox itself, and several ancient
orders make a corporation-like household the bearer.  `Party` therefore ranges
over whatever a legal order is willing to put on either side of an incidence.
-/

namespace Nomos

/-- A participant in a legal relation: whoever the order is willing to place on
either side of a liability.  Not necessarily a natural person. -/
structure Party where
  name : String
  deriving DecidableEq, Repr, Inhabited

instance : ToString Party := ⟨Party.name⟩

/-- The broad kind of a thing, used only where a rule turns on it (e.g. rules
that distinguish livestock from inert hazards, or land from movables). -/
inductive ResKind where
  | land
  | crop
  | livestock
  | chattel
  | structure
  | money
  | body            -- the person's own body, where the order treats it as res
  | intangible
  deriving DecidableEq, Repr, Inhabited

/-- A thing that a legal relation is about. -/
structure Res where
  name : String
  kind : ResKind
  deriving DecidableEq, Repr, Inhabited

/-- An act-type.  Left opaque for the same reason as `Party`: the corpus
individuates acts very differently across traditions. -/
structure Act where
  name : String
  deriving DecidableEq, Repr, Inhabited

/-- A unit of account.  Named `Measure` rather than `Unit` to avoid shadowing
`_root_.Unit`, which would make every `IO Unit` in a client file ambiguous.  Ancient tariffs are stated in wildly incommensurable
units (gur of grain per gan of land, shekels of silver, minas, oxen, days of
labour), and any attempt to normalise them to a single numeraire would be an
interpretive act we prefer to keep out of the kernel. -/
structure Measure where
  name : String
  deriving DecidableEq, Repr, Inhabited

/-- A quantity: a magnitude in some unit.  We use `Nat` deliberately.  Every
tariff in the corpus is a non-negative rational with a small denominator, and
`Nat` numerator with an explicit unit keeps everything decidable. -/
structure Quantity where
  amount : Nat
  unit : Measure
  deriving DecidableEq, Repr, Inhabited

namespace Quantity

def shekels (n : Nat) : Quantity := ⟨n, ⟨"shekel"⟩⟩
def minas   (n : Nat) : Quantity := ⟨n, ⟨"mina"⟩⟩
def gur     (n : Nat) : Quantity := ⟨n, ⟨"gur"⟩⟩
def asses   (n : Nat) : Quantity := ⟨n, ⟨"as"⟩⟩
def sela    (n : Nat) : Quantity := ⟨n, ⟨"sela"⟩⟩
def zuz     (n : Nat) : Quantity := ⟨n, ⟨"zuz"⟩⟩

/-- Comparability is *partial*: quantities in different units are not ordered.
This is not a limitation to be engineered away.  The incommensurability of
remedies across legal orders is one of the things the project is trying to
measure, and silently coercing gur of barley into shekels of silver would
destroy the evidence. -/
def comparable (a b : Quantity) : Prop := a.unit = b.unit

instance (a b : Quantity) : Decidable (comparable a b) :=
  inferInstanceAs (Decidable (a.unit = b.unit))

/-- `a ≤ b` only when the units agree. -/
def le (a b : Quantity) : Prop := a.unit = b.unit ∧ a.amount ≤ b.amount

instance (a b : Quantity) : Decidable (le a b) := by
  unfold le; infer_instance

theorem le_refl (a : Quantity) : le a a := ⟨rfl, Nat.le_refl _⟩

theorem le_trans {a b c : Quantity} (h₁ : le a b) (h₂ : le b c) : le a c :=
  ⟨h₁.1.trans h₂.1, Nat.le_trans h₁.2 h₂.2⟩

theorem le_antisymm {a b : Quantity} (h₁ : le a b) (h₂ : le b a) : a = b := by
  cases a with | mk n u =>
  cases b with | mk m v =>
  have hu : u = v := h₁.1
  subst hu
  have hn : n = m := Nat.le_antisymm h₁.2 h₂.2
  subst hn
  rfl

end Quantity

end Nomos
