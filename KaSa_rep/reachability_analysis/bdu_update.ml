(**
  * bdu_update.ml
  * openkappa
  * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
  * 
  * Creation: 2015, the 12th of October
  * Last modification: 
  * 
  * Compute the relations between sites in the BDU data structures
  * 
  * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et   
  * en Automatique.  All rights reserved.  This file is distributed     
  * under the terms of the GNU Library General Public License *)

open Cckappa_sig
open Int_storage
open Bdu_analysis_type
open Bdu_contact_map
open Set_and_map

open Print_bdu_analysis

let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "BDU update function") message exn (fun () -> default)  

let trace = false

(************************************************************************************)
(*a bond is discovered for the first time:
  For example:
  'r0' A() ->
  'r1' A(x) ->
  'r2' A(x!B.x) -> A(x)
  'r3' A(x), B(x) -> A(x!1), B(x!1)
  'r4' A(x,y), C(y) -> A(x,y!1), C(y!1)
  
  'r3' has a bond on the rhs, for any (rule_id, state) belong to side
  effects of A(x); state is compatible with B(x!1), add rule_id into update
  function.
*)

(*map (agent_type_cv, covering_class_id) -> rule_id list of modified sites*)

let store_covering_classes_modification_update_aux parameter error agent_type_cv
    site_type_cv covering_class_id store_modification_sites_without_creation store_result =
  let add_link (agent_type_cv, site_type_cv, cv_id) rule_id store_result =
    (*searching in the result whether or not those signatures are already inside*)
    let error, (l, old) =
      try Int2Map_CV_Modif.find_map parameter error
            (agent_type_cv, site_type_cv, cv_id) store_result
      with Not_found -> error, ([], Site_map_and_set.empty_set)
    in
    let error, current_set =
      Site_map_and_set.add_set parameter error rule_id old
    in
    let error, new_set =
      Site_map_and_set.union parameter error current_set old
    in
    let error, result =
      Int2Map_CV_Modif.add_map parameter error (agent_type_cv, site_type_cv, cv_id)
        (l, new_set) store_result
    in
    (*add the fresh signature into the old result and store them*)
    (*let error, result =
      Int2Map_CV_Modif.add_map parameter error (agent_type_cv, site_type_cv, cv_id)
        (l, rule_id :: old) store_result
    in*)
    error, result
  in
  (*Example:
    - modification_sites: 
    [agent_type:0@site_type:0:rule_id:2;
     agent_type:0@site_type:0:rule_id:1]
    - covering class:
    [agent_type:0@site_type:0:covering_class_id:0]
    - map each covering class to the list of rule that may modify the view of
    covering class.
    - result:
    [agent_type:0@site_type:0:covering_class_id:0:rule_id:2;
     agent_type:0@site_type:0:covering_class_id:0:rule_id:1]
  *)
  let error, result =
    Int2Map_Modif.fold_map
      (fun (agent_type_modif, site_modif) (m1, s2) store_result ->
        Site_map_and_set.fold_set (fun rule_id_modif (error, store_current_result) ->
          if compare agent_type_cv agent_type_modif = 0 &&
            compare site_type_cv site_modif = 0
          then
            let error, result =
              add_link (agent_type_cv, site_type_cv, covering_class_id) rule_id_modif 
                store_current_result
            in
            error, result
          else
            error, store_current_result
        ) s2 store_result
      ) store_modification_sites_without_creation store_result
  in error, result
    
(************************************************************************************)

let store_covering_classes_modification_update parameter error
    store_modification_sites_without_creation
    store_covering_classes_id =
  let error, store_result =
    Int2Map_CV.fold_map
      (fun (agent_type_cv, site_type_cv) (l1, l2) store_result ->
        List.fold_left (fun store_current_result cv_id ->
          let error, result =
            store_covering_classes_modification_update_aux
              parameter
              error
              agent_type_cv
              site_type_cv
              cv_id
              store_modification_sites_without_creation
              store_current_result
          in
          error, result
        ) store_result l2
      (*REMARK: when it is folding inside a list, start with empty result,
        because the add_link function has already called the old result.*)
      ) store_covering_classes_id (error, Int2Map_CV_Modif.empty_map)
  in
  let store_result =
    Int2Map_CV_Modif.map_map (fun (l, x) -> List.rev l, x) store_result
  in
  error, store_result

(************************************************************************************)
(*update function when discover a binding site. Added rule_id of side
  effect into the above update function.*)
(*TODO*)

let binding_hb_effect_aux parameter error agent_type_1 site_type_1
    state_1 agent_type_2 site_type_2 store_half_break
    store_covering_classes_modification_update store_result =
  let add_link (agent_type, site_type, cv_id) rule_id_effect store_result =
    let error, (l, old) =
      try Int2Map_CV_Modif.find_map parameter error
            (agent_type, site_type, cv_id) store_result
      with Not_found -> error, ([], Site_map_and_set.empty_set)
    in
    let error, current_set =
      Site_map_and_set.add_set parameter error rule_id_effect old
    in
    let error, new_set =
      Site_map_and_set.union parameter error current_set old
    in
    let error, result =
      Int2Map_CV_Modif.add_map parameter error (agent_type, site_type, cv_id)
        (l, new_set) store_result
    in
    (*let error, result =
      Int2Map_CV_Modif.add_map parameter error (agent_type, site_type, cv_id)
        (l, rule_id_effect :: old) store_result
    in*)
    error, result
  in
  Int2Map_HalfBreak_effect.fold_map
    (fun (agent_type_effect, site_type_effect) (l1, l2) store_result ->
      if l1 <> []
      then ()
      else ();
      List.fold_left (fun (error, store_current_result) (rule_id_effect, state_effect)  ->
        Int2Map_CV_Modif.fold_map (fun (agent_type_cv, site_type_cv, covering_class_id)
          (m1, m2) store_result ->
            Site_map_and_set.fold_set (fun rule_id_update (error, current_result) ->
                (*the first binding agent belong to side effect;
                  the second binding agent belong to update_function*)
              if compare agent_type_1 agent_type_effect = 0 &&
                compare site_type_1 agent_type_effect = 0 &&
                compare state_1 state_effect = 0 &&
                compare agent_type_2 agent_type_cv = 0 &&
                compare site_type_2 site_type_cv = 0
              then
                let error, result =
                  add_link (agent_type_cv, site_type_cv, covering_class_id) 
                    rule_id_effect current_result
                in
                error, result
              else
                error, current_result
            ) m2 store_result
        ) store_covering_classes_modification_update (error, store_current_result)
      ) store_result l2
    ) store_half_break store_result

