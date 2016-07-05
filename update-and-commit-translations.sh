#!/bin/bash
# Script to pull transifex translation files, and commit them to git if there are any changes.

tx pull -f --mode=reviewed

if [[ -z $(git diff-index --quiet HEAD --) ]]; then
	git commit -am "committing translations from transifex"
	git push
fi
