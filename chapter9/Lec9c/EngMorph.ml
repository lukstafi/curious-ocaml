
let wh_or_pronoun w =
  w = "where" || w = "what" || w = "who" ||
  w = "he" || w = "she" || w = "it" ||
  w = "I" || w = "you" || w = "we" || w = "they"

let abridged w1 w2 =
  if w2 = "ll" then [w1; "will"]
  else if w2 = "s" then
    if wh_or_pronoun w1 then [w1; "is"]
    else ["of"; w1]
  else if w2 = "d" then [w1^"ed"]
  else if w1 = "o" || w1 = "O"
  then
    if w2.[0] = 'e' && w2.[1] = 'r' then [w1^"v"^w2]
    else ["of"; w2]
  else if w2 = "t" then [w1; "it"]
  else [w1^"'"^w2]

let normalize s =
  String.lowercase s
