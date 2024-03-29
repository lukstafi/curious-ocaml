## Lecture 2: Type inference example derivation

$$ \frac{[?]}{{\texttt{fun x -> ((+) x) 1}} : [?]} $$

$$ \text{use } \rightarrow \text{ introduction:} $$

$$ \frac{\frac{[?]}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{use } \rightarrow \text{ elimination:} $$

$$ \frac{\frac{\begin{matrix}
     \frac{[?]}{{\texttt{(+) x}} : [? \beta] \rightarrow [?
     \alpha]} & \frac{[?]}{{\texttt{1}} : [? \beta]}
   \end{matrix}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{we know that {\texttt{1}}} : {\texttt{int}} $$

$$ \frac{\frac{\begin{matrix}
     \frac{[?]}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow [? \alpha]} &
     \frac{\,}{{\texttt{1}} : {\texttt{int}}}
     \tiny{\text{(constant)}}
   \end{matrix}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{application again:} $$

$$ \frac{\frac{\begin{matrix}
     \frac{\begin{matrix}
       \frac{[?]}{{\texttt{(+)}} : [? \gamma] \rightarrow
       {\texttt{int}} \rightarrow [? \alpha]} &
       \frac{[?]}{{\texttt{x}} : [? \gamma]}
     \end{matrix}}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow [? \alpha]} &
     \frac{\,}{{\texttt{1}} : {\texttt{int}}}
     \tiny{\text{(constant)}}
   \end{matrix}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{it's our {\texttt{x}}!} $$

$$ \frac{\frac{\begin{matrix}
     \frac{\begin{matrix}
       \frac{[?]}{{\texttt{(+)}} : [? \gamma] \rightarrow
       {\texttt{int}} \rightarrow [? \alpha]} &
       \frac{\,}{{\texttt{x}} : [? \gamma]}
       {\texttt{x}}
     \end{matrix}}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow [? \alpha]} &
     \frac{\,}{{\texttt{1}} : {\texttt{int}}}
     \tiny{\text{(constant)}}
   \end{matrix}}{{\texttt{((+) x) 1}} : [?
   \alpha]}}{{\texttt{fun x -> ((+) x) 1}} : [? \gamma]
   \rightarrow [? \alpha]} $$

$$ \text{but {\texttt{(+)}}} : {\texttt{int}}
   \rightarrow {\texttt{int}} \rightarrow
   {\texttt{int}} $$

$$ \frac{\frac{\begin{matrix}
     \frac{\begin{matrix}
       \frac{\,}{{\texttt{(+)}} : {\texttt{int}}
       \rightarrow {\texttt{int}} \rightarrow
       {\texttt{int}}} \tiny{\text{(constant)}} &
       \frac{\,}{{\texttt{x}} : {\texttt{int}}}
       {\texttt{x}}
     \end{matrix}}{{\texttt{(+) x}} :
     {\texttt{int}} \rightarrow
     {\texttt{int}}} & \frac{\,}{{\texttt{1}} :
     {\texttt{int}}} \tiny{\text{(constant)}}
   \end{matrix}}{{\texttt{((+) x) 1}} :
   {\texttt{int}}}}{\text{{\texttt{fun x -> ((+) x)
   1}}} : {\texttt{int}} \rightarrow
   {\texttt{int}}} $$


