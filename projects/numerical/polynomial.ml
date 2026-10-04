(* Coefficients are listed in increasing powers; [] is the zero polynomial. *)
let trim xs =
  let rec drop = function 0.::xs -> drop xs | xs -> xs in
  List.rev (drop (List.rev xs))
let evaluate x xs = List.fold_right (fun c acc -> c +. x *. acc) xs 0.
let integrate c xs = c :: List.mapi (fun i a -> a /. float_of_int (i+1)) xs
let differentiate = function
  | [] -> [] | _::xs -> List.mapi (fun i a -> float_of_int (i+1) *. a) xs
let finite x = Float.is_finite x
let quotient ~terms numerator denominator =
  if terms < 0 then invalid_arg "negative prefix length";
  if not (List.for_all finite (numerator @ denominator)) then
    invalid_arg "nonfinite coefficient";
  let denominator = trim denominator in
  match denominator with
  | [] -> invalid_arg "zero denominator"
  | 0.::_ -> invalid_arg "constant coefficient must be nonzero"
  | b0::_ ->
    let a = Array.of_list numerator and b = Array.of_list denominator in
    let q = Array.make terms 0. in
    for n = 0 to terms - 1 do
      let acc = ref (if n < Array.length a then a.(n) else 0.) in
      for k = 1 to min n (Array.length b - 1) do
        acc := !acc -. b.(k) *. q.(n-k)
      done;
      q.(n) <- !acc /. b0;
      if not (finite q.(n)) then invalid_arg "nonfinite quotient coefficient"
    done;
    Array.to_list q

(* A fixed finite Taylor polynomial, not a convergence detector. *)
let exp_unit ~degree x =
  if not (finite x) || x < 0. || x > 1. || degree < 0 || degree > 20 then
    invalid_arg "exp_unit: x in [0,1], degree in [0,20]";
  let term = ref 1. and sum = ref 1. in
  for n = 1 to degree do
    term := !term *. x /. float_of_int n;
    sum := !sum +. !term
  done;
  !sum
