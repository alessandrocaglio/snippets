#!/bin/bash

# Display help message if -h is passed as a parameter
if [ "$1" == "-h" ]; then
  echo "Usage: $0 [BASE_DIR]"
  echo "Update all Git repositories within a specified base directory."
  exit 0
fi

# Get the base directory as an optional parameter, defaulting to the current directory
BASE_DIR="${1:-$PWD}"

# Function to navigate through directories and execute git fetch and pull
git_fetch_pull() {
  local dir="$1"
  cd "$dir" || return
  if [ -d ".git" ]; then
    echo "Updating repository in $dir"
    git fetch
    git pull
  fi
  for sub_dir in */; do
    git_fetch_pull "$sub_dir"
  done
  cd ..
}

# Main script
git_fetch_pull "$BASE_DIR"
