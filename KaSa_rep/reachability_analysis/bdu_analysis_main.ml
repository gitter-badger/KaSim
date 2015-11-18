(**
  * bdu_analysis_main.ml
  * openkappa
  * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
  * 
  * Creation: 2015, the 28th of September
  * Last modification: 
  * 
  * Compute the relations between sites in the BDU data structures
  * 
  * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et   
  * en Automatique.  All rights reserved.  This file is distributed     
  * under the terms of the GNU Library General Public License *)

open Cckappa_sig
open Int_storage
open Fifo
open Bdu_build_common
open Bdu_analysis_type
open Print_bdu_analysis
open Bdu_side_effects
open Bdu_modification_sites
open Bdu_contact_map
open Bdu_update
open Bdu_working_list
open Bdu_build (*RENAME*)
open Bdu_structure (*RENAME*)
open Bdu_fixpoint_iteration

let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "BDU analysis") message exn (fun () -> default)  

let trace = false

(************************************************************************************)
(*static analysis*)

let scan_rule_static parameter error handler rule_id rule covering_classes
    store_result =
  (*------------------------------------------------------------------------------*)
  (*static information of covering classes: from sites -> covering_class id list*)
  let error, store_covering_classes_id =
    site_covering_classes
      parameter
      error
      covering_classes
  in
  (*------------------------------------------------------------------------------*)
  (*side effects*)
  let error, store_side_effects =
    collect_side_effects
      parameter
      error
      handler
      rule_id 
      rule.actions.half_break
      rule.actions.remove
      store_result.store_side_effects
  in 
  (*-------------------------------------------------------------------------------*)
  let error, store_modification_sites =
    collect_modification_sites
      parameter
      error
      rule_id
      rule.diff_direct
      store_result.store_modification_sites
  in
  (*-------------------------------------------------------------------------------*)
  (*test*)
  let error, store_test_sites =
    collect_test_sites
      parameter
      error
      rule_id
      rule.rule_lhs.views
      store_result.store_test_sites
  in
  (*-------------------------------------------------------------------------------*)
  (*test and modification*)
  let error, store_test_modification_sites =
    collect_test_modification_sites
      parameter
      error
      store_modification_sites
      store_test_sites
      store_result.store_test_modification_sites
  in
  (*-------------------------------------------------------------------------------*)
  error, 
  {
    store_covering_classes_id                  = store_covering_classes_id;
    store_side_effects                         = store_side_effects;
    store_modification_sites                   = store_modification_sites;
    store_test_sites                           = store_test_sites;
    store_test_modification_sites              = store_test_modification_sites;
  }

(************************************************************************************)
(*dynamic analysis*)

let scan_rule_dynamic parameter error handler rule_id rule 
    store_test_modification_sites
    store_covering_classes_id
    store_result =
  (*------------------------------------------------------------------------------*)
  (*contact map*)
  let error, store_contact_map =
    compute_contact_map
      parameter
      error
      handler
      rule
  in
  (*-------------------------------------------------------------------------------*)
  (*return a mapping of covering classes to a list of rules that has [modified and test]
    sites*)
  let error, store_covering_classes_modification_update =
    store_covering_classes_modification_update
      parameter
      error
      store_test_modification_sites
      store_covering_classes_id
  in
  (*------------------------------------------------------------------------------*)
  (*working list*)
  let error, store_wl_creation =
    collect_wl_creation
      parameter
      error
      rule_id
      rule
      store_result.store_wl_creation
  in
  (*-------------------------------------------------------------------------------*)
  error, 
  {
    store_contact_map                          = store_contact_map;
    store_covering_classes_modification_update = store_covering_classes_modification_update;
    store_wl_creation                          = store_wl_creation;
  }

(************************************************************************************)
(*rule bdu build*)

let scan_rule_bdu_build parameter error rule_id rule covering_classes store_result =
  let error, store_remanent_triple =
    collect_remanent_triple
      parameter
      error
      covering_classes
      store_result.store_remanent_triple
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_remanent_test =
    collect_test_restriction
      parameter
      error
      rule_id
      rule
      store_remanent_triple
      store_result.store_remanent_test
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_remanent_creation =
    collect_creation_restriction
      parameter
      error
      rule_id
      rule
      store_remanent_triple
      store_result.store_remanent_creation
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_remanent_modif =
    collect_modif_restriction
      parameter
      error
      rule_id
      rule
      store_remanent_triple
      store_result.store_remanent_modif
  in
  (*-------------------------------------------------------------------------------*)
  error, 
  {
    store_remanent_triple    = store_remanent_triple;
    store_remanent_test      = store_remanent_test;
    store_remanent_creation  = store_remanent_creation;
    store_remanent_modif     = store_remanent_modif;
  }

(************************************************************************************)
(*rule bdu build map*)

