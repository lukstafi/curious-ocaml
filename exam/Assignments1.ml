let rec gcd a b =
  if a = 0  then b
  else if b = 0 then a
  else if a > b then gcd b (a mod b) 
  else               gcd a (b mod a)

  
let foo ~bar =
  bar * 2;;
