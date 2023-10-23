let width = 17
let height = 12.0
let delim = '.'
let pi = atan 1.0 *. 4.
let r = 5.0

let rec fib x = match x with 
  | _ when x <= 0 -> 1
  | 1 -> 1
  | _ -> fib (x-1) + fib (x-2)    

type r = {a : int}
