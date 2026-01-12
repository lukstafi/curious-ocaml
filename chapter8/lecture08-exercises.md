Exercise 1.

Puzzle via Oleg Kiselyov.

"U2" has a concert that starts in 17 minutes and they must all cross a bridge 
to get there. All four men begin on the same side of the bridge. It is night. 
There is one flashlight. A maximum of two people can cross at one time. Any 
party who crosses, either 1 or 2 people, must have the flashlight with them. 
The flashlight must be walked back and forth, it cannot be thrown, etc.. Each 
band member walks at a different speed. A pair must walk together at the rate 
of the slower man's pace:

* Bono: 1 minute to cross
* Edge: 2 minutes to cross
* Adam: 5 minutes to cross
* Larry: 10 minutes to cross

For example: if Bono and Larry walk across first, 10 minutes have elapsed when 
they get to the other side of the bridge. If Larry then returns with the 
flashlight, a total of 20 minutes have passed and you have failed the mission.

Find all answers to the puzzle using a list comprehension. The comprehension 
will be a bit long but recursion is not needed.



Exercise 2.

Assume `concat_map` as defined in lecture 6. What will the following 
expresions return? Why?

1. perform with (|->) in  return 5;  return 7
1. let guard p = if p then [()] else [];;perform with (|->) in  guard 
   false;  return 7;;
1. perform with (|->) in  return 5;  guard false;  return 7;;



Exercise 3.

Define `bind` in terms of `lift` and `join`.



Exercise 4.

<span id="TreeM"></span>Define a monad-plus implementation 
based on binary trees, with constant-time `mzero` and `mplus`. Starter 
code:type 'a tree = Empty | Leaf of 'a | T of 'a t \* 'a tmodule TreeM = 
MonadPlus (struct  type 'a t = 'a tree  let bind a b = TODO  let return a = 
TODO  let mzero = TODO  let mplus a b = TODOend)



Exercise 5.

Show the monad-plus laws for one of:

1. `TreeM` from your solution of exercise [](#TreeM);
1. `ListM` from lecture.



Exercise 6.

Why the following monad-plus is not lazy enough?

* let rec badappend l1 l2 =  match l1 with lazy LazNil -> l2  | lazy 
  (LazCons (hd, tl)) ->    lazy (LazCons (hd, badappend tl l2))let rec 
  badconcatmap f = function  | lazy LazNil -> lazy LazNil  | lazy (LazCons 
  (a, l)) ->    badappend (f a) (badconcatmap f l)
* module BadyListM = MonadPlus (struct  type 'a t = 'a lazylist  let bind a b 
  = badconcatmap b a  let return a = lazy (LazCons (a, lazy LazNil))  let 
  mzero = lazy LazNil  let mplus = badappendend)
* module BadyCountdown = Countdown (BadyListM)let test5 () = BadyListM.run 
  (BadyCountdown.solutions [1;3;7;10;25;50] 765)
* # let t5a, sol5 = time test5;;val t5a : float = 3.3954310417175293val sol5 : 
  string lazylist = <lazy># let t5b, sol51 = time (fun () -> 
  laztake 1 sol5);;val t5b : float = 3.0994415283203125e-06val sol51 : string 
  list = ["((25-(3+7))\*(1+50))"]# let t5c, sol59 = time (fun () -> 
  laztake 10 sol5);;val t5c : float = 7.8678131103515625e-06val sol59 : string 
  list =  ["((25-(3+7))\*(1+50))"; "(((25-3)-7)\*(1+50))"; …# let t5d, 
  sol539 = time (fun () -> laztake 49 sol5);;val t5d : float 
  = 2.59876251220703125e-05val sol539 : string list =  
  ["((25-(3+7))\*(1+50))"; "(((25-3)-7)\*(1+50))"; …



Exercise 7.

Convert a “rectangular” list of lists of strings, representing a matrix with 
inner lists being rows, into a string, where elements are column-aligned. 
(Exercise not related to recent material.)



Exercise 8.

Recall the overly rich way to introduce monads – providing the freedom of 
additional parametermodule type MONAD = sig  type ('s, 'a) t  val return : 
'a -> ('s, 'a) t  val bind :    ('s, 'a) t -> ('a -> ('s, 'b) 
t) -> ('s, 'b) tend

Recall the operations for the exception monad:val throw : excn -> 'a 
monadval catch : 'a monad -> (excn -> 'a monad) -> 'a monad

