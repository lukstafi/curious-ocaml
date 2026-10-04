(* Illustration data comes from the maintained teaching implementations. *)
open Expressions.Expr
let op = function Add -> "Add" | Sub -> "Sub" | Mul -> "Mul" | Div -> "Div"
let symbol = function Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"
let rec expression = function
  | Number n -> Printf.sprintf "%g" n
  | Variable x -> x
  | Binary (o,a,b) -> Printf.sprintf "(%s %s %s)" (expression a) (symbol o) (expression b)
  | Let _ -> invalid_arg "the illustration uses only closed arithmetic"
let frame = function
  | Right (o,e,[]) -> Printf.sprintf "Right(%s, %s, [])" (op o) (expression e)
  | Combine (o,n) -> Printf.sprintf "Combine(%s, %g)" (op o) n
  | _ -> invalid_arg "unexpected illustrated environment or binder"
let string s = Printf.sprintf "%S" s (* These labels are ASCII. *)
let list render xs = "[" ^ String.concat "," (List.map render xs) ^ "]"
let pair (x,y) = Printf.sprintf "[%d,%d]" x y
let event = function Game.Paddle -> "Paddle" | Wall -> "Wall" | Ceiling -> "Ceiling" | Miss -> "Miss"
let () =
  let e = Binary (Mul, Binary (Add, Number 2., Number 3.), Number 4.) in
  let rec steps state =
    let mode,value,stack = match state with
      | Eval (e,[],stack) -> "Eval",expression e,stack
      | Return (n,stack) -> "Return",Printf.sprintf "%g" n,stack
      | _ -> assert false in
    let row = Printf.sprintf "{\"mode\":%s,\"value\":%s,\"stack\":%s}"
      (string mode) (string value) (list (fun f -> string (frame f)) stack) in
    match state with Return (_,[]) -> [row] | _ -> row :: steps (step state) in
  let search = Search.pairs 4 in
  let first = match Search.first search with None -> "null" | Some p -> pair p in
  let trace = Game.through_stream Game.recorded in
  assert (trace = Game.through_incremental Game.recorded);
  assert (trace = Game.through_effects Game.recorded);
  Printf.printf "{\n\"machine\":%s,\n\"search\":{\"all\":%s,\"first\":%s,\"count\":%d},\n\"game\":%s\n}\n"
    (list Fun.id (steps (Eval (e,[],[]))))
    (list pair (Search.all search)) first (Search.count search)
    (list (fun (s,events) -> Printf.sprintf
      "{\"tick\":%d,\"x\":%d,\"y\":%d,\"paddle\":%d,\"events\":%s}"
      s.Game.tick s.x s.y s.paddle (list (fun e -> string (event e)) events)) trace)
