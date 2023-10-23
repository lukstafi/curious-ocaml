let f x = "[Directory: "^x^"]"
let test = f (Unix.getcwd ())
