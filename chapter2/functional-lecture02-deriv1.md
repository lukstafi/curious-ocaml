# Lecture 2: Algebra, Fig. 1

Type inference example derivation

$$ \frac{[?]}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?]} $$

$$ \text{use } \rightarrow \text{ introduction:} $$

$$ \frac{\frac{[?]}{\text{{\texttt{((+) x) 1}}} : [?
   \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{use } \rightarrow \text{ elimination:} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{[?]}{\text{{\texttt{(+) x}}} : [? \beta] \rightarrow [?
     \alpha]} & \frac{[?]}{\text{{\texttt{1}}} : [? \beta]}
   \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
   \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{we know that \text{{\texttt{1}}}} : \text{{\texttt{int}}} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{[?]}{\text{{\texttt{(+) x}}} :
     \text{{\texttt{int}}} \rightarrow [? \alpha]} &
     \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
     \tiny{\text{(constant)}}
   \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
   \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{application again:} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{[?]}{\text{{\texttt{(+)}}} : [? \gamma] \rightarrow
       \text{{\texttt{int}}} \rightarrow [? \alpha]} &
       \frac{[?]}{\text{{\texttt{x}}} : [? \gamma]}
     \end{array}}{\text{{\texttt{(+) x}}} :
     \text{{\texttt{int}}} \rightarrow [? \alpha]} &
     \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
     \tiny{\text{(constant)}}
   \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
   \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{it's our \text{{\texttt{x}}}!} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{[?]}{\text{{\texttt{(+)}}} : [? \gamma] \rightarrow
       \text{{\texttt{int}}} \rightarrow [? \alpha]} &
       \frac{\,}{\text{{\texttt{x}}} : [? \gamma]}
       \text{{\texttt{x}}}
     \end{array}}{\text{{\texttt{(+) x}}} :
     \text{{\texttt{int}}} \rightarrow [? \alpha]} &
     \frac{\,}{\text{{\texttt{1}}} : \text{{\texttt{int}}}}
     \tiny{\text{(constant)}}
   \end{array}}{\text{{\texttt{((+) x) 1}}} : [?
   \alpha]}}{\text{{\texttt{fun x -> ((+) x) 1}}} : [? \gamma]
   \rightarrow [? \alpha]} $$

$$ \text{but \text{{\texttt{(+)}}}} : \text{{\texttt{int}}}
   \rightarrow \text{{\texttt{int}}} \rightarrow
   \text{{\texttt{int}}} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{\,}{\text{{\texttt{(+)}}} : \text{{\texttt{int}}}
       \rightarrow \text{{\texttt{int}}} \rightarrow
       \text{{\texttt{int}}}} \tiny{\text{(constant)}} &
       \frac{\,}{\text{{\texttt{x}}} : \text{{\texttt{int}}}}
       \text{{\texttt{x}}}
     \end{array}}{\text{{\texttt{(+) x}}} :
     \text{{\texttt{int}}} \rightarrow
     \text{{\texttt{int}}}} & \frac{\,}{\text{{\texttt{1}}} :
     \text{{\texttt{int}}}} \tiny{\text{(constant)}}
   \end{array}}{\text{{\texttt{((+) x) 1}}} :
   \text{{\texttt{int}}}}}{\text{\text{{\texttt{fun x -> ((+) x)
   1}}}} : \text{{\texttt{int}}} \rightarrow
   \text{{\texttt{int}}}} $$


