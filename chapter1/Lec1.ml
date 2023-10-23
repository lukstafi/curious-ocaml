(* Assume that we execute the following assignment statements: *)
let width = 17;;
let height = 12.0;;
let delimiter = '.';;
(* For each of the following expressions, write the value of the
   expression and the type (of the value of the expression). *)
width/2;;
width/.2.0;;
height/3;;
1 + 2 * 5;;
delimiter * 5;;

(* A palindrome is a word that is spelled the same backward and
   forward, like “noon” and “redivider”. Recursively, a word is a
   palindrome if the first and last letters are the same and the middle
   is a palindrome.  The following are functions that take a string
   argument and return the first, last, and middle letters: *)
let first_char word = word.[0];;
let last_char word =
  let len = String.length word - 1 in
  word.[len];;
let middle word =
  let len = String.length word - 2 in
  String.sub word 1 len;;

middle "";;

let rec pal word =
  String.length word <= 2
  || (first_char word = last_char word
     && pal (middle word)  )


let (+:) a b = String.concat " " [a; b];;
"Alpha" +: "Beta";;

let f b c d =
  match b with
    | true -> c
    | false -> d
      
;;

let f b c d =
  if b then c else d;;

let f n =
  if n < 0 then `Negative
  else if n = 0 then `Zero
  else if n < 10 then `A_couple
  else if n < 100 then `Small n
  else if n < 1000 then `Large n
  else `Huge (n, n mod 1000)
      
