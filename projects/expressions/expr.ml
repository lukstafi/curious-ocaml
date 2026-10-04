(* $MDX part-begin=syntax *)
type op = Add | Sub | Mul | Div

type t =
  | Number of float
  | Variable of string
  | Binary of op * t * t
  | Let of string * t * t

exception Unbound of string

let apply op x y =
  match op with
  | Add -> x +. y | Sub -> x -. y
  | Mul -> x *. y | Div -> x /. y

let lookup env x =
  match List.assoc_opt x env with
  | Some v -> v
  | None -> raise (Unbound x)
(* $MDX part-end *)

(* $MDX part-begin=direct *)
let rec eval env = function
  | Number n -> n
  | Variable x -> lookup env x
  | Binary (op, a, b) ->
    let x = eval env a in
    let y = eval env b in
    apply op x y
  | Let (x, value, body) ->
    let v = eval env value in
    eval ((x, v) :: env) body
(* $MDX part-end *)

(* $MDX part-begin=cps *)
let rec eval_cps env e k =
  match e with
  | Number n -> k n
  | Variable x -> k (lookup env x)
  | Binary (op, a, b) ->
    eval_cps env a (fun x ->
      eval_cps env b (fun y -> k (apply op x y)))
  | Let (x, value, body) ->
    eval_cps env value (fun v ->
      eval_cps ((x, v) :: env) body k)
(* $MDX part-end *)

(* $MDX part-begin=machine *)
type frame =
  | Right of op * t * (string * float) list
  | Combine of op * float
  | Bind of string * t * (string * float) list

type state =
  | Eval of t * (string * float) list * frame list
  | Return of float * frame list

let step = function
  | Eval (Number n, _, stack) -> Return (n, stack)
  | Eval (Variable x, env, stack) -> Return (lookup env x, stack)
  | Eval (Binary (op, a, b), env, stack) ->
    Eval (a, env, Right (op, b, env) :: stack)
  | Eval (Let (x, value, body), env, stack) ->
    Eval (value, env, Bind (x, body, env) :: stack)
  | Return (x, Right (op, b, env) :: stack) ->
    Eval (b, env, Combine (op, x) :: stack)
  | Return (y, Combine (op, x) :: stack) ->
    Return (apply op x y, stack)
  | Return (v, Bind (x, body, env) :: stack) ->
    Eval (body, (x, v) :: env, stack)
  | Return (_, []) as final -> final

let rec run = function
  | Return (v, []) -> v
  | state -> run (step state)

let eval_machine env e = run (Eval (e, env, []))
(* $MDX part-end *)

(* $MDX part-begin=fold *)
type 'a algebra = {
  number : float -> 'a;
  variable : string -> 'a;
  binary : op -> 'a -> 'a -> 'a;
  binding : string -> 'a -> 'a -> 'a;
}

let rec fold alg = function
  | Number n -> alg.number n
  | Variable x -> alg.variable x
  | Binary (op, a, b) ->
    let a' = fold alg a in
    let b' = fold alg b in
    alg.binary op a' b'
  | Let (x, value, body) ->
    let value' = fold alg value in
    let body' = fold alg body in
    alg.binding x value' body'

let rebuild = {
  number = (fun n -> Number n);
  variable = (fun x -> Variable x);
  binary = (fun op a b -> Binary (op, a, b));
  binding = (fun x value body -> Let (x, value, body));
}

let size = fold {
  number = (fun _ -> 1); variable = (fun _ -> 1);
  binary = (fun _ a b -> 1 + a + b);
  binding = (fun _ value body -> 1 + value + body);
}

let eval_fold = fold {
  number = (fun n _env -> n);
  variable = (fun x env -> lookup env x);
  binary = (fun op a b env ->
    let x = a env in let y = b env in apply op x y);
  binding = (fun x value body env ->
    let v = value env in body ((x, v) :: env));
}
(* $MDX part-end *)

(* $MDX part-begin=binding *)
module Names = Set.Make (String)

let rec free = function
  | Number _ -> Names.empty
  | Variable x -> Names.singleton x
  | Binary (_, a, b) -> Names.union (free a) (free b)
  | Let (x, value, body) ->
    Names.union (free value) (Names.remove x (free body))

let rec names = function
  | Number _ -> Names.empty
  | Variable x -> Names.singleton x
  | Binary (_, a, b) -> Names.union (names a) (names b)
  | Let (x, value, body) ->
    Names.add x (Names.union (names value) (names body))

let fresh used x =
  let rec loop x = if Names.mem x used then loop (x ^ "'") else x in
  loop x

let rec subst x replacement = function
  | Number _ as e -> e
  | Variable y as e -> if x = y then replacement else e
  | Binary (op, a, b) ->
    Binary (op, subst x replacement a, subst x replacement b)
  | Let (y, value, body) ->
    let value' = subst x replacement value in
    if x = y then Let (y, value', body)
    else if not (Names.mem y (free replacement)) then
      Let (y, value', subst x replacement body)
    else
      let used = Names.add x (Names.union (names body) (names replacement)) in
      let z = fresh used y in
      let renamed = subst y (Variable z) body in
      Let (z, value', subst x replacement renamed)
(* $MDX part-end *)

(* $MDX part-begin=simplify *)
let simplify = fold {
  rebuild with binary = (fun op a b ->
    match a, b with
    | Number x, Number y -> Number (apply op x y)
    | _ -> Binary (op, a, b));
}
(* $MDX part-end *)
