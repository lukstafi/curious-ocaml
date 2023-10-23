
let rec insert x = function
  | [] -> [[x]]
  | y::ys as xs -> (x::xs) :: List.map (fun xys -> y::xys) (insert x ys)

let rec perm l =
  match l with
    | [] -> [[]]
    | x::xs ->
      concat_map (insert x) (perm xs)

let rec choices l =
  match l with
    | [] -> [[]]
    | x::xs ->
      let cxs = choices xs in
      List.rev_append cxs (concat_map (insert x) cxs)


let test_choices = choices (from_to 1 2)
let test_choices = choices (from_to 1 4)


let degree = {
  fold_const = (fun c -> 0);
  fold_var = (fun x -> 1);
  fold_sum = (fun a b -> max a b);
  fold_diff = (fun a b -> max a b);
  fold_prod = (fun a b -> a + b);
  fold_quot = (fun a b -> a - b);
}
let degree e = expr_fold degree e

let simplify = {identity_map with
  map_sum = (fun a b -> match a,b with
  | Const a, Const b -> Const (a +. b)
  | Const 0., a | a, Const 0. -> a
  | _ when a = b -> Prod (Const 2., a)
  | _ ->Sum (a, b));
  map_prod = (fun a b -> match a,b with
  | Const a, Const b -> Const (a *. b)
  | Const 0., a | a, Const 0. -> Const 0.
  | Const 1., a | a, Const 1. -> a
  | _ -> Prod (a, b));
}
let simplify e = expr_map simplify e
