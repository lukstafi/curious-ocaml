type btree = Tip | Node of btree * int * btree

let example =
  Node (Node (Node (Tip, 4, Tip), 3, Node (Tip, 7, Tip)),
        1,
        Node (Tip, 5, Node (Tip, 9, Tip)))


let rec prefix_order t =
  match t with
    | Tip -> []
    | Node (left, number, right) ->
      number :: prefix_order left @ prefix_order right
;;
prefix_order example;;

let rec infix_order t =
  match t with
    | Tip -> []
    | Node (left,number,right) ->
      infix_order left @ [ number] @ infix_order right ;;
infix_order example;;

let rec postfix_order t =
  match t with 
    |Tip -> []
    |Node (left,number,right)  ->
      postfix_order left @ postfix_order right @ [ number] ;;
let example = postfix_order example;;

let rec bfs ts =
  match ts with
    | [] -> []
    | Tip :: rest -> bfs rest 
    | Node (left,number,right) :: rest  ->
      number :: bfs (rest @ [left] @ [right])

;;
let breadth_first t =
  bfs [t]

let ex2 = Node (
  Node (Node (Node (Tip, 8, Tip), 0, Node (Tip, 6, Tip)),
        -2, Tip),
  -3,
  Node (example, -1, Node (Tip, 2, Tip)));;
breadth_first ex2;;

let rec reverse l =
  match l with
    |[] -> []
    |head :: tail -> 
      (@) (reverse tail) (head :: []);;

reverse example;;

let rec split_size (n : int) l  =
  match l with
    |[] -> [],[]
    |head :: rest ->
      let smaller,bigger = split_size n rest in
      if head <= n
      then head :: smaller , bigger 
        
      else smaller ,head :: bigger  
;;        
split_size 6 example;;    

let rec quicksort l =
  match l with
    |[] -> []
    |head :: rest ->
      let smaller,bigger = split_size head rest in
      quicksort smaller @ [head] @ quicksort bigger ;;
quicksort example;;


let rec split_len l  =
  match l with
    |[] -> [],[]
    |[x]  -> [x],[]
    | x::y::rest ->
      let l1, l2  = split_len rest in
      x :: l1 , y :: l2
;;        
let example = [4; 4; 6; 1; 2; 9];;
split_len example;;    


let rec merge l1 l2 =
  match l1,l2 with
    |[],l2 -> l2
    |l1,[] -> l1
    |x::xs,y::ys ->
      if x<=y
      then x :: merge xs l2

      else y :: merge ys l1
;;
merge [3;4;5] [1;7;9];;

let rec mergesort l =
  match l with
    | [] -> l
    | [x] -> l
    | _ ->
      let l1, l2 =  split_len l in 
      merge
        (mergesort l1)
        (mergesort l2)
;;
(* Simplification of expressions. *)
let rec fixpoint f x =
  let x' = f x in
  if x = x'
  then x
  else
    fixpoint f x'

let rec simpl_once ex =
  match ex with
      Const c -> ex
    | Var v -> ex
    | Sum (Const 0.0, g) -> simpl_once g
    | Sum (g, Const 0.0) -> simpl_once g
    | Sum (x,y) when x=y -> Prod (Const 2.0 ,x)  
    | Sum(f, g) -> Sum (simpl_once f, simpl_once g)
    | Diff(f, g) -> Diff (simpl_once f, simpl_once g)
    | Prod (Const 0.0, g) -> Const 0.0
    | Prod (Const 1.0, g) -> simpl_once g
    | Prod (g, Const 0.0) -> Const 0.0
    | Prod (g, Const 1.0) -> simpl_once g
    | Prod(f, g) -> Prod (simpl_once f, simpl_once g)
    | Quot(f, g) -> Quot (simpl_once f, simpl_once g)

let simplify ex =
  fixpoint simpl_once ex

(* Trees with holes *)
type ('a, 'b) choice = Left of 'a | Right of 'b

type btree = Tip | Node of btree * int * btree

type btree_dir = LeftBranch | RightBranch
type btree_deriv =
  | Here of btree * btree
  | Below of btree_dir * int * btree * btree_deriv

let rec btree_integr n t =
  match t with
    | Here(left,right) -> Node(left,n,right)
    | Below(LeftBranch,m,right,left) ->  Node((btree_integr n left), m, right)
    | Below(RightBranch,m,left,right) ->
      Node(left,m,(btree_integr n right))

let rec find_box p t =
  match t with
    | Tip -> None

    | Node (left, n, right) when p n ->
      Some (Here (left, right))

    | Node (left, n, right) ->
      let is_on_left = find_box p left in
      match is_on_left with
        | Some on_left ->
          Some (Below (LeftBranch, n, right, on_left))

        | None ->
          let is_on_right = find_box p right in
          match is_on_right with
            | Some on_right ->
              Some (Below (RightBranch, n, left, on_right))
            | None -> None
