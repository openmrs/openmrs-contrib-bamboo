#!/bin/bash

set -e -v

echo "--> $(ps -p "$$" -o comm=)"
echo "shell  $SHELL"
