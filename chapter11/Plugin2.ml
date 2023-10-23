open PluginBase.ParseM

let multiplication lang =
  perform
    literal "("; n1 <-- lang; literal "*"; n2 <-- lang; literal ")";
    return (n1 * n2)

let () =
  PluginBase.(grammar_rules := multiplication :: !grammar_rules)
