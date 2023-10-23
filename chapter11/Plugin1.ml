open PluginBase.ParseM
let digit_of_char d = int_of_char d - int_of_char '0'

let number _ =
  let rec num =
    lazy (  (perform
                d <-- digit;
                (n, b) <-- Lazy.force num;
                return (digit_of_char d * b + n, b * 10))
      <|> lazy (digit >>= (fun d -> return (digit_of_char d, 10)))) in
  Lazy.force num >>| fst

let addition lang =
  perform
    literal "("; n1 <-- lang; literal "+"; n2 <-- lang; literal ")";
    return (n1 + n2)

let () =
  PluginBase.(grammar_rules := number :: addition :: !grammar_rules)
