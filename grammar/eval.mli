val init_kasa :
  Remanent_parameters_sig.called_from ->
  (string Location.annot * Ast.port list, Ast.mixture, string, Ast.rule)
    Ast.compil ->
  (string list * (string * string) list) Export_to_KaSim.String2Map.t *
    Export_to_KaSim.Export_to_KaSim.state

val compile :
  outputs:(Data.t -> 'a) -> pause:((unit -> 'b) -> 'b) ->
  return:(Environment.t * Connected_component.Env.t * bool *
	    (Alg_expr.t * Primitives.elementary_rule * Location.t) list -> 'b) ->
  ?rescale_init:float -> Signature.s -> unit NamedDecls.t ->
  (string list * (string * string) list) Export_to_KaSim.String2Map.t ->
  Counter.t -> ('c, LKappa.rule_mixture, int, LKappa.rule) Ast.compil -> 'b

val build_initial_state :
  (int * Alg_expr.t) list -> Counter.t -> Environment.t ->
  Connected_component.Env.t -> bool -> int list ->
  (Alg_expr.t * Primitives.elementary_rule * Location.t) list ->
  Environment.t * Rule_interpreter.t * State_interpreter.t