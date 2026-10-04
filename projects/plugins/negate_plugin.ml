open Plugin_api
type term += Negate of term
let () = register {
  name="neg"; arity=1;
  build=(function [term] -> Negate term | _ -> invalid_arg "neg arity");
  evaluate=(fun recur -> function Negate term -> Some (-. recur term) | _ -> None);
  print=(fun recur -> function Negate term -> Some ("(neg " ^ recur term ^ ")") | _ -> None);
}
