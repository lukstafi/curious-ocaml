type cell = int * int
module Cells = Set.Make (struct type t = cell let compare = compare end)
let set xs = List.fold_left (fun s x -> Cells.add x s) Cells.empty xs
let adjacent (x, y) =
  [x-1,y-1; x+1,y-1; x+2,y; x+1,y+1; x-1,y+1; x-2,y]
let board n =
  if n < 0 then invalid_arg "negative board size";
  List.init (4*n+1) (fun i -> i-2*n)
  |> List.concat_map (fun x -> List.init (2*n+1) (fun j -> x,j-n))
  |> List.filter (fun (x,y) ->
    (x-y) mod 2 = 0 && abs x + abs y <= 2*n)

type task = { honey : cell list; islands : int; size : int }
let validate t =
  if t.islands < 0 || t.size <= 0 ||
     List.length t.honey <> Cells.cardinal (set t.honey)
  then invalid_arg "invalid task"

(* The specification counts connected components of the retained cells. *)
let valid t eaten =
  let original = set t.honey and removed = set eaten in
  let rec flood todo unseen count = match todo with
    | [] -> count, unseen
    | c :: rest when not (Cells.mem c unseen) -> flood rest unseen count
    | c :: rest -> flood (adjacent c @ rest) (Cells.remove c unseen) (count+1) in
  let rec components n unseen =
    if Cells.is_empty unseen then n = t.islands
    else let c = Cells.min_elt unseen in
      let count, unseen = flood [c] unseen 0 in
      count = t.size && components (n+1) unseen in
  List.length eaten = Cells.cardinal removed &&
  Cells.subset removed original && components 0 (Cells.diff original removed)

let rec subsets = function
  | [] -> [[]]
  | x :: xs -> let rest = subsets xs in rest @ List.map (List.cons x) rest

let reference t = validate t; List.filter (valid t) (subsets t.honey)

(* Branch at every cell, including the first seed of a possible component. *)
let direct t =
  validate t;
  let rec visit eaten = function
    | [] -> if valid t eaten then [List.rev eaten] else []
    | c :: rest -> visit eaten rest @ visit (c :: eaten) rest in
  visit [] t.honey

let number_to_eat t =
  (* Avoid multiplication overflow, and detect an impossible retained size. *)
  let n = List.length t.honey in
  if t.islands > n / t.size then None
  else Some (n - t.islands * t.size)

let optimized t =
  validate t;
  let rec visit remaining need eaten = function
    | _ when need < 0 || need > remaining -> []
    | [] -> if valid t eaten then [List.rev eaten] else []
    | c :: rest ->
      visit (remaining-1) need eaten rest @
      visit (remaining-1) (need-1) (c::eaten) rest in
  match number_to_eat t with
  | None -> []
  | Some need -> visit (List.length t.honey) need [] t.honey

module type CHOICE = sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val choose : 'a list -> 'a t
end
module List_choice = struct
  type 'a t = 'a list
  let return x = [x]
  let bind xs f = List.concat_map f xs
  let choose xs = xs
end
module Solver (M : CHOICE) = struct
  let ( let* ) = M.bind
  let solve t =
    validate t;
    let rec visit eaten = function
      | [] -> if valid t eaten then M.return (List.rev eaten) else M.choose []
      | c :: rest ->
        let* eat = M.choose [false; true] in
        visit (if eat then c::eaten else eaten) rest in
    visit [] t.honey
end
module Monadic = Solver (List_choice)

(* StateT(List): each branch owns its own eaten-cell state. *)
module State_choice = struct
  type 'a t = cell list -> ('a * cell list) list
  let return x s = [x, s]
  let bind m f s = List.concat_map (fun (x,s') -> f x s') (m s)
  let choose xs s = List.map (fun x -> x,s) xs
  let modify f s = [(), f s]
  let get s = [s,s]
end
let transformer t =
  validate t;
  let open State_choice in
  let ( let* ) = bind in
  let rec visit = function
    | [] -> let* eaten = get in
      if valid t eaten then return (List.rev eaten) else choose []
    | c::rest ->
      let* eat = choose [false; true] in
      let* () = modify (fun s -> if eat then c::s else s) in
      visit rest in
  List.map fst (visit t.honey [])
