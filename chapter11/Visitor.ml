type 'visitor visitable = < accept : 'visitor -> unit >

type var_name = string

class ['visitor] var (v : var_name) =
object (self)
  method v = v
  method accept : 'visitor -> unit =
    fun visitor -> visitor#visitVar self
end
let new_var v = (new var v :> 'a visitable)

class ['visitor] abs (v : var_name) (body : 'visitor visitable) =
object (self)
  method v = v
  method body = body
  method accept : 'visitor -> unit =
    fun visitor -> visitor#visitAbs self
end
let new_abs v body = (new abs v body :> 'a visitable)

class ['visitor] app (f : 'visitor visitable) (arg : 'visitor visitable) =
object (self)
  method f = f
  method arg = arg
  method accept : 'visitor -> unit =
    fun visitor -> visitor#visitApp self
end
let new_app f arg = (new app f arg :> 'a visitable)

class virtual ['visitor] lambda_visit =
object
  method virtual visitVar : 'visitor var -> unit
  method virtual visitAbs : 'visitor abs -> unit
  method virtual visitApp : 'visitor app -> unit
end

let gensym = let n = ref 0 in fun () -> incr n; "_" ^ string_of_int !n

class ['visitor] eval_lambda
  (subst : (var_name * 'visitor visitable) list)
  (result : 'visitor visitable ref) =
object (self)
  inherit ['visitor] lambda_visit
  val mutable subst = subst
  val mutable beta_redex : (var_name * 'visitor visitable) option = None
  method visitVar var =
    beta_redex <- None;
    try result := List.assoc var#v subst
    with Not_found -> result := (var :> 'visitor visitable)
  method visitAbs abs =
    let v' = gensym () in
    let orig_subst = subst in
    subst <- (abs#v, new_var v')::subst;
    (abs#body)#accept self;
    let body' = !result in
    subst <- orig_subst;
    beta_redex <- Some (v', body');
    result := new_abs v' body'
  method visitApp app =
    app#arg#accept self;
    let arg' = !result in
    app#f#accept self;
    let f' = !result in
    match beta_redex with
    | Some (v', body') ->
      beta_redex <- None;
      let orig_subst = subst in
      subst <- (v', arg')::subst;
      body'#accept self;
      subst <- orig_subst
    | None -> result := new_app f' arg'
end

class ['visitor] freevars_lambda (result : var_name list ref) =
object (self)
  inherit ['visitor] lambda_visit
  method visitVar var =
    result := var#v :: !result
  method visitAbs abs =
    (abs#body)#accept self;
    result := List.filter (fun v' -> v' <> abs#v) !result
  method visitApp app =
    app#arg#accept self; app#f#accept self
end

type lambda_visit_t = lambda_visit_t lambda_visit
type lambda_t = lambda_visit_t visitable

let eval1 (e : lambda_t) subst : lambda_t =
  let result = ref (new_var "") in
  e#accept (new eval_lambda subst result :> lambda_visit_t);
  !result

let freevars1 (e : lambda_t) =
  let result = ref [] in
  e#accept (new freevars_lambda result);
  !result

let test1 =
  (new_app (new_abs "x" (new_var "x")) (new_var "y") :> lambda_t)
let e_test = eval1 test1 []
let fv_test = freevars1 test1

class ['visitor] num (i : int) =
object (self)
  method i = i
  method accept : 'visitor -> unit =
    fun visitor -> visitor#visitNum self
end
let new_num i = (new num i :> 'a visitable)

class virtual ['visitor] operation
  (arg1 : 'visitor visitable) (arg2 : 'visitor visitable) =
object (self)
  method arg1 = arg1
  method arg2 = arg2
end

class ['visitor] add arg1 arg2 =
object (self)
  inherit ['visitor] operation arg1 arg2
  method accept : 'visitor -> unit =
    fun visitor -> visitor#visitAdd self
end
let new_add arg1 arg2 = (new add arg1 arg2 :> 'a visitable)

class ['visitor] mult arg1 arg2 =
object (self)
  inherit ['visitor] operation arg1 arg2
  method accept : 'visitor -> unit =
    fun visitor -> visitor#visitMult self
end
let new_mult arg1 arg2 = (new mult arg1 arg2 :> 'a visitable)

class virtual ['visitor] expr_visit =
object
  method virtual visitNum : 'visitor num -> unit
  method virtual visitAdd : 'visitor add -> unit
  method virtual visitMult : 'visitor mult -> unit
end

class ['visitor] eval_expr
  (result : 'visitor visitable ref) =
object (self)
  inherit ['visitor] expr_visit
  val mutable num_redex : int option = None
  method visitNum num =
    num_redex <- Some num#i;
    result := (num :> 'visitor visitable)
  method private visitOperation new_e op e =
    (e#arg1)#accept self;
    let arg1' = !result and i1 = num_redex in
    (e#arg2)#accept self;
    let arg2' = !result and i2 = num_redex in
    match i1, i2 with
    | Some i1, Some i2 ->
      let res = op i1 i2 in
      num_redex <- Some res; result := new_num res
    | _ ->
      num_redex <- None;
      result := new_e arg1' arg2'
  method visitAdd add = self#visitOperation new_add ( + ) add
  method visitMult mult = self#visitOperation new_mult ( * ) mult
end

class ['visitor] freevars_expr (result : var_name list ref) =
object (self)
  inherit ['visitor] expr_visit
  method visitNum _ = ()
  method visitAdd add =
    add#arg1#accept self; add#arg2#accept self
  method visitMult mult =
    mult#arg1#accept self; mult#arg2#accept self
end

type expr_visit_t = expr_visit_t expr_visit
type expr_t = expr_visit_t visitable

let eval2 (e : expr_t) : expr_t =
  let result = ref (new_num 0) in
  e#accept (new eval_expr result);
  !result

let test2 =
  (new_add (new_mult (new_num 3) (new_num 3)) (new_num 1) :> expr_t)
let e_test = eval2 test2

class virtual ['visitor] lexpr_visit =
object
  inherit ['visitor] lambda_visit
  inherit ['visitor] expr_visit
end

class ['visitor] eval_lexpr subst result =
object
  inherit ['visitor] eval_expr result
  inherit ['visitor] eval_lambda subst result
end

class ['visitor] freevars_lexpr result =
object
  inherit ['visitor] freevars_expr result
  inherit ['visitor] freevars_lambda result
end

type lexpr_visit_t = lexpr_visit_t lexpr_visit
type lexpr_t = lexpr_visit_t visitable

let eval3 (e : lexpr_t) subst : lexpr_t =
  let result = ref (new_num 0) in
  e#accept (new eval_lexpr subst result);
  !result

let freevars3 (e : lexpr_t) =
  let result = ref [] in
  e#accept (new freevars_lexpr result);
  !result

let test3 =
  (new_add (new_mult (new_num 3) (new_var "x")) (new_num 1) :> lexpr_t)
let e_test = eval3 test3 []
let fv_test = freevars3 test3
let old_e_test = eval3 (test2 :> lexpr_t) []
let old_fv_test = eval3 (test2 :> lexpr_t) []
