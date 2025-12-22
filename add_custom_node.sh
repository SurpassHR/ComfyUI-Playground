#!/bin/bash
if [ -z "$1" ]; then
  echo "No custom node repo link detected."
  exit 1
fi

url=$1
name=$(basename -s .git "$url")
git clone "$url" "custom_nodes/$name"