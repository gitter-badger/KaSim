open Operator

type str_pos = string * Tools.pos

type ('a,'annot) link =
  | LNK_VALUE of int * 'annot
  | FREE
  | LNK_ANY
  | LNK_SOME
  | LNK_TYPE of 'a (* port *)
    * 'a (*agent_type*)

type internal = string Location.annot list

type port = {port_nme:string Location.annot;
	     port_int:internal;
	     port_lnk:(string Location.annot,unit) link Location.annot;}

type agent = (string Location.annot * port list)

type mixture = agent list

type 'mixt ast_alg_expr =
    BIN_ALG_OP of
      bin_alg_op * 'mixt ast_alg_expr Location.annot
      * 'mixt ast_alg_expr Location.annot
  | UN_ALG_OP of un_alg_op * 'mixt ast_alg_expr Location.annot
  | STATE_ALG_OP of state_alg_op
  | OBS_VAR of string
  | TOKEN_ID of string
  | KAPPA_INSTANCE of 'mixt
  | CONST of Nbr.t
  | TMAX
  | EMAX
  | PLOTNUM

type 'a bool_expr =
  | TRUE
  | FALSE
  | BOOL_OP of
      bool_op * 'a bool_expr Location.annot * 'a bool_expr Location.annot
  | COMPARE_OP of compare_op * 'a Location.annot * 'a Location.annot

type arrow = RAR | LRAR

type rule = {
  lhs: mixture ;
  rm_token: (mixture ast_alg_expr Location.annot * string Location.annot) list ;
  arrow:arrow ;
  rhs: mixture ;
  add_token: (mixture ast_alg_expr Location.annot * string Location.annot) list;
  k_def: mixture ast_alg_expr Location.annot ;
  k_un:
    (mixture ast_alg_expr Location.annot *
       mixture ast_alg_expr Location.annot option) option;
  (*k_1:radius_opt*)
  k_op: mixture ast_alg_expr Location.annot option ; (*rate for backward rule*)
}

let flip_label str = str^"_op"

type 'alg_expr print_expr =
    Str_pexpr of string
  | Alg_pexpr of 'alg_expr

