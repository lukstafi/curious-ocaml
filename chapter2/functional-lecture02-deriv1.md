# Lecture 2: Algebra, Fig. 1

Type inference example derivation

$$ \frac{[?]}{{\texttt{fun x -> ((+) x) 1}} : [?]} $$

$$ \text{use } \rightarrow \text{ introduction:} $$

$$ \frac{\frac{[?]}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{use } \rightarrow \text{ elimination:} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{[?]}{{\texttt{(+) x}} : [? \beta] \rightarrow [?
     \alpha]} & \frac{[?]}{{\texttt{1}} : [? \beta]}
   \end{array}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{we know that {\texttt{1}}} : {\texttt{int}} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{[?]}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow [? \alpha]} &
     \frac{\,}{{\texttt{1}} : {\texttt{int}}}
     \tiny{\text{(constant)}}
   \end{array}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{application again:} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{[?]}{{\texttt{(+)}} : [? \gamma] \rightarrow
       {\texttt{int}} \rightarrow [? \alpha]} &
       \frac{[?]}{{\texttt{x}} : [? \gamma]}
     \end{array}}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow [? \alpha]} &
     \frac{\,}{{\texttt{1}} : {\texttt{int}}}
     \tiny{\text{(constant)}}
   \end{array}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{it's our {\texttt{x}}!} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{[?]}{{\texttt{(+)}} : [? \gamma] \rightarrow
       {\texttt{int}} \rightarrow [? \alpha]} &
       \frac{\,}{{\texttt{x}} : [? \gamma]}
       {\texttt{x}}
     \end{array}}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow [? \alpha]} &
     \frac{\,}{{\texttt{1}} : {\texttt{int}}}
     \tiny{\text{(constant)}}
   \end{array}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [? \gamma]
   \rightarrow [? \alpha]} $$

$$ \text{but {\texttt{(+)}}} : {\texttt{int}}
   \rightarrow {\texttt{int}} \rightarrow
   {\texttt{int}} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{\,}{{\texttt{(+)}} : {\texttt{int}}
       \rightarrow {\texttt{int}} \rightarrow
       {\texttt{int}}} \tiny{\text{(constant)}} &
       \frac{\,}{{\texttt{x}} : {\texttt{int}}}
       {\texttt{x}}
     \end{array}}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow
     {\texttt{int}}} & \frac{\,}{{\texttt{1}} :
     {\texttt{int}}} \tiny{\text{(constant)}}
   \end{array}}{{\texttt{((+) x) 1}} :
   {\texttt{int}}}}{\text{{\texttt{fun x -> ((+) x)
   1}}} : {\texttt{int}} \rightarrow
   {\texttt{int}}} $$


