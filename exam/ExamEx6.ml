let rec from_to m n =
  if m > n then []
  else m :: from_to (m+1) n

let concat_map f l =
  let rec cmap_f accu = function
    | [] -> accu
    | a::l -> cmap_f (List.rev_append (f a) accu) l
  in
  List.rev (cmap_f [] l)

let rec concat_foldl f accu l =
  match l with
    | [] -> accu
    | a::l -> concat_foldl f (concat_map (f a) accu) l

let rec unique (l : int list) =
  match l with
    | [] -> true
    | x::xs -> not (List.mem x xs) && unique xs

(*
let valid_queens q =
*)

(*
let add_queen queens row =
*)

(*
let find_queen queens =
*)

(*
let find_queens (queen_num : int) solution =
*)

(*
let solve num_queens =
*)

solve 4
