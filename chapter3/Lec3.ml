let rec power f n =
  if n <= 0 then (fun x -> x) else f -| power f (n-1)
(*
let add n = power ((+) 1) n;;
add 5 7;;
let mult k n = power ((+) k) n 0;;
mult 3 7;;

let derivative dx f = function x -> (f(x +. dx) -. f(x)) /. dx

let pi = 4.0 *. atan 1.0
let sin''' = (power (derivative 1e-5) 3) sin;;
sin''' pi;;

let rec depth tree k = match tree with
    | Tip -> k 0
    | Node(_,left,right) ->
      depth left (fun dleft ->
        depth right (fun dright ->
          k (1 + (max dleft dright))))

let depth tree = depth tree (fun d -> d)
*)

type expression =
     Const of float
   | Var of string
   | Sum of expression * expression    (* e1 + e2 *)
   | Diff of expression * expression   (* e1 - e2 *)
   | Prod of expression * expression   (* e1 * e2 *)
   | Quot of expression * expression   (* e1 / e2 *)

exception Unbound_variable of string

let rec eval env exp =
   match exp with
     Const c -> c
   | Var v ->
       (try List.assoc v env with Not_found -> raise(Unbound_variable v))
   | Sum(f, g) -> eval env f +. eval env g
   | Diff(f, g) -> eval env f -. eval env g
   | Prod(f, g) -> eval env f *. eval env g
   | Quot(f, g) -> eval env f /. eval env g

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

let env = ["x", 1.0; "y", 2.0]
let rec eval_1_2 exp =
   match exp with
     Const c -> c
   | Var v ->
       (try List.assoc v env with Not_found -> raise(Unbound_variable v))
   | Sum(f, g) -> eval_1_2 f +. eval_1_2 g
   | Diff(f, g) -> eval_1_2 f -. eval_1_2 g
   | Prod(f, g) -> eval_1_2 f *. eval_1_2 g
   | Quot(f, g) -> eval_1_2 f /. eval_1_2 g
(* *)
  #trace eval_1_2;;
eval_1_2 (!:3.0 *: x +: !:2.0 *: y +: x *: x *: y);;

let rec count n =
  if n <= 0 then 0 else 1 + (count (n-1));;
count 100000;;
count 1000000;;
let rec count_tcall acc n =
  if n <= 0 then acc else count_tcall (acc+1) (n-1);;
count_tcall 1000000;;

let rec unfold n = if n <= 0 then [] else n :: unfold (n-1);;
unfold 100000;;
unfold 1000000;;
let rec unfold_tcall acc n =
  if n <= 0 then acc else unfold_tcall (n::acc) (n-1);;
unfold_tcall [] 100000;;
unfold_tcall [] 1000000;;
*)