let scan_rule_bdu_build_map parameter error rule_id rule 
    store_remanent_test
    store_remanent_triple
    store_remanent_creation
    store_remanent_modif
    store_result =
  (*-------------------------------------------------------------------------------*)
  let error, store_remanent_test_map =
    collect_remanent_test_map
      parameter
      error
      store_remanent_test
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_remanent_creation_map =
    collect_remanent_creation_map
      parameter
      error
      store_remanent_creation
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_remanent_modif_map =
    collect_remanent_modif_map
      parameter
      error
      store_remanent_modif
  in
  (*-------------------------------------------------------------------------------*)
  (*let error, store_test_bdu = (*REMOVE*)
    collect_test_bdu
      parameter
      error
      store_remanent_test_map
  in*)
  (*-------------------------------------------------------------------------------*)
  (*let error, store_creation_bdu = (*REMOVE*)
    collect_creation_bdu
      parameter
      error
      store_remanent_creation_map
  in*)
  (*-------------------------------------------------------------------------------*)
  let error, store_creation_bdu_map =
    collect_creation_bdu_map
      parameter
      error
      store_remanent_creation_map
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_test_bdu_map =
    collect_test_bdu_map
      parameter
      error
      store_remanent_test_map
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_modif_list_map =
    collect_modif_list_map
      parameter
      error
      store_remanent_modif_map
  in
  (*-------------------------------------------------------------------------------*)
  error, 
  {
    store_remanent_test_map      = store_remanent_test_map;
    store_remanent_creation_map  = store_remanent_creation_map;
    store_remanent_modif_map     = store_remanent_modif_map;
    (*store_test_bdu               = store_test_bdu; (*REMOVE*)
    store_creation_bdu           = store_creation_bdu; (*REMOVE*)*)
    store_creation_bdu_map       = store_creation_bdu_map;
    store_test_bdu_map           = store_test_bdu_map;
    store_modif_list_map         = store_modif_list_map
  }

(************************************************************************************)
(*scan rule fixpoint*)

(*let scan_rule_fixpoint parameter error handler
    store_creation_bdu
    store_test_bdu
    store_result =
  let error, store_bdu_creation_array =
    collect_bdu_creation_array
      parameter
      error
      handler
      store_creation_bdu
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_bdu_test_array =
    collect_bdu_test_array
      parameter
      error
      handler
      store_test_bdu
  in
  (*-------------------------------------------------------------------------------*)
  error, 
  {
    store_bdu_creation_array      = store_bdu_creation_array;
    store_bdu_test_array          = store_bdu_test_array;
  }*)
  
(************************************************************************************)
(*rule*)

let scan_rule parameter error handler rule_id rule store_covering_classes
    compiled store_result =
  let covering_classes, covering_class_set = store_covering_classes in
  (*-------------------------------------------------------------------------------*)
  let error, store_bdu_analysis_static =
    scan_rule_static 
      parameter
      error 
      handler
      rule_id 
      rule 
      covering_classes
      store_result.store_bdu_analysis_static
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_bdu_analysis_dynamic =
    scan_rule_dynamic
      parameter
      error
      handler
      rule_id
      rule 
      store_bdu_analysis_static.store_test_modification_sites
      store_bdu_analysis_static.store_covering_classes_id
      store_result.store_bdu_analysis_dynamic
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_bdu_build =
    scan_rule_bdu_build
      parameter
      error
      rule_id
      rule
      covering_classes
      store_result.store_bdu_build
  in
  (*-------------------------------------------------------------------------------*)
  let error, store_bdu_build_map =
    scan_rule_bdu_build_map
      parameter
      error
      rule_id
      rule
      store_bdu_build.store_remanent_test
      store_bdu_build.store_remanent_triple
      store_bdu_build.store_remanent_creation
      store_bdu_build.store_remanent_modif
      store_result.store_bdu_build_map
  in
  (*-------------------------------------------------------------------------------*)
  (*let error, store_bdu_fixpoint =
    scan_rule_fixpoint
      parameter
      error
      handler
      store_bdu_build_map.store_creation_bdu
      store_bdu_build_map.store_test_bdu
      store_result.store_bdu_fixpoint
  in*)
  (*------------------------------------------------------------------------------*)
  (*store*)
  error,
  {
    store_bdu_analysis_static  = store_bdu_analysis_static;
    store_bdu_analysis_dynamic = store_bdu_analysis_dynamic;
    store_bdu_build            = store_bdu_build;
    store_bdu_build_map        = store_bdu_build_map;
    (*store_bdu_fixpoint         = store_bdu_fixpoint*)
  }
 
(************************************************************************************)
(*intitial state of static analysis*)

let init_bdu_analysis_static =
  let init_covering_classes_id     = Int2Map_CV.Map.empty in
  let init_half_break              = Int2Map_HalfBreak_effect.Map.empty  in
  let init_remove                  = Int2Map_Remove_effect.Map.empty  in
  let init_modification            = Int2Map_Modif.Map.empty in
  let init_test                    = Int2Map_Modif.Map.empty in
  let init_test_modification       = Int2Map_Modif.Map.empty in
  let init_bdu_analysis_static =
    {
      store_covering_classes_id     = init_covering_classes_id;
      store_side_effects            = (init_half_break, init_remove);
      store_modification_sites      = init_modification;
      store_test_sites              = init_test;
      store_test_modification_sites = init_test_modification;
    }
  in
  init_bdu_analysis_static
      
