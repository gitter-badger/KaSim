(** Main compilation functions *)

val init_kasa :
  Remanent_parameters_sig.called_from -> Signature.s ->
  (string Location.annot * Ast.port list, Ast.mixture, string, Ast.rule)
    Ast.compil ->
  Primitives.contact_map * Export_to_KaSim.Export_to_KaSim.state

val compile_bool:
  Primitives.contact_map -> Connected_component.PreEnv.t ->
  (LKappa.rule_mixture, int) Ast.ast_alg_expr Ast.bool_expr Location.annot ->
  Connected_component.PreEnv.t * Alg_expr.t Ast.bool_expr Location.annot

val compile_modification_no_update:
  Primitives.contact_map -> Connected_component.PreEnv.t ->
  (LKappa.rule_mixture, int) Ast.modif_expr ->
  Connected_component.PreEnv.t * Primitives.modification list

val compile :
  outputs:(Data.t -> 'a) -> pause:((unit -> 'b) -> 'b) ->
  return:(Environment.t * Connected_component.Env.t * (bool*bool*bool) option *
	    bool option * bool *
	      (Alg_expr.t * Primitives.elementary_rule * Location.t) list -> 'b) ->
  ?rescale_init:float -> Signature.s -> unit NamedDecls.t ->
  Primitives.contact_map ->
  Counter.t -> ('c, LKappa.rule_mixture, int, LKappa.rule) Ast.compil -> 'b

val build_initial_state :
  bind:('a -> (Rule_interpreter.t * State_interpreter.t -> 'a) -> 'a) ->
  return:(Rule_interpreter.t * State_interpreter.t -> 'a) ->
  (int * Alg_expr.t) list -> Counter.t -> Environment.t ->
  Connected_component.Env.t -> ((bool*bool*bool)*bool) option ->
  bool option -> int list ->
  (Alg_expr.t * Primitives.elementary_rule * Location.t) list ->
  Environment.t * 'a