(************************************************************************************)
(*TODO*)

let binding_remove_effect_aux parameter error agent_type_1 site_type_1 agent_type_2
    site_type_2 store_remove_effect store_covering_classes_modification_update
    store_result =
  let add_link (agent_type, site_type, cv_id) rule_id_effect store_result =
    let error, (l, old) =
      try Int2Map_CV_Modif.find_map parameter error
            (agent_type, site_type, cv_id) store_result
      with Not_found -> error, ([], Site_map_and_set.empty_set)
    in
    let error, current_set =
      Site_map_and_set.add_set parameter error rule_id_effect old
    in
    let error, new_set =
      Site_map_and_set.union parameter error current_set old
    in
    let error, result =
      Int2Map_CV_Modif.add_map parameter error (agent_type, site_type, cv_id)
      (l, new_set) store_result
    in
    (*let error, result =
      Int2Map_CV_Modif.add_map parameter error (agent_type, site_type, cv_id)
        (l, rule_id_effect :: old) store_result (*TEST*)
    in*)
    error, result
  in
  Int2Map_Remove_effect.fold_map
    (fun (agent_type_effect, site_type_effect) (l1, l2) store_result ->
      if l1 <> []
      then ()
      else ();
      List.fold_left (fun (error, store_current_result) rule_id_effect ->
        Int2Map_CV_Modif.fold_map
          (fun (agent_type_cv, site_type_cv, cv_id) (m1, m2)
            store_result ->
              Site_map_and_set.fold_set (fun rule_id_update (error, current_result) ->
                if compare agent_type_1 agent_type_effect = 0 &&
                  compare site_type_1 site_type_effect = 0 &&
                  compare agent_type_2 agent_type_cv = 0 &&
                  compare site_type_2 site_type_cv = 0
                then
                  let error, result =
                    add_link (agent_type_cv, site_type_cv, cv_id)
                      rule_id_effect current_result
                  in
                  error, result
                else
                  error, current_result
              ) m2 store_result
          ) store_covering_classes_modification_update (error, store_current_result)
      ) store_result l2
    ) store_remove_effect store_result

(************************************************************************************)
(*update function*)

let store_binding_update parameter error 
    store_covering_classes_modification_update
    store_side_effects
    store_contact_map =
  (*get side effect information*)
  let store_half_break, store_remove_effect = store_side_effects in
  let (error, store_result_hb),
    (error', store_result_remove),
    store_result_hb_remove,
    store_result_update_aux
    =
    Int2Map_CM_state.fold_map
      (fun (agent_type_1, site_type_1, state_1)
        (l1, l2) store_result ->
          if l1 <> []
          then ()
          else
            ();
          List.fold_left (fun 
            (store_current_result_hb, store_current_result_remove, _, _)
            (agent_type_2, site_type_2, state_2) ->
              (*binding with half break side effect*)
              let error, store_binding_hb =
                binding_hb_effect_aux
                  parameter
                  error
                  agent_type_1
                  site_type_1
                  state_1
                  agent_type_2
                  site_type_2
                  store_half_break
                  store_covering_classes_modification_update
                  store_current_result_hb
              in
              (*binding with remove side effect*)
              let error, store_binding_remove =
                binding_remove_effect_aux
                  parameter
                  error
                  agent_type_1
                  site_type_1
                  agent_type_2
                  site_type_2
                  store_remove_effect
                  store_covering_classes_modification_update
                  store_current_result_remove
              in
              (*combine half break and remove side effect*)
              let error, store_binding_hb_remove =
                Int2Map_CV_Modif.merge_map parameter error
                  store_binding_hb store_binding_remove
              in
              (*combine half_break and remove with previous binding function*)
              let error, store_update_aux =
                Int2Map_CV_Modif.merge_map parameter error
                  store_covering_classes_modification_update
                  store_binding_hb_remove
              in
              ((error, store_binding_hb),
               (error, store_binding_remove),
               store_binding_hb_remove,
               store_update_aux
              )
          ) store_result l2
      ) store_contact_map 
      ((error, Int2Map_CV_Modif.empty_map),
       (error, Int2Map_CV_Modif.empty_map),
       Int2Map_CV_Modif.empty_map,
       Int2Map_CV_Modif.empty_map
      )
  in
  let store_result_hb =
    Int2Map_CV_Modif.map_map (fun (l, x) -> List.rev l, x) store_result_hb
  in
  let store_result_remove =
    Int2Map_CV_Modif.map_map (fun (l, x) -> List.rev l, x) store_result_remove
  in
  let store_result_hb_remove =
    Int2Map_CV_Modif.map_map (fun (l, x) -> List.rev l, x) store_result_hb_remove
  in
  let store_result_update_aux =
    Int2Map_CV_Modif.map_map (fun (l, x) -> List.rev l, x) store_result_update_aux
  in
  error,
  (store_result_hb,
   store_result_remove,
   store_result_hb_remove,
   store_result_update_aux
  )