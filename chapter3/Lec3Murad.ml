type 'a btree = Node of 'a btree * 'a * 'a btree | Tip

let test = Node (Node (Node (Tip, 4, Tip), 2, Tip), 1,
                 Node (Node (Tip, 5, Tip), 3, Tip))

let rec prefix = function
  | Tip -> []
  | Node(l,x,r) ->x::prefix l @ prefix r

let rec infix = function
  | Tip -> []
  | Node(l,x,r) -> infix l  @ x::infix r

let rec bfs q = match q with
  | [] -> []
  | Tip ::q' -> bfs q'
  | Node(l,x,r)::q' ->
         x::bfs(q'@[l;r])

type expression =
     Const of float
   | Var of string
   | Sum of expression * expression    (* e1 + e2 *)
   | Diff of expression * expression   (* e1 - e2 *)
   | Prod of expression * expression   (* e1 * e2 *)
   | Quot of expression * expression   (* e1 / e2 *)

let rec deriv exp dv =
   match exp with
     Const c -> Const 0.0
   | Var v -> if v = dv then Const 1.0 else Const 0.0
   | Sum(f, g) -> Sum(deriv f dv, deriv g dv)
   | Diff(f, g) -> Diff(deriv f dv, deriv g dv)
   | Prod(f, g) -> Sum(Prod(f, deriv g dv), Prod(deriv f dv, g))
   | Quot(f, g) -> Quot(Diff(Prod(deriv f dv, g), Prod(f, deriv g dv)),
                        Prod(g, g))


let x = Var "x"
let y = Var "y"
let z = Var "z"
let (+:) f g = Sum (f, g)
let (-:) f g = Diff (f, g)
let ( *: ) f g = Prod (f, g)
let (/:) f g = Quot (f, g)
let (!:) i = Const i

let example = !:3.0 *: x +: !:2.0 *: y +: x *: x *: y

let print_expr ppf exp =
  (* Local function definitions *)
  let open_paren prec op_prec =
    if prec > op_prec then Format.fprintf ppf "(@["
    else Format.fprintf ppf "@[" in
  let close_paren prec op_prec =
    if prec > op_prec then Format.fprintf ppf "@])"
    else Format.fprintf ppf "@]" in
  let rec print prec exp =     (* prec is the current precedence *)
    match exp with
        Const c -> Format.fprintf ppf "%.2f" c
      | Var v -> Format.print_string v
      | Sum(f, g) ->
        open_paren prec 0;
        print 0 f; Format.fprintf ppf "@ +@ "; print 0 g;
        close_paren prec 0
      | Diff(f, g) ->
        open_paren prec 0;
        print 0 f; Format.fprintf ppf "@ -@ "; print 1 g;
        close_paren prec 0
      | Prod(f, g) ->
        open_paren prec 2;
        print 2 f; Format.fprintf ppf "@ *@ "; print 2 g;
        close_paren prec 2
      | Quot(f, g) ->
        open_paren prec 2;
        print 2 f; Format.fprintf ppf "@ /@ "; print 3 g;
        close_paren prec 2
  in print 0 exp
;;
#install_printer print_expr;;
example;;
deriv example "x";;

let rec fixpoint f x =
  let x' = f x in
  if x' = x then x
  else fixpoint f x'

let rec simpl = function
  | Const c -> Const c
  | Var v -> Var v
  | Sum(Const 0.,g) -> g
  | Sum(f,Const 0.) -> f
  | Sum(f,g) when f = g -> Prod(Const 2.,f)
  | Sum(f,g) -> Sum(simpl f,simpl g)
  | Diff(f, g) ->Diff(simpl f,simpl g)
  | Prod(Const 0.,g) -> Const 0.
  | Prod(f,Const 0.) -> Const 0.
  | Prod(Const 1., g) -> g
  | Prod(f,Const 1.) -> f
  | Prod(f, g) -> Prod(simpl f,simpl g)
  | Quot(f, g) -> Quot (simpl f, simpl g)

let simplify x = fixpoint simpl x
