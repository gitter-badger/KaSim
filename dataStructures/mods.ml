let int_compare (x: int) y = Pervasives.compare x y
let int_pair_compare (p,q) (p',q') =
  let o = int_compare p p' in
  if o = 0 then int_compare q q' else o

module StringSetMap =
  SetMap.Make (struct type t = string
		      let compare = String.compare
		      let print = Format.pp_print_string end)
module StringSet = StringSetMap.Set
module StringMap = StringSetMap.Map
module IntSetMap =
  SetMap.Make (struct type t = int
		      let compare = int_compare
		      let print = Format.pp_print_int end)
module IntSet = IntSetMap.Set
module IntMap = IntSetMap.Map
module Int2SetMap =
  SetMap.Make (struct type t = int*int
		      let compare = int_pair_compare
		      let print f (a,b) =
			Format.fprintf f "(%i, %i)" a b end)
module Int2Set = Int2SetMap.Set
module Int2Map = Int2SetMap.Map
module CharSetMap =
  SetMap.Make (struct type t = char
		      let compare = compare
		      let print = Format.pp_print_char end)
module CharSet = CharSetMap.Set
module CharMap = CharSetMap.Map

module DynArray = DynamicArray.DynArray(LargeArray)

type 'a simulation_info = (* type of data to be given with observables for story compression (such as date when the obs is triggered*)
    {
      story_id: int ;
      story_time: float ;
      story_event: int ;
      profiling_info: 'a;
    }

let event_of_simulation_info a = a.story_event
let story_id_of_simulation_info a = a.story_id

module Palette:
	sig
	  type t
	  type color = (float*float*float)
	  val find : int -> t -> color
	  val add : int -> color -> t -> t
	  val mem : int -> t -> bool
	  val empty : t
	  val new_color : unit -> color
	  val grey : int -> string
	  val string_of_color : color -> string
	end =
	struct
	  type color = (float*float*float)
	  type t = color IntMap.t
	  let find x p =
	    match IntMap.find_option x p with Some c -> c | None -> raise Not_found
	  let add = IntMap.add
	  let mem = IntMap.mem
	  let empty = IntMap.empty
	  let new_color () = Random.float 1.0,Random.float 1.0,Random.float 1.0
	  let grey d = if d > 16 then "black" else ("gray"^(string_of_int (100-6*d)))
	  let string_of_color (r,g,b) = String.concat "," (List.rev_map string_of_float [b;g;r])
	end

let update_profiling_info a info =
  {
    story_id = info.story_id ;
    story_time = info.story_time ;
    story_event = info.story_event ;
    profiling_info = a}

let compare_profiling_info info1 info2 = compare info1.story_id info2.story_id
