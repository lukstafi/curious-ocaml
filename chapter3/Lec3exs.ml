type ('a, 'b) choice = Left of 'a | Right of 'b

type btree = Tip | Node of btree * int * btree

type btree_dir = LeftBranch | RightBranch
type btree_deriv =
  | Here of btree * btree
  | Below of btree_dir * int * btree * btree_deriv

let rec btree_integr n t =
  match t with
    | Here(left,right) -> Node(left,n,right)
    | Below(LeftBranch,m,right,left) ->  Node((btree_intergr n left), m, right)
    | Below(RightBranch,m,left,right) ->
      Node(left,m,(btree_intergr n right))

let rec depth tree k = match tree with
    | Tip -> k 0
    | Node(left,_,right) ->
      depth left (fun dleft ->
        depth right (fun dright ->
          k (1 + (max dleft dright))))
let depth t = depth t (fun i->i)

let rec prefix t =
  match t with
    |Tip -> []
    |Node(left,n,right) -> n::prefix left @ prefix right

let breadth_first t =
  let rec aux queue =
    match queue with
      | [] -> []
      | Tip::rest -> aux rest
      | Node(left,n,right)::rest -> n::aux (rest @ [left; right]) in
  aux [t]

let rec prefix_tr t =
  let rec loop queue = function
    | Tip -> queue
    | Node (l, n, Tip) -> loop (n::queue) l
    | Node (l, k, Node (rl, n, rr)) ->
      loop queue (Node (Node (l, k, rl), n, rr)) in
  loop [] t
    

let rec prefix_cps tree k =
  match tree with
  | Tip -> k []
  | Node (left,n,right) ->
    prefix_cps left (fun nleft ->
        prefix_cps right (fun nright ->
            k (n :: nleft @ nright)))
let prefix_cps t = prefix_cps t (fun l -> l)

let rec btree_deriv_at p bt =
  match bt with
    | Tip -> None
    | Node (left,n,right) ->
      if p n then Some (Here (left, right))
      else
        match btree_deriv_at p left with
          | Some found_left ->
            Some (Below (LeftBranch, n, right, found_left))
          | None ->
            match btree_deriv_at p right with
              | Some found_right ->
                Some (Below (RightBranch, n, left, found_right))
              | None -> None

#use "Lec3.ml";;

let rec fixpoint f x =
  let x' = f x in
  if x = x' then x
  else fixpoint f x'

let rec simplify_once exp =
  let rec flatten exp =
    match exp with
      | Const _ as c -> c
      | Var _ as v -> v
      | Sum (Const _ as f, g) -> Sum (f, simplify_once g)
      | Sum (Sum (f, (Const _ as g)), h) ->
        (* move constants to the front of addition *)
        flatten (Sum (g, Sum (f, h)))
      | Sum (f, (Const _ as g)) ->
        flatten (Sum (g, f))
      | Sum (Sum (f, g), h) ->
        (* flatten addition into a right-slanted list *)
        flatten (Sum (f, Sum (g, h)))
      | Sum (f, g) -> Sum (simplify_once f, simplify_once g)
      | Diff (f, g) ->
        flatten (Sum (f, Prod (Const (-1.0), g)))
      | Prod(Const _ as f, g) -> Prod (f, simplify_once g)
      | Prod (Prod (f, (Const _ as g)), h) ->
        (* move constants to the front of multiplication *)
        flatten (Prod (g, Prod (f, h)))
      | Prod (f, (Const _ as g)) ->
        flatten (Prod (g, f))
      | Prod (Prod (f, g), h) ->
        (* flatten multiplication into a right-slanted list *)
        flatten (Prod (f, Prod (g, h)))
      | Prod(f, g) -> Prod (simplify_once f, simplify_once g)
      | Quot(f, g) -> Quot (flatten f, flatten g) in
  match flatten exp with
    | Const _ as c -> c
    | Var _ as v -> v
    | Sum (Const a, Const b) -> Const (a +. b)
    | Sum (Const 0.0, g) -> g
    | Sum (f, g) when f = g -> Prod (Const 2.0, f)
    | Sum (Prod (Const a, f), g) when f = g ->
      Prod (Const (a +. 1.0), f)
    | Sum (g, Prod (Const a, f)) when f = g ->
      Prod (Const (a +. 1.0), f)
    | Sum (Prod (Const a, f), Prod (Const b, g)) when f = g ->
      Prod (Const (a +. b), f)
    | Sum (Const a, Sum (Const b, g)) -> Sum (Const (a +. b), g)
    | Sum (Prod (Const (-1.0), f), Prod (Const (-1.0), g)) ->
      Prod (Const (-1.0), Sum (f, g))
    | Sum (Prod (Const (-1.0), f), g) when f = g -> Const 0.0
    | Sum (Prod (Const (-1.0), f), g) -> Diff (g, f)
    | Sum (f, Prod (Const (-1.0), g)) when f = g -> Const 0.0
    | Sum (f, Prod (Const (-1.0), g)) -> Diff (f, g)
    | Sum _ as res -> res
    | Diff (f, g) -> assert false

    | Prod (Const a, Const b) -> Const (a *. b)
    | Prod (Const 0.0, g) -> Const 0.0
    | Prod (Const 1.0, g) -> g
    | Prod (Const a, Prod (Const b, g)) -> Prod (Const (a *. b), g)
    | Prod _ as res -> res

    | Quot(f, Const c) ->
      Prod (Const (1.0 /. c), f)
    | Quot(f, Prod (Const c, g)) ->
      Prod (Const (1.0 /. c), Quot (f, g))
    | Quot(f, Prod (g, h)) when f = g ->
      Quot (Const 1.0, h)
    | Quot(Prod (e, f), Prod (g, h)) when e = g ->
      Quot (f, h)
    | Quot _ as res -> res

let simplify = fixpoint simplify_once
