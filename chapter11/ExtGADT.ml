(** ExtGADT.ml — Extensible GADTs and the expression problem.

    Key demonstration:
    1. Extensible GADTs provide type-precise constructors: each constructor
       carries a type index that the compiler tracks, unlike plain extensible
       variants where all constructors have type [expr].
    2. However, OCaml cannot check exhaustiveness for extensible GADTs:
       every pattern-match requires a catch-all, giving the same runtime-failure
       risk as plain extensible variants (section 11.3).
    3. The handler-composition pattern allows modular extension of evaluation.

    Compare with ExtV.ml, which uses plain extensible variants (type expr = ..).
*)

(* ===== Part 1: Arithmetic extensible GADT ===== *)

(** An extensible GADT indexed by the type of value it evaluates to.
    Each constructor specifies its result type precisely. *)
type _ expr = ..

(** Arithmetic sub-language.  All constructors produce [int]. *)
type _ expr +=
  | Num : int -> int expr
  | Add : int expr * int expr -> int expr
  | Mul : int expr * int expr -> int expr

(** A typed evaluator for the arithmetic sub-language.
    The [type a.] annotation introduces a locally abstract type, required
    for pattern-matching on a GADT.  The return type [a] is refined by
    each constructor arm: matching [Num n] refines [a] to [int], so [n : int]
    and the return type is [int]. *)
let rec eval_arith : type a. a expr -> a = function
  | Num n -> n
  | Add (e1, e2) -> eval_arith e1 + eval_arith e2
  | Mul (e1, e2) -> eval_arith e1 * eval_arith e2
  | _ -> failwith "eval_arith: unhandled constructor"
  (* ^ OCaml requires this catch-all: because [_ expr] is extensible,
     the compiler cannot verify that all constructors are covered.
     This is the non-solution penalty, identical to plain extensible variants. *)

let test1 : int = eval_arith (Add (Mul (Num 3, Num 4), Num 2))
(* = 3 * 4 + 2 = 14 *)

(* ===== Part 2: Adding boolean expressions ===== *)

(** Boolean sub-language.
    [Gt] crosses the int/bool boundary: its sub-expressions are [int expr]
    but it produces [bool expr].  With plain extensible variants (type expr = ..)
    we would need to pattern-match on [Num _] at runtime to extract the integer;
    with GADTs the types are known at compile time. *)
type _ expr +=
  | Bool : bool -> bool expr
  | And  : bool expr * bool expr -> bool expr
  | Not  : bool expr -> bool expr
  | Gt   : int expr * int expr -> bool expr

let rec eval_bool : type a. a expr -> a = function
  | Bool b -> b
  | And (e1, e2) -> eval_bool e1 && eval_bool e2
  | Not e        -> not (eval_bool e)
  | Gt (e1, e2)  -> eval_arith e1 > eval_arith e2
  (* ^ Here eval_arith is called with e1 : int expr, returning int directly.
     With plain extensible variants this call would be eval_rec e1 : expr,
     and we would have to unsafely coerce or match to get an int. *)
  | _ -> failwith "eval_bool: unhandled constructor"

let test2 : bool = eval_bool (Gt (Add (Num 2, Num 3), Num 4))
(* = (2 + 3) > 4 = true *)

(* ===== Part 3: The non-solution penalty in action ===== *)

(** The key advantage over plain extensible variants: the type index carries
    semantic information that the compiler checks.

    With plain extensible variants (type expr = ..):
      eval_var subst (Var "x")  has type  expr  (all constructors unified)

    With extensible GADTs (type _ expr = ..):
      eval_arith (Add …)  has type  int
      eval_bool  (Gt …)   has type  bool
      The compiler rejects eval_arith (Bool true) at compile time.

    But the same penalty applies: no exhaustiveness checking.
    Adding a new constructor, e.g.

      type _ expr += Str : string -> string expr

    does NOT trigger a warning in eval_arith or eval_bool.  The catch-all
    silently handles it at runtime — and raises an exception. *)

(* ===== Part 4: Handler composition via open recursion ===== *)

(** A composed evaluator is a record with a universally polymorphic [eval]
    field, so a single [eval_chain] value handles expressions of any type. *)
type eval_chain = { eval : 'a. 'a expr -> 'a }

(** A layer handles some constructors and returns [None] for unknown ones.
    It receives the full [eval_chain] so recursive sub-expressions go through
    all registered handlers, not just the current layer. *)
type eval_layer = { layer : 'a. eval_chain -> 'a expr -> 'a option }

let arith_layer = {
  layer = fun (type a) (chain : eval_chain) (e : a expr) : a option ->
    match e with
    | Num n        -> Some n
    | Add (e1, e2) -> Some (chain.eval e1 + chain.eval e2)
    | Mul (e1, e2) -> Some (chain.eval e1 * chain.eval e2)
    | _            -> None }

let bool_layer = {
  layer = fun (type a) (chain : eval_chain) (e : a expr) : a option ->
    match e with
    | Bool b       -> Some b
    | And (e1, e2) -> Some (chain.eval e1 && chain.eval e2)
    | Not e        -> Some (not (chain.eval e))
    | Gt (e1, e2)  -> Some (chain.eval e1 > chain.eval e2)
    (* ^ chain.eval : 'b. 'b expr -> 'b, so chain.eval e1 : int directly *)
    | _            -> None }

(** Build a composed evaluator.  Each layer tries its constructors in order;
    the first [Some] wins.  If no layer matches, raises an exception.

    Uses a mutable reference to tie the open-recursion knot: [chain] points
    to the fully-composed evaluator, so sub-expression calls go through all
    layers even when the initial call is dispatched by an earlier layer. *)
let build_eval (layers : eval_layer list) : eval_chain =
  let chain : eval_chain ref =
    ref { eval = fun _ -> failwith "build_eval: not yet initialised" } in
  let full_eval : type a. a expr -> a = fun e ->
    match List.find_map (fun l -> l.layer !chain e) layers with
    | Some v -> v
    | None   -> failwith "build_eval: no handler for this constructor"
  in
  chain := { eval = full_eval };
  { eval = full_eval }

let combined = build_eval [arith_layer; bool_layer]

let test3 : bool = combined.eval (Gt (Add (Num 2, Num 3), Num 4))
(* = (2 + 3) > 4 = true *)

let test4 : int = combined.eval (Mul (Add (Num 3, Num 4), Num 2))
(* = (3 + 4) * 2 = 14 *)

(** The non-solution verdict: if we add a new constructor and forget to
    register a handler for it, the exception is raised at runtime:

      type _ expr += Str : string -> string expr
      combined.eval (Str "hello")   (* raises Failure "no handler" *)

    This is the same runtime-failure risk as plain extensible variants (11.3),
    but with stronger compile-time type guarantees for the constructors that
    ARE handled.  Polymorphic variants (sections 11.7–11.8) avoid this by
    giving up extensibility in exchange for exhaustiveness checking. *)
