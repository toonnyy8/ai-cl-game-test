#!/bin/sh
# deploy-pages.sh — publish dist/duel to the gh-pages branch (GitHub Pages is pointed at it in the repo settings).
# Run after ./build.sh duel and the gates. The branch holds only the built files (+ .nojekyll), one commit per deploy.
set -eu
cd "$(dirname "$0")/.."
[ -f dist/duel/index.html ] || { echo "no dist/duel: run ./build.sh duel first" >&2; exit 1; }
WT=build/gh-pages
rev=$(git rev-parse --short HEAD)
git fetch -q origin gh-pages 2>/dev/null || true
if [ ! -d "$WT" ]; then
  if git show-ref -q --verify refs/remotes/origin/gh-pages; then
    git worktree add -q -B gh-pages "$WT" origin/gh-pages
  else
    git worktree add -q --detach "$WT" && git -C "$WT" checkout -q --orphan gh-pages
  fi
fi
git -C "$WT" rm -rfq --ignore-unmatch . >/dev/null
git -C "$WT" clean -fdxq   # (a fresh orphan starts with main's tree staged: drop it all)
cp -r dist/duel/. "$WT"/
touch "$WT"/.nojekyll
git -C "$WT" add -A
git -C "$WT" commit -q -m "Deploy SOUL DUEL from main $rev" || { echo "nothing changed"; exit 0; }
git -C "$WT" push -q origin gh-pages
echo "deployed main $rev to gh-pages"
