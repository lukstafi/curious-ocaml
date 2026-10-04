open Polynomial
let () =
  assert (trim [1.;0.;0.] = [1.]);
  assert (trim [0.;0.] = []);
  assert (differentiate [] = []);
  assert (integrate 1. [2.;3.] = [1.;2.;1.5]);
  assert (differentiate (integrate 1. [2.;3.]) = [2.;3.]);
  assert (quotient ~terms:5 [1.] [1.;-1.;0.] = [1.;1.;1.;1.;1.]);
  assert (quotient ~terms:4 [1.;2.] [1.] = [1.;2.;0.;0.]);
  assert (quotient ~terms:0 [1.] [1.] = []);
  List.iter (fun denominator ->
    assert (try ignore (quotient ~terms:3 [1.] denominator); false
      with Invalid_argument _ -> true)) [ []; [0.;0.]; [0.;1.] ];
  let sparse = 1. :: List.init 99 (fun _ -> 0.) @ [1.] in
  assert (evaluate 1. sparse = 2.);
  for i = 0 to 100 do
    let x = float_of_int i /. 100. in
    assert (abs_float (exp_unit ~degree:12 x -. exp x) < 1e-9)
  done
