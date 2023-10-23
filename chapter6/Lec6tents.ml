(* Helper functions *)

let ( |> ) x f = f x

let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l in
  List.rev (cmap_f [] l)
let ( |-> ) x f = concat_map f x

let unique l =
  let rec idemp acc = function
    | e1::(e2::_ as tl) when compare e1 e2 = 0 -> idemp acc tl
    | e::tl -> idemp (e::acc) tl
    | [] -> acc in
  idemp [] (List.sort (fun x y -> - (compare x y)) l)

let map_reduce mapf redf base l =
  match List.sort (fun x y -> compare (fst x) (fst y))
    (List.map mapf l)
  with
  | [] -> []
  | (k0, v0)::tl ->
    let k0, vs, l =
      List.fold_left (fun (k0, vs, l) (kn, vn) ->
	if k0 = kn then k0, vn::vs, l
        else kn, [vn], (k0,vs)::l)
	(k0, [v0], []) tl in
    List.rev_map (fun (k,vs) -> k, List.fold_left redf base vs)
      ((k0,vs)::l)

(* Test cases *)
type puzzle = {
  width : int;
  height : int;
  trees : (int * int) list;
  ntents : int;
  columns : (int * int) list;           (* column, # of tents on it *)
  rows : (int * int) list               (* row, # of tents on it *)
}

let test0 = {width = 2; height = 2;
             trees=[0,0; 1,1];
             ntents = 2;
             columns = [0,1; 1,1]; rows = [0,1; 1,1]}
let test1 = {width = 2; height = 2;
             trees=[0,0];
             ntents = 1;
             columns = [0,1]; rows = [1,1]}

(* Solver *)

let tent_cands puzzle =
  puzzle.trees |-> (fun (x,y) ->
    List.filter
      (fun (x,y) -> x>=0 && y>=0 && x<puzzle.width && y<puzzle.height)
      [x-1,y; x+1,y; x,y-1; x,y+1])
  |> unique

let column_counts tents =
  map_reduce (fun p->p) (fun c _ -> c+1) 0 tents
let row_counts tents =
  map_reduce (fun (x,y)->y,x) (fun c _ -> c+1) 0 tents

let touching tents =
  let neighbors =
    tents |-> (fun (x,y) ->
      [x,y; x-1,y; x+1,y; x,y-1; x,y+1]) in
  List.sort (fun x y -> - (compare x y)) neighbors = unique neighbors
  

let valid puzzle tents =
  List.length tents = puzzle.ntents &&
  column_counts tents = puzzle.columns &&
  row_counts tents = puzzle.rows && not (touching tents)

let within puzzle tents =
  try
    List.length tents <= puzzle.ntents &&
      List.for_all
      (fun (col, n) -> n <= List.assoc col puzzle.columns)
      (column_counts tents) &&
      List.for_all
      (fun (row, n) -> n <= List.assoc row puzzle.rows)
      (row_counts tents) &&
      not (touching tents)
  with Not_found -> false

let rec solve puzzle partials = function
  | [] -> List.filter (valid puzzle) partials
  | cand::cands ->
    solve puzzle
      (List.filter (within puzzle)
         (List.map (fun partial->cand::partial) partials)
       @ partials)
      cands
  
let solve puzzle = solve puzzle [[]] (tent_cands puzzle)
