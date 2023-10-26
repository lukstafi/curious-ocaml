---
title: Curious OCaml
author: Lukasz Stafiniak
header-includes:
  - <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"
       integrity="sha384-n8MVd4RsNIU0tAv4ct0nTaAbDJwPJzDEaqSD1odI+WdtXRGWt2kTvGFasHpSy3SV" crossorigin="anonymous">
  - <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"
       integrity="sha384-XjKyOOlGwcjNTAIQHIpgOno0Hl1YQqzUOEleOLALmuqehneUG+vnGctmUb0ZY0l8"
       crossorigin="anonymous"></script>
  - <script>document.addEventListener("DOMContentLoaded", function () {
        var mathElements = document.getElementsByClassName("math");
        var macros = [];
        for (var i = 0; i < mathElements.length; i++) {
          var texText = mathElements[i].firstChild;
          if (mathElements[i].tagName == "SPAN") {
          katex.render(texText.data, mathElements[i], {
            displayMode:mathElements[i].classList.contains('display'), throwOnError:false, macros:macros, fleqn:false}); }}});
    </script>
---
