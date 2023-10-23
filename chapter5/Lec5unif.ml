type term = V of string | T of string * term list
type subst = (string * term) list
apply : subst -> term -> term
V("x") T("f", [V("x"); V("y")])
