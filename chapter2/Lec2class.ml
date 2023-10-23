
type btree = Tip | Node of int * btree * btree
type repr = (int * (int * btree * btree * btree option) option) option

let bij : btree -> repr = function
  | Tip -> None 
  | Node (x, Tip, Tip) -> Some (x, None)
  | Node (x, Tip, Node (y, left, right)) ->
    Some (x, Some (y, left, right, None))
  | Node (x, Node (y, lleft, rright), right) ->
    Some (x, Some (y, lleft, rright, Some right)) 

let inv = function
  | None -> Tip 
  | Some (x, None) -> Node (x, Tip, Tip)
  |  Some (x, Some (y, left, right, None)) ->
    Node (x, Tip, Node (y, left, right))
  | Some (x, Some (y, lleft, rright, Some right)) ->
    Node (x, Node (y, lleft, rright), right)
