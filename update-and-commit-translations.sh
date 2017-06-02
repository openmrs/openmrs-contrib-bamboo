#!/bin/bash -eux
# Script to pull transifex translation files, and commit them to git if there are any changes.

tx pull -f --mode=reviewed

git update-index -q --refresh

# If running inside a Bamboo agent, set git origin
if [ -n "${bamboo_shortJobName}" ]; then
  remote_url="git@github.com:openmrs/openmrs-module-${bamboo_shortJobName}.git"
  echo "Setting git remote to ${remote_url}"
  git remote set-url origin $remote_url
fi

if ! git diff-index --quiet HEAD --; then
  echo 'There are changes to be committed'
  git commit -am "committing translations from transifex"
  git push
fi
