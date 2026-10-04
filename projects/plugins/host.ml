open Plugin_api
type term += Alien
let fails predicate f = try ignore (f ()); false with exn -> predicate exn
let () =
  let filename = Sys.argv.(1) in
  assert (fails (function Unknown_form "neg" -> true | _ -> false)
    (fun () -> parse "(neg 3)"));
  assert (fails (function Missing_operation _ -> true | _ -> false)
    (fun () -> eval [] Alien));
  assert (fails (function Dynlink.Error _ -> true | _ -> false)
    (fun () -> Dynlink.loadfile (filename ^ ".missing")));
  Dynlink.loadfile filename;
  let term = parse "(+ 2 (neg (let x 3 (* x 4))))" in
  assert (eval [] term = -10.);
  assert (eval [] (parse (print term)) = -10.);
  assert (fails (function Expressions.Sexp.Parse_error _ -> true | _ -> false)
    (fun () -> parse "(neg 1 2)"));
  assert (fails (function Dynlink.Error _ -> true | _ -> false)
    (fun () -> Dynlink.loadfile filename));
  let extension = {name="neg"; arity=0; build=(fun _ -> Number 0.);
    evaluate=(fun _ _ -> None); print=(fun _ _ -> None)} in
  assert (fails (function Invalid_argument _ -> true | _ -> false)
    (fun () -> register extension));
  let expression = Expressions.Expr.Let ("x", Number 3.,
    Binary (Add, Variable "x", Number 4.)) in
  assert (eval [] (of_closed expression) = Expressions.Expr.eval [] expression)
