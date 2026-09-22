/-
# Factors

A *factor*, in the sense of HYPO and CATO and of Horty & Bench-Capon's formal
reconstruction, is a stereotypical pattern of fact that counts as a reason for
one side.  Factors are one-sided by definition: a fact that can cut either way
is modelled as two factors, not one factor with a sign.

The vocabulary below was not designed a priori.  It was read off the seed
provisions in `Nomos/Corpus/`, which is why it looks lopsided in places --
there are four factors about animal husbandry and none about maritime salvage,
because the seed set is built around the scenarios that recur most widely.
Extending the vocabulary is expected and cheap; `Nomos.Reasoning.Precedent`
proves that the constraint relation behaves monotonically as factors are added
to a fact situation, so a larger vocabulary never invalidates earlier results.

A caution that matters for anyone using this to compare legal orders: a factor
is a description *we* impose. When we say that Exodus 21:29 and D.9.1.1.4 both
exhibit `knownVice`, we are asserting that "the ox was wont to gore in time
past, and it hath been testified to his owner" and "bos cornu petere solitus"
pick out the same legally operative feature.  That is a real claim about the
two systems and it can be wrong.  Every such assertion in `Nomos/Corpus/`
carries a citation so it can be checked, and the ones we are least sure of are
marked in the accompanying seed data with `confidence: medium` or `low`.
-/

namespace Nomos

/-- Which party a factor is a reason for.

`claimant` is whoever seeks redress -- plaintiff, *actor*, the injured party,
the *nizak*.  `respondent` is whoever resists -- defendant, *reus*, *mazik*.
We avoid "plaintiff"/"defendant" because several traditions in the corpus have
no procedural role answering to them. -/
inductive Side where
  | claimant
  | respondent
  deriving DecidableEq, Repr, Inhabited

namespace Side
def other : Side → Side
  | claimant => respondent
  | respondent => claimant

@[simp] theorem other_other (s : Side) : s.other.other = s := by cases s <;> rfl

@[simp] theorem other_ne (s : Side) : s.other ≠ s := by cases s <;> simp [other]
end Side

