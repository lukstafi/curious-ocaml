(* Chapter 7 prelude - Lazy evaluation utilities *)

(* Basic utility functions *)
let flip f x y = f y x
let uncurry f (x, y) = f x y
let curry f x y = f (x, y)
let id x = x

(* Composition operators *)
let (-|) f g x = f (g x)
let (|-) f g x = g (f x)

(* Stream type for call-by-name *)
type 'a stream = SNil | SCons of 'a * (unit -> 'a stream)

let rec stake n = function
  | SCons (a, s) when n > 0 -> a :: (stake (n-1) (s ()))
  | _ -> []

let rec s_ones = SCons (1, fun () -> s_ones)

let rec s_from n = SCons (n, fun () -> s_from (n+1))

let rec smap f = function
  | SNil -> SNil
  | SCons (a, s) -> SCons (f a, fun () -> smap f (s ()))

let rec szip = function
  | SNil, SNil -> SNil
  | SCons (a1, s1), SCons (a2, s2) ->
      SCons ((a1, a2), fun () -> szip (s1 (), s2 ()))
  | _ -> raise (Invalid_argument "szip")

(* Lazy list type *)
type 'a llist = LNil | LCons of 'a * 'a llist Lazy.t

let rec ltake n = function
  | LCons (a, lazy l) when n > 0 -> a :: (ltake (n-1) l)
  | _ -> []

let rec l_ones = LCons (1, lazy l_ones)

let rec l_from n = LCons (n, lazy (l_from (n+1)))

let rec lzip = function
  | LNil, LNil -> LNil
  | LCons (a1, ll1), LCons (a2, ll2) ->
      LCons ((a1, a2), lazy (
        lzip (Lazy.force ll1, Lazy.force ll2)))
  | _ -> raise (Invalid_argument "lzip")

let rec lmap f = function
  | LNil -> LNil
  | LCons (a, ll) ->
    LCons (f a, lazy (lmap f (Lazy.force ll)))

let posnums = l_from 1

let rec lfact =
  LCons (1, lazy (lmap (fun (a,b) -> a*b)
    (lzip (lfact, posnums))))

(* Lazy list fold *)
let rec lazy_foldr f l base =
  match l with
  | LNil -> base
  | LCons (x, lazy xs) -> f x (lazy (lazy_foldr f xs base))

(* Float-based lazy lists for power series *)
let rec l_from_f n = LCons (n, lazy (l_from_f (n +. 1.)))

let posnums_f = l_from_f 1.

(* Numeric conversions *)
let of_int = float_of_int
let to_int = int_of_float

(* Power series operations *)
let rec add xs ys =
  match xs, ys with
    | LNil, _ -> ys
    | _, LNil -> xs
    | LCons (x,xs), LCons (y,ys) ->
      LCons (x +. y, lazy (add (Lazy.force xs) (Lazy.force ys)))

let rec sub xs ys =
  match xs, ys with
    | LNil, _ -> lmap (fun x -> -.x) ys
    | _, LNil -> xs
    | LCons (x,xs), LCons (y,ys) ->
      LCons (x -. y, lazy (sub (Lazy.force xs) (Lazy.force ys)))

let scale s = lmap (fun x -> s *. x)

let rec shift n xs =
  if n = 0 then xs
  else if n > 0 then LCons (0., lazy (shift (n-1) xs))
  else match xs with
    | LNil -> LNil
    | LCons (0., lazy xs) -> shift (n+1) xs
    | _ -> failwith "shift: fractional division"

let rec mul xs = function
  | LNil -> LNil
  | LCons (y, ys) ->
    add (scale y xs) (LCons (0., lazy (mul xs (Lazy.force ys))))

let rec div xs ys =
  match xs, ys with
  | LNil, _ -> LNil
  | LCons (0., xs'), LCons (0., ys') ->
    div (Lazy.force xs') (Lazy.force ys')
  | LCons (x, xs'), LCons (y, ys') ->
    let q = x /. y in
    LCons (q, lazy (div (sub (Lazy.force xs')
                                 (scale q (Lazy.force ys'))) ys))
  | LCons _, LNil -> failwith "div: division by zero"

let integrate c xs =
  LCons (c, lazy (lmap (uncurry (/.)) (lzip (xs, posnums_f))))

let ltail = function
  | LNil -> invalid_arg "ltail"
  | LCons (_, lazy tl) -> tl

let differentiate xs =
  lmap (uncurry ( *.)) (lzip (ltail xs, posnums_f))

(* Unary negation for series *)
let (~-:) = lmap (fun x -> -.x)

(* Inlined integration for recursive definitions *)
let integ xs = lmap (uncurry (/.)) (lzip (xs, posnums_f))

(* Horner method for evaluating power series *)
let rec lhorner x = function
  | LNil -> 0.
  | LCons (c, lazy cs) ->
    let t = lhorner x cs in
    if t = 0. && c = 0. then 0.
    else c +. x *. t

(* Infinite precision Horner *)
let infhorner x l =
  let upd c sum =
    LCons (c, lazy (lmap (fun apx -> c +. x *. apx)
                      (Lazy.force sum))) in
  lazy_foldr upd l (LCons (of_int 0, lazy LNil))

(* Find convergence *)
let rec exact f = function
  | LNil -> assert false
  | LCons (x0, lazy (LCons (x1, lazy (LCons (x2, _)))))
    when f x0 = f x1 && f x1 = f x2 -> f x1
  | LCons (_, lazy xs) -> exact f xs

let eval = exact id

(* Scalar operations on series *)
let ( +:) = add
let ( -:) = sub
let ( *:) = mul
let ( /:) = div
let ( *:.) s xs = scale s xs
