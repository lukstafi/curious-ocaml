---
title: Curious OCaml
author:
  - Lukasz Stafiniak
  - Claude Opus 4.5
  - GPT-5.2
header-includes:
  - <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"
       integrity="sha384-n8MVd4RsNIU0tAv4ct0nTaAbDJwPJzDEaqSD1odI+WdtXRGWt2kTvGFasHpSy3SV" crossorigin="anonymous">
  - <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"
       integrity="sha384-XjKyOOlGwcjNTAIQHIpgOno0Hl1YQqzUOEleOLALmuqehneUG+vnGctmUb0ZY0l8"
       crossorigin="anonymous"></script>
  - <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
       integrity="sha384-+VBxd3r6XgURycqtZ117nYw44OOcIax56Z4dCRWbxyPt0Koah1uHoK0o4+/RRE05" crossorigin="anonymous"
       onload="renderMathInElement(document.body);"></script>
  - |
    <script>
    document.addEventListener('DOMContentLoaded', function() {
      const toc = document.getElementById('TOC');
      if (!toc) return;

      const tocLinks = toc.querySelectorAll('a[href^="#"]');
      const headings = [];

      tocLinks.forEach(link => {
        const id = link.getAttribute('href').slice(1);
        const heading = document.getElementById(id);
        if (heading) {
          headings.push({ id, link, heading });
        }
      });

      function updateActiveLink() {
        const scrollPos = window.scrollY + 100;

        let current = null;
        for (const item of headings) {
          if (item.heading.offsetTop <= scrollPos) {
            current = item;
          } else {
            break;
          }
        }

        tocLinks.forEach(link => link.classList.remove('toc-active'));
        toc.querySelectorAll('li').forEach(li => li.classList.remove('toc-active'));

        if (current) {
          current.link.classList.add('toc-active');
          let parent = current.link.closest('li');
          while (parent && toc.contains(parent)) {
            parent.classList.add('toc-active');
            parent = parent.parentElement?.closest('li');
          }
          if (window.innerWidth > 900) {
            current.link.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
          }
        }
      }

      let ticking = false;
      window.addEventListener('scroll', function() {
        if (!ticking) {
          requestAnimationFrame(function() {
            updateActiveLink();
            ticking = false;
          });
          ticking = true;
        }
      });

      updateActiveLink();
    });
    </script>
documentclass: report
classoption:
  - openany
fontsize: 11pt
geometry:
  - margin=1in
toc-depth: 3
---
