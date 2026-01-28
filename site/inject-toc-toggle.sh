#!/bin/bash
# Inject ToC lock toggle button into pandoc HTML output
# Reads from stdin, writes to stdout

sed 's|<nav id="TOC" role="doc-toc">|<nav id="TOC" role="doc-toc"><button id="toc-lock-toggle" title="Toggle auto-fold">\&#x1f512;</button><script>document.addEventListener("DOMContentLoaded",function(){var btn=document.getElementById("toc-lock-toggle");var toc=document.getElementById("TOC");if(!btn\|\|!toc)return;var locked=localStorage.getItem("tocLocked")==="true";function updateState(){if(locked){toc.classList.add("toc-locked");btn.classList.add("locked");btn.innerHTML="\&#x1f513;";btn.title="Click to enable auto-fold";}else{toc.classList.remove("toc-locked");btn.classList.remove("locked");btn.innerHTML="\&#x1f512;";btn.title="Click to expand all \&amp; disable auto-fold";}}updateState();btn.addEventListener("click",function(){locked=!locked;localStorage.setItem("tocLocked",locked);updateState();});});</script>|'
