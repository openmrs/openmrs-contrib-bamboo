#!/bin/bash
# Script to pull transifex translation files, and commit them to git if there are any changes.

tx pull -f --mode=reviewed

if ! git diff-index --quiet HEAD --; then 
  echo 'There are changes to be committed'
  git commit -am "committing translations from transifex"
  git push
fi