/-- The factor vocabulary. -/
inductive Factor where
  -- ── reasons for the claimant ──────────────────────────────────────────
  /-- The claimant suffered an impairment the order recognises. -/
  | harmOccurred
  /-- The instrument of harm belonged to, or was in the charge of, the
      respondent.  LH §251, Ex 21:29, m.BK 1:1 ("it is your duty to guard
      them"), D.9.1.1.2. -/
  | respondentsInstrument
  /-- The respondent brought about the harm by his own act, not through a
      thing.  The Aquilian *corpore corpori*. -/
  | respondentActedDirectly
  /-- The dangerous propensity was known: "wont to gore in time past" (Ex
      21:29), *bos cornu petere solitus* (D.9.1.1.4), the rabbinic *mu'ad*. -/
  | knownVice
  /-- The respondent had been specifically warned. -/
  | warned
  /-- No precaution at all was taken. -/
  | noPrecaution
  /-- Entry onto the claimant's land or use of his thing without leave.
      LH §57, Ex 22:4. -/
  | withoutLeave
  /-- The respondent stood to gain: the paid bailee, the hirer, the merchant.
      Drives the Roman *utilitas* doctrine and m.BM 7:8's four bailees. -/
  | respondentBenefited
  /-- The harm was to a person rather than to property. -/
  | harmToPerson
  /-- The respondent held himself out as having a skill: surgeon, builder,
      pilot.  LH §§215-233, D.9.2.7.8, D.19.2.9.5. -/
  | professedSkill
  /-- The respondent departed from the terms on which he held the thing. -/
  | deviationFromTerms
  /-- The harm happened in a public place or on the claimant's own ground,
      not on the respondent's.  The *reshut ha-rabbim* distinction. -/
  | inPublicOrClaimantsGround
  /-- The thing was taken or kept against the owner's will. -/
  | wrongfulTaking
  /-- The claimant stood above the respondent in a status the order
      recognises, so the wrong is aggravated.  Almost every order in the
      corpus grades liability this way and the gradings are startlingly
      parallel: XII Tab. 8.3 sets 300 asses for a free man's broken bone and
      150 for a slave's; Ex 21:32 prices a gored slave at thirty shekels where
      a free victim is not priced at all; LH §§251-252 halves the tariff for a
      slave; the Tang Code grades by 良賤 (free/base) and by mourning degree;
      Anglo-Saxon wergild tables do the same by rank. -/
  | claimantSuperiorInStatus
  /-- The respondent held office, and the harm arose in the exercise of it.
      Chinese law is saturated with this -- the 監臨主守 ("supervising and
      custodial officials") category runs through the Tang and Qing codes --
      and Roman law has its own version in the liability of magistrates and
      the *actio de effusis* against occupiers. -/
  | respondentHeldOffice
  /-- The harm was aimed at, not incidental.  The rabbinic *keren* (horn) is
      distinguished from *shen* (tooth) on exactly this ground: the goring
      animal takes no benefit and means the injury, where the grazing animal
      eats for its own good.  Roman law draws the same line between *dolus*
      and *culpa*, and between *iniuria* and *damnum*. -/
  | intentToHarm

  -- ── reasons for the respondent ────────────────────────────────────────
  /-- The claimant consented, or gave leave.  The paradigm liability-waiver,
      and the one on which `Nomos.Core.Right` builds. -/
  | claimantConsented
  /-- Adequate precaution was taken: "shut it in properly" (m.BK 6:1). -/
  | properPrecaution
  /-- A third party's deliberate act intervened: the bandits of m.BK 6:1. -/
  | thirdPartyIntervened
  /-- The claimant's own conduct contributed.  D.9.2.11pr (the ball-players),
      D.50.17.203 (*quod quis ex culpa sua damnum sentit*). -/
  | claimantAtFault
  /-- Irresistible force: *vis maior*, *ones*, an act of God. -/
  | irresistibleForce
  /-- The respondent acted gratuitously, for the claimant's benefit only. -/
  | gratuitousService
  /-- The animal or thing behaved out of character: the rabbinic *tam*, the
      *quadrupes* that harmed *contra naturam*. -/
  | behavedAnomalously
  /-- The harm occurred on the respondent's own ground. -/
  | onRespondentsGround
  /-- Notice was given and the claimant could have avoided the harm. -/
  | noticeGiven
  /-- The respondent followed established custom or trade practice. -/
  | customaryPractice
  /-- The respondent was acting in defence of himself or his property. -/
  | defensive
  /-- The respondent stood above the claimant in a recognised status, so the
      wrong is mitigated or excused.  The mirror of `claimantSuperiorInStatus`,
      and modelled as a separate factor because a factor favours exactly one
      side by construction. -/
  | respondentSuperiorInStatus
  deriving DecidableEq, Repr, Inhabited

namespace Factor

/-- Which side each factor favours. -/
def side : Factor → Side
  | harmOccurred | respondentsInstrument | respondentActedDirectly
  | knownVice | warned | noPrecaution | withoutLeave | respondentBenefited
  | harmToPerson | professedSkill | deviationFromTerms
  | inPublicOrClaimantsGround | wrongfulTaking | intentToHarm
  | claimantSuperiorInStatus | respondentHeldOffice => Side.claimant
  | claimantConsented | properPrecaution | thirdPartyIntervened
  | claimantAtFault | irresistibleForce | gratuitousService
  | behavedAnomalously | onRespondentsGround | noticeGiven
  | customaryPractice | defensive | respondentSuperiorInStatus => Side.respondent

/-- A short human-readable tag, used when rendering explanations. -/
def tag : Factor → String
  | harmOccurred => "harm-occurred"
  | respondentsInstrument => "respondents-instrument"
  | respondentActedDirectly => "acted-directly"
  | knownVice => "known-vice"
  | warned => "warned"
  | noPrecaution => "no-precaution"
  | withoutLeave => "without-leave"
  | respondentBenefited => "respondent-benefited"
  | harmToPerson => "harm-to-person"
  | professedSkill => "professed-skill"
  | deviationFromTerms => "deviation-from-terms"
  | inPublicOrClaimantsGround => "public-or-claimants-ground"
  | wrongfulTaking => "wrongful-taking"
  | intentToHarm => "intent-to-harm"
  | claimantSuperiorInStatus => "claimant-superior-in-status"
  | respondentHeldOffice => "respondent-held-office"
  | respondentSuperiorInStatus => "respondent-superior-in-status"
  | claimantConsented => "claimant-consented"
  | properPrecaution => "proper-precaution"
  | thirdPartyIntervened => "third-party-intervened"
  | claimantAtFault => "claimant-at-fault"
  | irresistibleForce => "irresistible-force"
  | gratuitousService => "gratuitous-service"
  | behavedAnomalously => "behaved-anomalously"
  | onRespondentsGround => "on-respondents-ground"
  | noticeGiven => "notice-given"
  | customaryPractice => "customary-practice"
  | defensive => "defensive"

/-- Some factors are ordered intensifications of the same underlying feature:
`warned` is a stronger form of `knownVice`, and where the stronger is present
the weaker is too.  Recording this is what makes a fortiori steps available
*within* a fact situation rather than only between situations. -/
def strengthens : Factor → Factor → Prop
  | warned, knownVice => True
  | noPrecaution, withoutLeave => False
  | _, _ => False

instance (a b : Factor) : Decidable (strengthens a b) := by
  cases a <;> cases b <;> simp [strengthens] <;> infer_instance

/-- The complete vocabulary, used for exhaustiveness checks in the tooling. -/
def all : List Factor :=
  [ harmOccurred, respondentsInstrument, respondentActedDirectly, knownVice,
    warned, noPrecaution, withoutLeave, respondentBenefited, harmToPerson,
    professedSkill, deviationFromTerms, inPublicOrClaimantsGround,
    wrongfulTaking, intentToHarm, claimantSuperiorInStatus,
    respondentHeldOffice, claimantConsented, properPrecaution, thirdPartyIntervened,
    claimantAtFault, irresistibleForce, gratuitousService, behavedAnomalously,
    onRespondentsGround, noticeGiven, customaryPractice, defensive,
    respondentSuperiorInStatus ]

theorem mem_all (f : Factor) : f ∈ all := by
  cases f <;> simp [all]

end Factor

/-- A *fact situation*: the factors a tribunal finds present.

We use a `List` rather than a set type so that everything stays computable in
core Lean with no `Mathlib` dependency.  Order and duplication are treated as
irrelevant throughout; `Situation.equiv` is the intended equality. -/
structure Situation where
  factors : List Factor
  deriving DecidableEq, Repr, Inhabited

namespace Situation

def has (s : Situation) (f : Factor) : Bool := s.factors.contains f

/-- The factors in `s` favouring `side`. -/
def forSide (s : Situation) (side : Side) : List Factor :=
  s.factors.filter (fun f => decide (f.side = side))

def pro (s : Situation) : List Factor := s.forSide Side.claimant
def con (s : Situation) : List Factor := s.forSide Side.respondent

def equiv (s t : Situation) : Prop :=
  ∀ f : Factor, s.has f = t.has f

/-- Add factors, e.g. when a later court finds more than an earlier one did. -/
def with_ (s : Situation) (fs : List Factor) : Situation := ⟨fs ++ s.factors⟩

theorem mem_forSide {s : Situation} {side : Side} {f : Factor}
    (h : f ∈ s.forSide side) : f ∈ s.factors ∧ f.side = side := by
  unfold forSide at h
  obtain ⟨hm, hp⟩ := List.mem_filter.mp h
  exact ⟨hm, of_decide_eq_true hp⟩

theorem mem_forSide_of {s : Situation} {side : Side} {f : Factor}
    (hm : f ∈ s.factors) (hs : f.side = side) : f ∈ s.forSide side := by
  unfold forSide
  exact List.mem_filter.mpr ⟨hm, decide_eq_true hs⟩

end Situation

end Nomos