1. Design the signatures for the exception monad operations to use the 
   enriched monads with ('s, 'a) monad type, so that they provide more 
   flexibility than our exception monad.
1. Does the implementation of the exception monad need to change? The same 
   implementation can work with both sets of signatures, but the 
   implementation given in lecture needs a very slight change. Can you find it 
   without implementing? If not, the lecture script provides RMONAD, 
   RMONAD\_OPS, RMonadOps and RMonad, so you can implement and see for 
   yourself – copy ExceptionM and modify:module ExceptionRM : sig  type ('e, 
   'a) t = KEEP/TODO  include RMONADOPS  val run : ('e, 'a) monad -> ('e, 
   'a) t  val throw : TODO  val catch : TODOend = struct  module M = struct    
   type ('e, 'a) t = KEEP/TODO    let return a = OK a    let bind m b = 
   KEEP/TODO  end  include M  include RMonadOps(M)  let throw e = KEEP/TODO  
   let catch m handler = KEEP/TODOend



Exercise 9.

 Implement the following constructs for *all* monads:

1. for…to…
1. for…downto…
1. while…do…
1. do…while…
1. repeat…until…

Explain how, when your implementation is instantiated with the StateM monad, 
we get the solution to exercise 2 from lecture 4.



Exercise 10.

A canonical example of a probabilistic model is that of a lawn whose grass may 
be wet because it rained, because the sprinkler was on, or for some other 
reason. Oleg Kiselyov builds on this example with variables `rain`, 
`sprinkler`, and `wet_grass`, by adding variables `cloudy` and `wet_roof`. The 
probability tables are:

\begin{eqnarray*}
  P (\operatorname{cloudy}) & = & 0.5 \\\\\\
  P (\operatorname{rain}|\operatorname{cloudy}) & = & 0.8 \\\\\\
  P (\operatorname{rain}|\operatorname{not}\operatorname{cloudy}) & = & 0.2
  \\\\\\
  P (\operatorname{sprinkler}|\operatorname{cloudy}) & = & 0.1 \\\\\\
  P (\operatorname{sprinkler}|\operatorname{not}\operatorname{cloudy}) & = &
  0.5 \\\\\\
  P (\operatorname{wet\_roof}|\operatorname{not}\operatorname{rain})
  & = & 0 \\\\\\
  P (\operatorname{wet}\operatorname{roof}|\operatorname{rain}) & = & 0.7
  \\\\\\
  P (\operatorname{wet}\operatorname{grass}|\operatorname{rain} \wedge
  \operatorname{not}\operatorname{sprinkler}) & = & 0.9 \\\\\\
  P (\operatorname{wet}\operatorname{grass}|\operatorname{sprinkler} \wedge
  \operatorname{not}\operatorname{rain}) & = & 0.9
\end{eqnarray*}

We observe whether the grass is wet and whether the roof is wet. What is the 
probability that it rained?



Exercise 11.

Implement the coarse-grained concurrency model.

* Modify `bind` to compute the resulting monad straight away if the input 
  monad has returned.
* Introduce `suspend` to do what in the fine-grained model was the effect of 
  `bind (return a) b`, i.e. suspend the work although it could already be 
  started.
* One possibility is to introduce `suspend` of type unit monad, introduce a 
  “dummy” monadic value `Suspend` (besides `Return` and `Sleep`), and define 
  `bind suspend b` to do what `bind (return ()) b` would formerly do.
