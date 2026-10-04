open Expressions
let () =
  let text = "(let x 3 (+ (* x 4) 2))" in
  let expression = match Parser.parse text with Ok e -> e | Error e -> failwith e in
  assert (Expr.eval [] expression = 14.);
  assert (Parser.parse (Parser.print expression) = Ok expression);
  List.iter (fun text -> assert (Result.is_error (Parser.parse text)))
    [""; "("; "()"; "(+ 1)"; "(+ 1 2 3)"; "1 2"; "(+ 1 2))";
     "(let 3 1 2)"; "(unknown 1)"; "(let nan 1 nan)"; "nan"; "infinity"];
  let rng = Random.State.make [|11;2026|] in
  let rec generate n =
    if n=0 then Expr.Number (Random.State.float rng 100. -. 50.) else
    Expr.Binary (Expr.Add, generate (n-1), generate (n-1)) in
  for _ = 1 to 100 do
    let e = generate 3 in assert (Parser.parse (Parser.print e) = Ok e)
  done
