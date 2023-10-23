type var = string

let eval_var wrap sub (s : var) =
  try List.assoc s sub with Not_found -> wrap s

type 'a lambda =
  VarL of var | Abs of string * 'a | App of 'a * 'a

let gensym = let n = ref 0 in fun () -> incr n; "_" ^ string_of_int !n

let eval_lambda eval_rec wrap unwrap subst e =
  match unwrap e with
  | Some (VarL v) -> eval_var (fun v -> wrap (VarL v)) subst v
  | Some (App (l1, l2)) ->
    let l1' = eval_rec subst l1
    and l2' = eval_rec subst l2 in
    (match unwrap l1' with
    | Some (Abs (s, body)) ->
      eval_rec [s, l2'] body
    | _ -> wrap (App (l1', l2')))
  | Some (Abs (s, l1)) ->
    let s' = gensym () in
    wrap (Abs (s', eval_rec ((s, wrap (VarL s'))::subst) l1))
  | None -> e

type lambda_t = Lambda_t of lambda_t lambda

let rec eval1 subst =
  eval_lambda eval1
    (fun e -> Lambda_t e) (fun (Lambda_t e) -> Some e) subst

type 'a expr =
  VarE of var | Num of int | Add of 'a * 'a | Mult of 'a * 'a

let eval_expr eval_rec wrap unwrap subst e =
  match unwrap e with
  | Some (Num _) -> e
  | Some (VarE v) ->
    eval_var (fun x -> wrap (VarE x)) subst v
  | Some (Add (m, n)) ->
    let m' = eval_rec subst m
    and n' = eval_rec subst n in
    (match unwrap m', unwrap n' with
    | Some (Num m'), Some (Num n') ->
      wrap (Num (m' + n'))
    | _ -> wrap (Add (m', n')))
  | Some (Mult (m, n)) ->
    let m' = eval_rec subst m
    and n' = eval_rec subst n in
    (match unwrap m', unwrap n' with
    | Some (Num m'), Some (Num n') ->
      wrap (Num (m' * n'))
    | _ -> wrap (Mult (m', n')))
  | None -> e

type expr_t = Expr_t of expr_t expr

let rec eval2 subst =
  eval_expr eval2
    (fun e -> Expr_t e) (fun (Expr_t e) -> Some e) subst

type 'a lexpr =
  Lambda of 'a lambda | Expr of 'a expr

let eval_lexpr eval_rec wrap unwrap subst e =
  eval_lambda eval_rec
    (fun e -> wrap (Lambda e))
    (fun e ->
      match unwrap e with
      | Some (Lambda e) -> Some e
      | _ -> None)
    subst
    (eval_expr eval_rec
       (fun e -> wrap (Expr e))
       (fun e ->
         match unwrap e with
         | Some (Expr e) -> Some e
         | _ -> None)
       subst e)

type lexpr_t = LExpr_t of lexpr_t lexpr

let rec eval3 subst =
  eval_lexpr eval3
    (fun e -> LExpr_t e)
    (fun (LExpr_t e) -> Some e) subst
