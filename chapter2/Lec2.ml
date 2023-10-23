type coords = Coords of int * int

let longitude (Coords (x,_)) = x

type ('a, 'b) choice = Left of 'a | Right of 'b

type btree = Tip | Node of int * btree * btree

let rec remove_last = function
  | Tip -> raise Not_found
  | Node (left, e, Tip) -> left, e
  | Node (left, e, right) ->
    let removed, last = remove_last right in
    Node (left, e, removed), last

let replace_root_last = function
  | Tip -> Tip
  | t ->
    let removed, last = remove_last t in
    match removed with
    | Tip -> Node (Tip, last, Tip)
    | Node (left, _, right) -> Node (left, last, right)


  

type repr = (int * (int * btree * btree * btree option) option) option

(* Failed attempt:

type repr = (int * (int * btree * btree * btree option) option) option
# let iso1 (t : btree) : repr =
  match t with
    | Tip -> None
    | Node (x, Tip, Tip) -> Some (x, None)
    | Node (x, Node (y, t1, t2), Tip) -> Some (x, Some (y, t1, t2, None))
    | Node (x, Node (y, t1, t2), t3) ->
      Some (x, Some (y, t1, t2, Some t3));;
            Characters 32-261:
  ..match t with
      | Tip -> None
      | Node (x, Tip, Tip) -> Some (x, None)
      | Node (x, Node (y, t1, t2), Tip) -> Some (x, Some (y, t1, t2, None))
      | Node (x, Node (y, t1, t2), t3) ->
        Some (x, Some (y, t1, t2, Some t3))..
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
Node (_, Tip, Node (_, _, _))
val iso1 : btree -> repr = <fun>

 *)

type interm1 =
    ((int * btree, int * int * btree * btree * btree) choice) option
      
type interm2 =
    ((int, int * int * btree * btree * btree option) choice) option

let step1r (t : btree) : interm1 =
  match t with
    | Tip -> None
    | Node (x, t1, Tip) -> Some (Left (x, t1))
    | Node (x, t1, Node (y, t2, t3)) ->
      Some (Right (x, y, t1, t2, t3))

let step1l (r : interm1) : btree =
  match r with
    | None -> Tip
    | Some (Left (x, t1)) -> Node (x, t1, Tip)
    | Some (Right (x, y, t1, t2, t3)) ->
      Node (x, t1, Node (y, t2, t3))

let step2r (r : interm1) : interm2 =
  match r with
    | None -> None
    | Some (Left (x, Tip)) ->
      Some (Left x)
    | Some (Left (x, Node (y, t1, t2))) ->
      Some (Right (x, y, t1, t2, None))
    | Some (Right (x, y, t1, t2, t3)) ->
      Some (Right (x, y, t1, t2, Some t3))

let step2l (r : interm2) : interm1 =
  match r with
    | None -> None
    | Some (Left x) ->
      Some (Left (x, Tip))
    | Some (Right (x, y, t1, t2, None)) ->
      Some (Left (x, Node (y, t1, t2)))
    | Some (Right (x, y, t1, t2, Some t3)) ->
      Some (Right (x, y, t1, t2, t3))

let step3r (r : interm2) : repr =
  match r with
    | None -> None
    | Some (Left x) -> Some (x, None)
    | Some (Right (x, y, t1, t2, t3opt)) ->
      Some (x, Some (y, t1, t2, t3opt))

let step3l (r : repr) : interm2 =
  match r with
    | None -> None
    | Some (x, None) -> Some (Left x)
    | Some (x, Some (y, t1, t2, t3opt)) ->
      Some (Right (x, y, t1, t2, t3opt))
      

let iso1 (t : btree) : repr =
  step3r (step2r (step1r t))

let iso2 (r : repr) : btree =
  step1l (step2l (step3l r))


    (* Take-home lessons:

       * Try to define data structures so that only information that
       makes sense can be represented -- as long as it does not
       overcomplicate the data structures. Avoid catch-all clauses
       when defining functions. The compiler will then tell you if you
       have forgotten about a case.
       
       * Divide solutions into small steps so that each step can be
       easily understood and checked.

    *)

(* Shorter forms using function composition: *)
(* *)
let iso2 = step1l -| step2l -| step3l
let iso1 = step1r |- step2r |- step3r
(* *)
