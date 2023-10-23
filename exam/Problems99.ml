(* Logic and Codes *)

type bool_expr =
    | Var of string
    | Not of bool_expr
    | And of bool_expr * bool_expr
    | Or of bool_expr * bool_expr

(* Truth tables for logical expressions. *)
let table vars expr =
