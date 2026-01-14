(* Chapter 7 prelude - minimal utilities *)

(* Basic utility functions *)
let flip f x y = f y x
let uncurry f (x, y) = f x y
let id x = x

(* Numeric conversions *)
let of_int = float_of_int
let to_int = int_of_float
