module ParseM =
  Parsec.ParseOps (Monad.LListM) (Parsec.ParseT (Monad.LListM))
open ParseM

let grammar_rules : (int monad -> int monad) list ref = ref []

let get_language () : int monad =
  let rec result =
    lazy
      (List.fold_left
         (fun acc lang -> acc <|> lazy (lang (Lazy.force result)))
          mzero !grammar_rules) in
  perform r <-- Lazy.force result; end_of_text; return r
