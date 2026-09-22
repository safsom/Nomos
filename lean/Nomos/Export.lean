/-
# Exporting the formalised corpus as data

The Lean library is the source of truth for the seed formalisations.  Rather
than parse Lean from Python -- which would be fragile and would let the two
drift -- we make the library emit its own contents, and the Python side reads
what Lean printed.

`Remedy.toSource` is the piece that earns its keep beyond export: it round-trips
a remedy back to valid Lean source, which is what the autoformalisation
pipeline needs in order to splice a generated remedy into a candidate
declaration and hand it to the compiler.
-/

import Nomos

namespace Nomos.Export

/-- JSON string escaping, enough for the identifiers and citations we emit. -/
def esc (s : String) : String :=
  s.foldl (init := "") fun acc c =>
    acc ++ (match c with
      | '"'  => "\\\""
      | '\\' => "\\\\"
      | '\n' => "\\n"
      | '\t' => "\\t"
      | '\r' => "\\r"
      | c    => if c.toNat < 0x20 then "" else String.singleton c)

def quote (s : String) : String := "\"" ++ esc s ++ "\""

def arr (xs : List String) : String := "[" ++ String.intercalate "," xs ++ "]"

def obj (kvs : List (String × String)) : String :=
  "{" ++ String.intercalate "," (kvs.map fun (k, v) => quote k ++ ":" ++ v) ++ "}"

/-- The Lean constructor name of a factor, so exported data can be spliced
straight back into Lean source. -/
def factorIdent : Factor → String
  | .harmOccurred => "harmOccurred"
  | .respondentsInstrument => "respondentsInstrument"
  | .respondentActedDirectly => "respondentActedDirectly"
  | .knownVice => "knownVice"
  | .warned => "warned"
  | .noPrecaution => "noPrecaution"
  | .withoutLeave => "withoutLeave"
  | .respondentBenefited => "respondentBenefited"
  | .harmToPerson => "harmToPerson"
  | .professedSkill => "professedSkill"
  | .deviationFromTerms => "deviationFromTerms"
  | .inPublicOrClaimantsGround => "inPublicOrClaimantsGround"
  | .wrongfulTaking => "wrongfulTaking"
  | .intentToHarm => "intentToHarm"
  | .claimantSuperiorInStatus => "claimantSuperiorInStatus"
  | .respondentHeldOffice => "respondentHeldOffice"
  | .respondentSuperiorInStatus => "respondentSuperiorInStatus"
  | .claimantConsented => "claimantConsented"
  | .properPrecaution => "properPrecaution"
  | .thirdPartyIntervened => "thirdPartyIntervened"
  | .claimantAtFault => "claimantAtFault"
  | .irresistibleForce => "irresistibleForce"
  | .gratuitousService => "gratuitousService"
  | .behavedAnomalously => "behavedAnomalously"
  | .onRespondentsGround => "onRespondentsGround"
  | .noticeGiven => "noticeGiven"
  | .customaryPractice => "customaryPractice"
  | .defensive => "defensive"

def sideIdent : Side → String
  | .claimant => "claimant"
  | .respondent => "respondent"

def resSource (r : Res) : String :=
  "⟨" ++ quote r.name ++ ", ResKind." ++
    (match r.kind with
     | .land => "land" | .crop => "crop" | .livestock => "livestock"
     | .chattel => "chattel" | .structure => "structure" | .money => "money"
     | .body => "body" | .intangible => "intangible") ++ "⟩"

def qtySource (q : Quantity) : String :=
  "⟨" ++ toString q.amount ++ ", ⟨" ++ quote q.unit.name ++ "⟩⟩"

/-- Emit a remedy as valid Lean source. -/
partial def remedySource : Remedy → String
  | .exempt => "Remedy.exempt"
  | .restore r => "(Remedy.restore " ++ resSource r ++ ")"
  | .compensate l => "(Remedy.compensate ⟨" ++ quote l.descr ++ "⟩)"
  | .multiple k l => "(Remedy.multiple " ++ toString k ++ " ⟨" ++ quote l.descr ++ "⟩)"
  | .tariff q => "(Remedy.tariff " ++ qtySource q ++ ")"
  | .inKind s => "(Remedy.inKind " ++ quote s ++ ")"
  | .surrender r => "(Remedy.surrender " ++ resSource r ++ ")"
  | .orElse a b => "(Remedy.orElse " ++ remedySource a ++ " " ++ remedySource b ++ ")"
  | .both a b => "(Remedy.both " ++ remedySource a ++ " " ++ remedySource b ++ ")"
  | .corporal s k => "(Remedy.corporal " ++ toString s ++ " " ++ quote k ++ ")"
  | .capital => "Remedy.capital"

def holdingJson (tradition : String) (h : Holding) : String :=
  obj [ ("cite", quote h.cite)
      , ("tradition", quote tradition)
      , ("situation", arr (h.situation.factors.map (quote ∘ factorIdent)))
      , ("winner", quote (sideIdent h.winner))
      , ("remedy", quote (remedySource h.remedy))
      , ("reason", arr (h.reason.map (quote ∘ factorIdent)))
      , ("well_formed", if h.WellFormed then "true" else "false") ]

def dumpCorpus (tradition : String) (Γ : Corpus) : IO Unit :=
  for h in Γ.cases do
    IO.println (holdingJson tradition h)

def factorJson (f : Factor) : String :=
  obj [ ("name", quote (factorIdent f))
      , ("tag", quote f.tag)
      , ("side", quote (sideIdent f.side)) ]

end Nomos.Export

open Nomos Nomos.Export Nomos.Corpus in
/-- `lake exe export-corpus` writes the seed corpus as JSONL on stdout, and
`--factors` writes the factor vocabulary instead. -/
def main (args : List String) : IO Unit := do
  if args.contains "--factors" then
    for f in Factor.all do IO.println (factorJson f)
  else
    dumpCorpus "covenant" Covenant.corpus
    dumpCorpus "rabbinic" Rabbinic.corpus
    dumpCorpus "roman" Roman.corpus
    dumpCorpus "mesopotamian" Mesopotamia.corpus
    dumpCorpus "chinese" Sinica.tangCode
    dumpCorpus "english" Anglia.corpus
