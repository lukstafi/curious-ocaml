Functional Programming



Lecture 2: Algebra, Fig. 1

Type inference example derivation

$$ \frac{[?]}{\text{\text{{\texttt{fun x -> ((+) x) 1}}}} : [?]} $$

$$ \text{use } \rightarrow \text{ introduction:} $$

$$ \frac{\frac{[?]}{\text{\text{{\texttt{((+) x) 1}}}} : [?
   \alpha]}}{\text{\text{{\texttt{fun x -> ((+) x) 1}}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{use } \rightarrow \text{ elimination:} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{[?]}{\text{\text{{\texttt{(+) x}}}} : [? \beta] \rightarrow [?
     \alpha]} & \frac{[?]}{\text{\text{{\texttt{1}}}} : [? \beta]}
   \end{array}}{\text{\text{{\texttt{((+) x) 1}}}} : [?
   \alpha]}}{\text{\text{{\texttt{fun x -> ((+) x) 1}}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{we know that \text{{\texttt{1}}}} : \text{\text{{\texttt{int}}}}
$$

$$ \frac{\frac{\begin{array}{ll}
     \frac{[?]}{\text{\text{{\texttt{(+) x}}}} :
     \text{\text{{\texttt{int}}}} \rightarrow [? \alpha]} &
     \frac{}{\text{\text{{\texttt{1}}}} : \text{\text{{\texttt{int}}}}}
     \scriptsize{\text{(constant)}}
   \end{array}}{\text{\text{{\texttt{((+) x) 1}}}} : [?
   \alpha]}}{\text{\text{{\texttt{fun x -> ((+) x) 1}}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{application again:} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{[?]}{\text{\text{{\texttt{(+)}}}} : [? \gamma] \rightarrow
       \text{\text{{\texttt{int}}}} \rightarrow [? \alpha]} &
       \frac{[?]}{\text{\text{{\texttt{x}}}} : [? \gamma]}
     \end{array}}{\text{\text{{\texttt{(+) x}}}} :
     \text{\text{{\texttt{int}}}} \rightarrow [? \alpha]} &
     \frac{}{\text{\text{{\texttt{1}}}} : \text{\text{{\texttt{int}}}}}
     \scriptsize{\text{(constant)}}
   \end{array}}{\text{\text{{\texttt{((+) x) 1}}}} : [?
   \alpha]}}{\text{\text{{\texttt{fun x -> ((+) x) 1}}}} : [?] 
\rightarrow
   [? \alpha]} $$

$$ \text{it's our \text{{\texttt{x}}}!} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{[?]}{\text{\text{{\texttt{(+)}}}} : [? \gamma] \rightarrow
       \text{\text{{\texttt{int}}}} \rightarrow [? \alpha]} &
       \frac{}{\text{\text{{\texttt{x}}}} : [? \gamma]}
       \text{\text{{\texttt{x}}}}
     \end{array}}{\text{\text{{\texttt{(+) x}}}} :
     \text{\text{{\texttt{int}}}} \rightarrow [? \alpha]} &
     \frac{}{\text{\text{{\texttt{1}}}} : \text{\text{{\texttt{int}}}}}
     \scriptsize{\text{(constant)}}
   \end{array}}{\text{\text{{\texttt{((+) x) 1}}}} : [?
   \alpha]}}{\text{\text{{\texttt{fun x -> ((+) x) 1}}}} : [? \gamma]
   \rightarrow [? \alpha]} $$

$$ \text{but \text{{\texttt{(+)}}}} : \text{\text{{\texttt{int}}}}
   \rightarrow \text{\text{{\texttt{int}}}} \rightarrow
   \text{\text{{\texttt{int}}}} $$

$$ \frac{\frac{\begin{array}{ll}
     \frac{\begin{array}{ll}
       \frac{}{\text{\text{{\texttt{(+)}}}} : \text{\text{{\texttt{int}}}}
       \rightarrow \text{\text{{\texttt{int}}}} \rightarrow
       \text{\text{{\texttt{int}}}}} \scriptsize{\text{(constant)}} &
       \frac{}{\text{\text{{\texttt{x}}}} : \text{\text{{\texttt{int}}}}}
       \text{\text{{\texttt{x}}}}
     \end{array}}{\text{\text{{\texttt{(+) x}}}} :
     \text{\text{{\texttt{int}}}} \rightarrow
     \text{\text{{\texttt{int}}}}} & \frac{}{\text{\text{{\texttt{1}}}} :
     \text{\text{{\texttt{int}}}}} \scriptsize{\text{(constant)}}
   \end{array}}{\text{\text{{\texttt{((+) x) 1}}}} :
   \text{\text{{\texttt{int}}}}}}{\text{\text{{\texttt{fun x -> ((+) 
x)
   1}}}} : \text{\text{{\texttt{int}}}} \rightarrow
   \text{\text{{\texttt{int}}}}} $$


