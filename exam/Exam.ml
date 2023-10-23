let foo =
let double f x = f (f x) in fun g x -> double (g x);;
(* foo (+) 2 3, foo ( * ) 2 3, foo ( * ) 3 2 *)
let foo =
let rec tails l = match l with [] -> [] | x::xs -> xs::tails xs in
fun l -> List.combine l (tails l);;
(* foo [1; 2; 3] *)

let rec drop1 l =
  match l with
    | [] -> []
    | x::xs -> xs :: List.map (fun r -> x::r) (drop1 xs)
let rec drop2 l =
  match l with
    | [] -> []
    | x::xs -> List.map (fun r -> x::r) (drop2 xs) @ drop1 xs
        
type 'a btree = Tip | Node of 'a btree * 'a * 'a btree

let bfs p t =
  let rec search queue =
    match queue with
      | [] -> None
      | Tip::rest -> search rest
      | Node (l, e, r)::rest ->
        if p e then Some e else search (rest @ [l; r]) in
  search [t]

let example =
  Node (Tip, 0, Node (Node (Tip, 1, Node (Tip, 6, Tip)), 2,
                      Node (Node (Tip, 3, Tip),
                            4, Node (Tip, 5, Tip))))
;;
bfs (fun x->x>3) example;;
bfs (fun x->x>4) example;;


(* Last ex. *)

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
  match l with [] -> true | x::xs -> not (List.mem x xs) && unique xs

let valid_queens q =
  let n = List.length q in
  unique q && unique (List.map2 (+) (from_to 1 n) q)
  && unique (List.map2 (-) (from_to 1 n) q)

let add_queen queens row =
  if valid_queens (row::queens) then [ row::queens ] else []

let find_queen queens =
  concat_map (add_queen queens) (from_to 1 8)

let find_queens (queen_num : int) solution =
  find_queen solution

let solve num_queens =
  concat_foldl find_queens [[]] (from_to 1 num_queens)
;;

solve 4
