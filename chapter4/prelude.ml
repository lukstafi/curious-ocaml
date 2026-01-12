let (-|) f g x = f (g x)
let (|-) f g x = g (f x)
let id x = x
let rec fix f x = f (fix f) x
