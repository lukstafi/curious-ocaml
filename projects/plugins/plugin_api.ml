open Expressions

type term = ..
type term +=
  | Number of float
  | Variable of string
  | Binary of Expr.op * term * term
  | Let of string * term * term

type extension = {
  name : string;
  arity : int;
  build : term list -> term;
  evaluate : (term -> float) -> term -> float option;
  print : (term -> string) -> term -> string option;
}
exception Unknown_form of string
exception Missing_operation of string
let extensions = ref []
let register extension =
  if extension.arity < 0 || List.mem extension.name ["let";"+";"-";"*";"/"] ||
     List.exists (fun e -> e.name=extension.name) !extensions then
    invalid_arg "duplicate or reserved extension";
  extensions := !extensions @ [extension]
let rec eval env = function
  | Number n -> n
  | Variable x -> Expr.lookup env x
  | Binary (op,a,b) -> let x=eval env a in let y=eval env b in Expr.apply op x y
  | Let (x,value,body) -> let value=eval env value in eval ((x,value)::env) body
  | term -> match List.find_map (fun e -> e.evaluate (eval env) term) !extensions with
    | Some value -> value | None -> raise (Missing_operation "evaluation")
let rec print = function
  | Number n -> Printf.sprintf "%.17g" n
  | Variable x -> x
  | Binary (op,a,b) ->
    let name = match op with Expr.Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" in
    Printf.sprintf "(%s %s %s)" name (print a) (print b)
  | Let (x,value,body) -> Printf.sprintf "(let %s %s %s)" x (print value) (print body)
  | term -> match List.find_map (fun e -> e.print print term) !extensions with
    | Some value -> value | None -> raise (Missing_operation "printing")
let rec of_sexp = function
  | Sexp.Atom atom ->
    (match Parser.of_sexp (Sexp.Atom atom) with
     | Expr.Number n -> Number n | Expr.Variable x -> Variable x | _ -> assert false)
  | Sexp.Form ("let", [Atom x;value;body]) when Parser.identifier x ->
    Let (x, of_sexp value, of_sexp body)
  | Sexp.Form (("+"|"-"|"*"|"/" as name), [a;b]) ->
    let op = match name with "+" -> Expr.Add | "-" -> Sub | "*" -> Mul | _ -> Div in
    Binary (op, of_sexp a, of_sexp b)
  | Sexp.Form (name,args) ->
    (match List.find_opt (fun e -> e.name=name) !extensions with
     | None -> raise (Unknown_form name)
     | Some e when List.length args <> e.arity ->
       raise (Sexp.Parse_error "wrong extension arity")
     | Some e -> e.build (List.map of_sexp args))
let parse text = match Sexp.parse text with
  | Error error -> raise (Sexp.Parse_error error)
  | Ok syntax -> of_sexp syntax
let of_closed = Expr.fold {
  number=(fun n -> Number n); variable=(fun x -> Variable x);
  binary=(fun op a b -> Binary (op,a,b));
  binding=(fun x value body -> Let (x,value,body));
}
