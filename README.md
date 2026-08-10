TODO:
- UNIT TESTS +  AUTO-MERGE.
- faster propagation without relying purely on purge, you'd tune Cache-Control headers on the origin (shorter max-age for HTML, long max-age + cache-busting filenames for JS/CSS bundles — the classic pattern is hash the filename, e.g. main.a3f9c1.js, so a new deploy is a new URL and caching becomes irrelevant to correctness).


---
# Git things:
git status                    # shows uncommitted local changes only
git diff main...feat/yml      # shows ALL file differences since branches diverged
