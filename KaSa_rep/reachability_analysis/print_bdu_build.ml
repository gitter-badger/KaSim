(**
  * print_bdu_build.ml
  * openkappa
  * Jérôme Feret & Ly Kim Quyen, projet Abstraction, INRIA Paris-Rocquencourt
  * 
  * Creation: 2015, the 28th of October
  * Last modification: 
  * 
  * Print relations between sites in the BDU data structures
  * 
  * Copyright 2010,2011,2012,2013,2014 Institut National de Recherche en Informatique et   
  * en Automatique.  All rights reserved.  This file is distributed     
  * under the terms of the GNU Library General Public License *)

open Printf
open Bdu_analysis_type
open Set_and_map
open Cckappa_sig


let warn parameters mh message exn default =
  Exception.warn parameters mh (Some "BDU creation") message exn (fun () -> default)  

let trace = false

(************************************************************************************)
(*restriction bdu_test*)

let print_triple_list l =
  let rec aux acc =
    match acc with
    | [] -> []
    | (id, _, set) :: tl ->
      fprintf stdout "Covering_class_id:%i\n" id;
      Site_map_and_set.iter_set (fun site ->
        fprintf stdout "site_type:%i\n" site
      ) set; aux tl
  in aux l

let print_pair_list l =
  let rec aux acc =
    match acc with
    | [] -> []
    | (id, m) :: tl ->
      fprintf stdout "Covering_class_id:%i\n" id;
      Site_map_and_set.iter_map (fun site state ->
        fprintf stdout "site':%i:state:%i\n" site state
      ) m; aux tl
  in aux l

let print_remanent_test parameter error result =
  AgentMap.print error
    (fun error parameter triple_list ->
      let _ =
        print_triple_list triple_list
      in
      error
    ) parameter result

let print_test_restriction parameter error result =
  AgentMap.print error
    (fun error parameter pair_list ->
      let _ =
        print_pair_list pair_list
      in
      error
    ) parameter result

(************************************************************************************)
(*main print*)

let print_bdu_build parameter error result =
  let _ =
    fprintf (Remanent_parameters.get_log parameter)
      "\n------------------------------------------------------------\n";
    fprintf (Remanent_parameters.get_log parameter)
      "* Build BDU:\n";
    fprintf (Remanent_parameters.get_log parameter)
      "------------------------------------------------------------\n";
  in
  let _ =
    fprintf (Remanent_parameters.get_log parameter)
      "- Covering classes of test:\n";
    print_remanent_test
      parameter
      error
      result.store_remanent_test
  in
  let _ =
    fprintf (Remanent_parameters.get_log parameter)
      "- Covering classes of test restriction:\n";
    print_test_restriction
      parameter
      error
      result.store_test_restriction
  in
  error