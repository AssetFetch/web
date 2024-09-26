#!/bin/bash

# Remove existing files
rm -rf -v /docs/docs/spec/*

# Loop through each version
for version in "tags/0.1" "tags/0.2" "tags/0.3" "heads/main" ; do
  curl --create-dirs -sS -L -o "/docs/docs/spec/$version.md" "https://raw.githubusercontent.com/AssetFetch/spec/refs/$version/spec.md"
done
