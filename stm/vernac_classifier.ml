(************************************************************************)
(*         *   The Coq Proof Assistant / The Coq Development Team       *)
(*  v      *   INRIA, CNRS and contributors - Copyright 1999-2018       *)
(* <O___,, *       (see CREDITS file for the list of authors)           *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

open CErrors
open Util
open Pp
open CAst
open Vernacextend
open Vernacexpr

let string_of_parallel = function
  | `Yes (solve,abs) ->
       "par" ^ if solve then "solve" else "" ^ if abs then "abs" else ""
  | `No -> ""

let string_of_vernac_type = function
  | VtUnknown -> "Unknown"
  | VtStartProof _ -> "StartProof"
  | VtSideff _ -> "Sideff"
  | VtQed (VtKeep VtKeepAxiom) -> "Qed(admitted)"
  | VtQed (VtKeep (VtKeepOpaque | VtKeepDefined)) -> "Qed(keep)"
  | VtQed VtDrop -> "Qed(drop)"
  | VtProofStep { parallel; proof_block_detection } ->
      "ProofStep " ^ string_of_parallel parallel ^
        Option.default "" proof_block_detection
  | VtQuery -> "Query"
  | VtMeta -> "Meta "
  | VtProofMode _ -> "Proof Mode"

let string_of_vernac_when = function
  | VtLater -> "Later"
  | VtNow -> "Now"

let string_of_vernac_classification (t,w) =
  string_of_vernac_type t ^ " " ^ string_of_vernac_when w

let vtkeep_of_opaque = let open Proof_global in function
  | Opaque -> VtKeepOpaque
  | Transparent -> VtKeepDefined

let idents_of_name : Names.Name.t -> Names.Id.t list =
  function
  | Names.Anonymous -> []
  | Names.Name n -> [n]

let stm_allow_nested_proofs_option_name = ["Nested";"Proofs";"Allowed"]

let options_affecting_stm_scheduling =
  [ Attributes.universe_polymorphism_option_name;
    stm_allow_nested_proofs_option_name;
    Vernacentries.proof_mode_opt_name;
    Attributes.program_mode_option_name;
    Proof_using.proof_using_opt_name;
  ]

let classify_vernac e =
  let static_classifier ~poly e = match e with
    (* Univ poly compatibility: we run it now, so that we can just
     * look at Flags in stm.ml.  Would be nicer to have the stm
     * look at the entire dag to detect this option. *)
    | VernacSetOption (_, l,_)
      when CList.exists (CList.equal String.equal l)
        options_affecting_stm_scheduling ->
       VtSideff [], VtNow
    (* Qed *)
    | VernacAbort _ -> VtQed VtDrop, VtLater
    | VernacEndProof Admitted -> VtQed (VtKeep VtKeepAxiom), VtLater
    | VernacEndProof (Proved (opaque,_)) -> VtQed (VtKeep (vtkeep_of_opaque opaque)), VtLater
    | VernacExactProof _ -> VtQed (VtKeep VtKeepOpaque), VtLater
    (* Query *)
    | VernacShow _ | VernacPrint _ | VernacSearch _ | VernacLocate _
    | VernacCheckMayEval _ -> VtQuery, VtLater
    (* ProofStep *)
    | VernacProof _ 
    | VernacFocus _ | VernacUnfocus
    | VernacSubproof _
    | VernacCheckGuard
    | VernacUnfocused
    | VernacSolveExistential _ ->
        VtProofStep { parallel = `No; proof_block_detection = None }, VtLater
    | VernacBullet _ ->
        VtProofStep { parallel = `No; proof_block_detection = Some "bullet" },
        VtLater
    | VernacEndSubproof -> 
        VtProofStep { parallel = `No;
                      proof_block_detection = Some "curly" },
        VtLater
    (* StartProof *)
    | VernacDefinition ((Decl_kinds.DoDischarge,_),({v=i},_),ProveBody _) ->
      VtStartProof(Doesn'tGuaranteeOpacity, idents_of_name i), VtLater

    | VernacDefinition (_,({v=i},_),ProveBody _) ->
       let guarantee = if poly then Doesn'tGuaranteeOpacity else GuaranteesOpacity in
        VtStartProof(guarantee, idents_of_name i), VtLater
    | VernacStartTheoremProof (_,l) ->
        let ids = List.map (fun (({v=i}, _), _) -> i) l in
       let guarantee = if poly then Doesn'tGuaranteeOpacity else GuaranteesOpacity in
        VtStartProof (guarantee,ids), VtLater
    | VernacFixpoint (discharge,l) ->
       let guarantee =
         if discharge = Decl_kinds.DoDischarge || poly then Doesn'tGuaranteeOpacity
         else GuaranteesOpacity
       in
        let ids, open_proof =
          List.fold_left (fun (l,b) ((({v=id},_),_,_,_,p),_) ->
            id::l, b || p = None) ([],false) l in
        if open_proof
        then VtStartProof (guarantee,ids), VtLater
        else VtSideff ids, VtLater
    | VernacCoFixpoint (discharge,l) ->
       let guarantee =
         if discharge = Decl_kinds.DoDischarge || poly then Doesn'tGuaranteeOpacity
         else GuaranteesOpacity
       in
        let ids, open_proof =
          List.fold_left (fun (l,b) ((({v=id},_),_,_,p),_) ->
            id::l, b || p = None) ([],false) l in
        if open_proof
        then VtStartProof (guarantee,ids), VtLater
        else VtSideff ids, VtLater
    (* Sideff: apply to all open branches. usually run on master only *)
    | VernacAssumption (_,_,l) ->
        let ids = List.flatten (List.map (fun (_,(l,_)) -> List.map (fun (id, _) -> id.v) l) l) in
        VtSideff ids, VtLater
    | VernacPrimitive (id,_,_) ->
        VtSideff [id.CAst.v], VtLater
    | VernacDefinition (_,({v=id},_),DefineBody _) -> VtSideff (idents_of_name id), VtLater
    | VernacInductive (_, _,_,l) ->
        let ids = List.map (fun (((_,({v=id},_)),_,_,_,cl),_) -> id :: match cl with
        | Constructors l -> List.map (fun (_,({v=id},_)) -> id) l
        | RecordDecl (oid,l) -> (match oid with Some {v=x} -> [x] | _ -> []) @
           CList.map_filter (function
            | AssumExpr({v=Names.Name n},_), _ -> Some n
            | _ -> None) l) l in
        VtSideff (List.flatten ids), VtLater
    | VernacScheme l ->
        let ids = List.map (fun {v}->v) (CList.map_filter (fun (x,_) -> x) l) in
        VtSideff ids, VtLater
    | VernacCombinedScheme ({v=id},_) -> VtSideff [id], VtLater
    | VernacBeginSection {v=id} -> VtSideff [id], VtLater
    | VernacUniverse _ | VernacConstraint _
    | VernacCanonical _ | VernacCoercion _ | VernacIdentityCoercion _
    | VernacAddLoadPath _ | VernacRemoveLoadPath _ | VernacAddMLPath _
    | VernacChdir _ 
    | VernacCreateHintDb _ | VernacRemoveHints _ | VernacHints _
    | VernacArguments _
    | VernacReserve _
    | VernacGeneralizable _
    | VernacSetOpacity _ | VernacSetStrategy _
    | VernacSetOption _
    | VernacAddOption _ | VernacRemoveOption _
    | VernacMemOption _ | VernacPrintOption _
    | VernacGlobalCheck _
    | VernacDeclareReduction _
    | VernacExistingClass _ | VernacExistingInstance _
    | VernacRegister _
    | VernacNameSectionHypSet _
    | VernacComments _
    | VernacDeclareInstance _ -> VtSideff [], VtLater
    (* Who knows *)
    | VernacLoad _ -> VtSideff [], VtNow
    (* (Local) Notations have to disappear *)
    | VernacEndSegment _ -> VtSideff [], VtNow
    (* Modules with parameters have to be executed: can import notations *)
    | VernacDeclareModule (exp,{v=id},bl,_)
    | VernacDefineModule (exp,{v=id},bl,_,_) ->
        VtSideff [id], if bl = [] && exp = None then VtLater else VtNow
    | VernacDeclareModuleType ({v=id},bl,_,_) ->
        VtSideff [id], if bl = [] then VtLater else VtNow
    (* These commands alter the parser *)
    | VernacDeclareCustomEntry _
    | VernacOpenCloseScope _ | VernacDeclareScope _
    | VernacDelimiters _ | VernacBindScope _
    | VernacInfix _ | VernacNotation _ | VernacNotationAddFormat _
    | VernacSyntaxExtension _
    | VernacSyntacticDefinition _
    | VernacRequire _ | VernacImport _ | VernacInclude _
    | VernacDeclareMLModule _
    | VernacContext _ (* TASSI: unsure *) -> VtSideff [], VtNow
    | VernacProofMode pm -> VtProofMode pm, VtNow
    (* These are ambiguous *)
    | VernacInstance _ -> VtUnknown, VtNow
    (* Stm will install a new classifier to handle these *)
    | VernacBack _ | VernacAbortAll
    | VernacUndoTo _ | VernacUndo _
    | VernacResetName _ | VernacResetInitial
    | VernacBackTo _ | VernacRestart -> VtMeta, VtNow
    (* What are these? *)
    | VernacRestoreState _
    | VernacWriteState _ -> VtSideff [], VtNow
    (* Plugins should classify their commands *)
    | VernacExtend (s,l) ->
        try Vernacextend.get_vernac_classifier s l
        with Not_found -> anomaly(str"No classifier for"++spc()++str (fst s)++str".")
  in
  let rec static_control_classifier v = v |> CAst.with_val (function
    | VernacExpr (f, e) ->
      let poly = Attributes.(parse_drop_extra polymorphic_nowarn f) in
      static_classifier ~poly e
    | VernacTimeout (_,e) -> static_control_classifier e
    | VernacTime (_,e) | VernacRedirect (_, e) ->
       static_control_classifier e
    | VernacFail e -> (* Fail Qed or Fail Lemma must not join/fork the DAG *)
        (match static_control_classifier e with
        | ( VtQuery | VtProofStep _ | VtSideff _
          | VtMeta), _ as x -> x
        | VtQed _, _ ->
            VtProofStep { parallel = `No; proof_block_detection = None },
            VtLater
        | (VtStartProof _ | VtUnknown | VtProofMode _), _ -> VtQuery, VtLater))
  in
  static_control_classifier e
