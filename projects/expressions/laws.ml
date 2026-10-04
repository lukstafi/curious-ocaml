open Expressions.Expr

let same_float a b = Int64.bits_of_float a = Int64.bits_of_float b || (Float.is_nan a && Float.is_nan b)
let outcome f = try Ok (f ()) with Unbound x -> Error x
let same_outcome a b = match a, b with
  | Ok x, Ok y -> same_float x y
  | Error x, Error y -> x = y
  | _ -> false

let check e =
  let env = ["x", 3.; "y", -2.] in
  let expected = outcome (fun () -> eval env e) in
  List.iter (fun interpret ->
    assert (same_outcome expected (outcome (fun () -> interpret e))))
    [ (fun e -> eval_cps env e Fun.id);
      eval_machine env; (fun e -> eval_fold e env);
      (fun e -> eval env (simplify e)) ];
  assert (fold rebuild e = e)

let () =
  let atoms = [Number (-0.); Number 0.; Number 1.; Number (-2.); Variable "x";
               Variable "y"; Variable "missing"] in
  List.iter check atoms;
  List.iter (fun a -> List.iter (fun b ->
    List.iter (fun op -> check (Binary (op, a, b))) [Add; Sub; Mul; Div];
    check (Let ("x", a, b))) atoms) atoms;
  let random = Random.State.make [|2026; 3|] in
  let rec generate depth =
    if depth = 0 then List.nth atoms (Random.State.int random (List.length atoms))
    else match Random.State.int random 4 with
      | 0 -> Let ("x", generate (depth - 1), generate (depth - 1))
      | 1 -> Let ("y", generate (depth - 1), generate (depth - 1))
      | _ -> Binary (List.nth [Add; Sub; Mul; Div] (Random.State.int random 4),
                     generate (depth - 1), generate (depth - 1)) in
  for _ = 1 to 500 do check (generate 4) done;
  let capture = Let ("y", Number 1., Binary (Add, Variable "x", Variable "y")) in
  let replaced = subst "x" (Variable "y") capture in
  assert (eval ["y", 10.] replaced = 11.);
  assert (Names.elements (free replaced) = ["y"]);
  let shadow = Let ("x", Variable "x", Variable "x") in
  assert (eval [] (subst "x" (Number 7.) shadow) = 7.);
  let nested = Let ("y", Number 1., Let ("y'", Number 2., Variable "x")) in
  assert (eval ["y", 9.] (subst "x" (Variable "y") nested) = 9.);
  (* Evaluation order is observable when both branches are unbound. *)
  assert (outcome (fun () -> eval_machine []
    (Binary (Add, Variable "left", Variable "right"))) = Error "left");
  (* The machine and CPS handle a deep input without a growing call stack. *)
  let rec deep n e = if n = 0 then e else
    deep (n - 1) (Binary (Add, e, Number 1.)) in
  let e = deep 100_000 (Number 0.) in
  assert (eval_machine [] e = 100_000.);
  assert (eval_cps [] e Fun.id = 100_000.)
