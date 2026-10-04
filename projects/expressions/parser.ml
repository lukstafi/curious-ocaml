let identifier s =
  let alpha = function 'a'..'z' | 'A'..'Z' | '_' -> true | _ -> false in
  let rest c = alpha c || match c with '0'..'9' | '\'' -> true | _ -> false in
  String.length s > 0 && alpha s.[0] && String.for_all rest s &&
  not (List.mem s ["nan";"infinity";"neg_infinity"])
let rec of_sexp = function
  | Sexp.Atom token ->
    (match float_of_string_opt token with
     | Some value when Float.is_finite value -> Expr.Number value
     | _ when identifier token && not (List.mem token ["nan";"infinity";"neg_infinity"]) ->
       Expr.Variable token
     | _ -> raise (Sexp.Parse_error "expected finite number or identifier"))
  | Sexp.Form ("let", [Atom x; value; body]) when identifier x ->
    Expr.Let (x, of_sexp value, of_sexp body)
  | Sexp.Form (("+" | "-" | "*" | "/" as name), [a;b]) ->
    let op = match name with "+" -> Expr.Add | "-" -> Sub | "*" -> Mul | _ -> Div in
    Expr.Binary (op, of_sexp a, of_sexp b)
  | _ -> raise (Sexp.Parse_error "unknown form or wrong arity")
let parse text = match Sexp.parse text with
  | Error _ as error -> error
  | Ok syntax -> try Ok (of_sexp syntax) with Sexp.Parse_error message -> Error message
let rec print = function
  | Expr.Number n -> Printf.sprintf "%.17g" n
  | Variable x -> x
  | Binary (op,a,b) ->
    let name = match op with Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" in
    Printf.sprintf "(%s %s %s)" name (print a) (print b)
  | Let (x,value,body) -> Printf.sprintf "(let %s %s %s)" x (print value) (print body)