(************************************************************************************)
(*intitial state of dynamic analysis*)

let init_bdu_analysis_dynamic parameter error =
  let init_contact_map     = Int2Map_CM_state.Map.empty in
  let init_cv_modification = Int2Map_CV_Modif.Map.empty in
  let init_wl_creation     = IntWL.empty in
  let init_bdu_analysis_dynamic =
    {
      store_contact_map                          = init_contact_map;
      store_covering_classes_modification_update = init_cv_modification;
      store_wl_creation                          = init_wl_creation;
    }
  in
  error, init_bdu_analysis_dynamic

(************************************************************************************)
(*init of bdu build*)

let init_bdu_build parameter error =
  let error, init_remanent_triple    = AgentMap.create parameter error 0 in
  let error, init_remanent_test      = AgentMap.create parameter error 0 in
  let error, init_remanent_creation  = AgentMap.create parameter error 0 in
  let error, init_remanent_modif     = AgentMap.create parameter error 0 in
  let init_restriction_bdu_test =
    {
      store_remanent_triple    = init_remanent_triple;
      store_remanent_test      = init_remanent_test;
      store_remanent_creation  = init_remanent_creation;
      store_remanent_modif     = init_remanent_modif;
    }
  in
  error, init_restriction_bdu_test

(************************************************************************************)
(*init of bdu build map*)

let init_bdu_build_map parameter error =
  let init_remanent_test_map      = Map_test.Map.empty in
  let init_remanent_creation_map  = Map_creation.Map.empty in
  let init_remanent_modif_map     = Map_modif.Map.empty in
  (*let error, init_test_bdu        = AgentMap.create parameter error 0 in*) (*REMOVE*)
  (*let error, init_creation_bdu    = AgentMap.create parameter error 0 in*) (*REMOVE*)
  let init_creation_bdu_map       = Map_creation_bdu.Map.empty in
  let init_test_bdu_map           = Map_test_bdu.Map.empty in
  let init_modif_list_map         = Map_modif_list.Map.empty in
  let init_bdu_build_map =
    {
      store_remanent_test_map      = init_remanent_test_map;
      store_remanent_creation_map  = init_remanent_creation_map;
      store_remanent_modif_map     = init_remanent_modif_map;
      (*store_test_bdu               = init_test_bdu;
      store_creation_bdu           = init_creation_bdu;*)
      store_creation_bdu_map       = init_creation_bdu_map;
      store_test_bdu_map           = init_test_bdu_map;
      store_modif_list_map         = init_modif_list_map
    }
  in
  error, init_bdu_build_map

(************************************************************************************)
(*init of bdu fixpoint*)

(*let init_bdu_fixpoint parameter error =
  let error, init_bdu_creation_array = AgentMap.create parameter error 0 in
  let error, init_bdu_test_array     = AgentMap.create parameter error 0 in
  let init_bdu_fixpoint =
    {
      store_bdu_creation_array = init_bdu_creation_array;
      store_bdu_test_array     = init_bdu_test_array;
    }
  in
  error, init_bdu_fixpoint*)

(************************************************************************************)
(*rules*)

let scan_rule_set parameter error handler store_covering_classes compiled rules =
  let error, init_bdu_analysis_dynamic = init_bdu_analysis_dynamic parameter error in
  let error, init_bdu_build            = init_bdu_build parameter error in
  let error, init_bdu_build_map        = init_bdu_build_map parameter error in
  (*let error, init_bdu_fixpoint         = init_bdu_fixpoint parameter error in*)
  let init_bdu =
    {
      store_bdu_analysis_static  = init_bdu_analysis_static;
      store_bdu_analysis_dynamic = init_bdu_analysis_dynamic;
      store_bdu_build            = init_bdu_build;
      store_bdu_build_map        = init_bdu_build_map;
      (*store_bdu_fixpoint         = init_bdu_fixpoint*)
    }
  in
  (*------------------------------------------------------------------------------*)
  (*map each agent to a covering classes*)
  let error, store_results =
    Nearly_inf_Imperatif.fold
      parameter error
      (fun parameter error rule_id rule store_result ->
        let error, result =
          scan_rule
            parameter
            error
            handler
            rule_id
            rule.e_rule_c_rule
            store_covering_classes
            compiled
            store_result
        in
        error, result
      ) rules init_bdu
  in
  error, store_results

(************************************************************************************)
(*MAIN*)

let bdu_main parameter error handler store_covering_classes cc_compil =
  let error, result =
    scan_rule_set
      parameter
      error 
      handler
      store_covering_classes
      cc_compil 
      cc_compil.rules 
  in
  let error =
    if  (Remanent_parameters.get_trace parameter) || trace
    then print_result parameter error result
    else error
  in
  error, result