type 'mixture modif_expr =
  | INTRO of ('mixture ast_alg_expr Location.annot * 'mixture Location.annot)
  | DELETE of ('mixture ast_alg_expr Location.annot * 'mixture Location.annot)
  | UPDATE of
      (string Location.annot * 'mixture ast_alg_expr Location.annot) (*TODO: pause*)
  | UPDATE_TOK of
      (string Location.annot * 'mixture ast_alg_expr Location.annot) (*TODO: pause*)
  | STOP of ('mixture ast_alg_expr print_expr Location.annot list * Tools.pos)
  | SNAPSHOT of
      ('mixture ast_alg_expr print_expr Location.annot list * Tools.pos)
  (*maybe later of mixture too*)
  | PRINT of
      (('mixture ast_alg_expr print_expr Location.annot list) *
	  ('mixture  ast_alg_expr print_expr Location.annot list) * Tools.pos)
  | PLOTENTRY
  | CFLOWLABEL of (bool * string Location.annot)
  | CFLOWMIX of (bool * 'mixture Location.annot)
  | FLUX of 'mixture ast_alg_expr print_expr Location.annot list * Tools.pos
  | FLUXOFF of 'mixture ast_alg_expr print_expr Location.annot list * Tools.pos

type 'mixture perturbation =
    ('mixture ast_alg_expr bool_expr Location.annot * ('mixture modif_expr list) *
       'mixture ast_alg_expr bool_expr Location.annot option) Location.annot

type configuration = string Location.annot * (str_pos list)

type 'mixture variable_def =
    string Location.annot * 'mixture ast_alg_expr Location.annot

type 'mixture init_t =
  | INIT_MIX of 'mixture ast_alg_expr Location.annot * 'mixture Location.annot
  | INIT_TOK of 'mixture ast_alg_expr Location.annot * string Location.annot

type 'mixture instruction =
  | SIG      of agent
  | TOKENSIG of string Location.annot
  | VOLSIG   of str_pos * float * str_pos (* type, volume, parameter*)
  | INIT     of string Location.annot option * 'mixture init_t * Tools.pos
  (*volume, init, position *)
  | DECLARE  of 'mixture variable_def
  | OBS      of 'mixture variable_def (*for backward compatibility*)
  | PLOT     of 'mixture ast_alg_expr Location.annot
  | PERT     of 'mixture perturbation
  | CONFIG   of configuration

type ('agent,'mixture,'rule) compil =
    {
      variables :
	'mixture variable_def list;
      (*pattern declaration for reusing as variable in perturbations or kinetic rate*)
      signatures :
	'agent list; (*agent signature declaration*)
      rules :
	(string Location.annot option * 'rule Location.annot) list;
      (*rules (possibly named)*)
      observables :
	'mixture ast_alg_expr Location.annot list;
      (*list of patterns to plot*)
      init :
	(string Location.annot option * 'mixture init_t * Tools.pos) list;
      (*initial graph declaration*)
      perturbations :
	'mixture perturbation list;
      configurations :
	configuration list;
      tokens :
	string Location.annot list;
      volumes :
	(str_pos * float * str_pos) list
    }

let no_more_site_on_right warning left right =
  List.for_all
    (fun p ->
     List.exists (fun p' -> fst p.port_nme = fst p'.port_nme) left
     || let () =
	  if warning then
	    ExceptionDefn.warning
	      ~pos:(snd p.port_nme)
	      (fun f ->
		Format.fprintf
		  f "@[Site@ '%s'@ was@ not@ mentionned in@ the@ left-hand@ side."
		  (fst p.port_nme);
		Format.fprintf
		  f "This@ agent@ and@ the@ following@ will@ be@ removed@ and@ ";
		Format.fprintf
		  f "recreated@ (probably@ causing@ side@ effects).@]")
	in false)
    right

let result:(agent,mixture,rule) compil ref =
  ref {
    variables      = [];
    signatures     = [];
    rules          = [];
    init           = [];
    observables    = [];
    perturbations  = [];
    configurations = [];
    tokens         = [];
    volumes        = []
  }

let init_compil () =
  result :=
    {
      variables      = [];
      signatures     = [];
      rules          = [];
      init           = [];
      observables    = [];
      perturbations  = [];
      configurations = [];
      tokens         = [];
      volumes        = []
    }

(*
  let reverse res = 
  let l_pat = List.rev !res.patterns
  and l_sig = List.rev !res.signatures
  and l_rul = List.rev !res.rules
  and l_ini = List.rev !res.init
  and l_obs = List.rev !res.observables
  in
  res:={patterns=l_pat ; signatures=l_sig ; rules=l_rul ; init = l_ini ; observables = l_obs}
*)

let print_link pr_type pr_annot f = function
  | FREE -> ()
  | LNK_TYPE (p, a) -> Format.fprintf f "!%a.%a" pr_type p pr_type a
  | LNK_ANY -> Format.fprintf f "?"
  | LNK_SOME -> Format.fprintf f "!_"
  | LNK_VALUE (i,a) -> Format.fprintf f "!%i%a" i pr_annot a

let print_ast_link =
  print_link (fun f (x,_) -> Format.pp_print_string f x) (fun _ () -> ())
let print_ast_internal f l =
  Pp.list Pp.empty (fun f (x,_) -> Format.fprintf f "~%s" x) f l

let print_ast_port f p =
  Format.fprintf f "%s%a%a" (fst p.port_nme)
		 print_ast_internal p.port_int
		 print_ast_link (fst p.port_lnk)

let print_ast_agent f ((ag_na,_),l) =
  Format.fprintf f "%s(%a)" ag_na
		 (Pp.list (fun f -> Format.fprintf f ",") print_ast_port) l

let print_ast_mix f m = Pp.list Pp.comma print_ast_agent f m

let rec print_ast_alg f = function
  | EMAX -> Format.fprintf f "[Emax]"
  | PLOTNUM -> Format.fprintf f "[p]"
  | TMAX -> Format.fprintf f "[Tmax]"
  | CONST n -> Nbr.print f n
  | OBS_VAR lab -> Format.fprintf f "'%s'" lab
  | KAPPA_INSTANCE ast ->
     Format.fprintf f "|%a|" print_ast_mix ast
  | TOKEN_ID tk -> Format.fprintf f "|%s|" tk
  | STATE_ALG_OP op -> Operator.print_state_alg_op f op
  | BIN_ALG_OP (op, (a,_), (b,_)) ->
     Format.fprintf f "(%a %a %a)"
		    print_ast_alg a Operator.print_bin_alg_op op print_ast_alg b
  |UN_ALG_OP (op, (a,_)) ->
    Format.fprintf f "(%a %a)" Operator.print_un_alg_op op print_ast_alg a

let print_tok f ((nb,_),(n,_)) = Format.fprintf f "%a:%s" print_ast_alg nb n
let print_one_size tk f mix =
  Format.fprintf
    f "%a%t%a" print_ast_mix mix
    (fun f -> match tk with [] -> () | _::_ -> Format.pp_print_string f " | ")
    (Pp.list (fun f -> Format.pp_print_string f " + ") print_tok) tk
let print_arrow f = function
  | RAR -> Format.pp_print_string f "->"
  | LRAR -> Format.pp_print_string f "<->"
let print_raw_rate op f (def,_) =
  Format.fprintf
    f "%a%t" print_ast_alg def
    (fun f ->
     match op with None -> ()
		 | Some (d,_) -> Format.fprintf f ", %a" print_ast_alg d)
let print_rates un op f def =
  Format.fprintf
    f "%a%t" (print_raw_rate op) def
    (fun f ->
     match un with None -> ()
		 | Some (d,o) -> Format.fprintf f " (%a)" (print_raw_rate o) d)
let print_ast_rule f r =
  Format.fprintf
    f "@[<h>%a %a %a @@ %a@]"
    (print_one_size r.rm_token) r.lhs
    print_arrow r.arrow
    (print_one_size r.add_token) r.rhs
    (print_rates r.k_un r.k_op) r.k_def
let print_ast_rule_no_rate ~reverse f r =
    Format.fprintf
    f "@[<h>%a -> %a@]"
    (print_one_size r.rm_token) (if reverse then r.rhs else r.lhs)
    (print_one_size r.add_token) (if reverse then r.lhs else r.rhs)

let rec print_bool p_alg f = function
  | TRUE -> Format.fprintf f "[true]"
  | FALSE -> Format.fprintf f "[false]"
  | BOOL_OP (op,(a,_), (b,_)) ->
     Format.fprintf f "(%a %a %a)" (print_bool p_alg) a
		    Operator.print_bool_op op (print_bool p_alg) b
  | COMPARE_OP (op,(a,_), (b,_)) ->
     Format.fprintf f "(%a %a %a)"
		    p_alg a Operator.print_compare_op op p_alg b

let print_ast_bool = print_bool print_ast_alg

