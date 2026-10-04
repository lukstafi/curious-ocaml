open Expressions.Lambda
let normalize e = match reduce ~fuel:1000 normal_step e with
  | Done e -> assert (well_scoped e); e
  | Limit _ -> failwith "unexpected reduction limit"
let () =
  let identity = Lam (Bound 0) in
  let self = Lam (App (Bound 0, Bound 0)) in
  let omega = App (self, self) in
  let discard = App (Lam identity, omega) in
  assert (normalize discard = identity);
  assert (match reduce ~fuel:30 value_step discard with Limit _ -> true | _ -> false);
  assert (normalize (App (Lam (Lam (Bound 1)), Free "y")) = Lam (Free "y"));
  let nested = App (Lam (Lam (App (Bound 1, Bound 0))), identity) in
  assert (normalize nested = identity);
  let under_lambda = Lam (App (identity, Bound 0)) in
  assert (normalize under_lambda = identity);
  assert (reduce ~fuel:10 value_step under_lambda = Done under_lambda);
  let church n =
    let rec times n = if n = 0 then Bound 0 else App (Bound 1, times (n-1)) in
    Lam (Lam (times n)) in
  (* lambda m n f x. m f (n f x) *)
  let add = Lam (Lam (Lam (Lam
    (App (App (Bound 3, Bound 1), App (App (Bound 2, Bound 1), Bound 0)))))) in
  assert (normalize (App (App (add, church 2), church 3)) = church 5);
  (* Scott naturals select a case, handing the predecessor to the successor case. *)
  let zero = Lam (Lam (Bound 1)) in
  let succ = Lam (Lam (Lam (App (Bound 0, Bound 2)))) in
  let one = normalize (App (succ, zero)) in
  let predecessor n = App (App (n, zero), identity) in
  assert (normalize (predecessor one) = zero);
  assert (normalize (predecessor zero) = zero)
