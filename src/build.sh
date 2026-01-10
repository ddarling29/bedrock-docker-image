#!/usr/bin/env bash

set -euo pipefail

function extract_file() {
  local zip_path=$1
  local dest_dir=$2

  echo "Attempting to extract $zip_path to $dest_dir"

  mkdir -p "$dest_dir"

  if unzip -q "$zip_path" -d "$dest_dir"; then
    echo "Extraction successful."
    rm "$zip_path"
  else
    echo "Extraction failed." >&2
    exit 1
  fi
}

function main() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <zip_path> <binary_out_dir> <data_out_dir>" >&2
    exit 1
  fi

  local zip_path=$1
  local binary_out_dir=$2
  local data_out_dir=$3

  extract_file "$zip_path" "$data_out_dir"

  echo "Copying server binary to $binary_out_dir/bedrock_server"
  mkdir -p "$binary_out_dir"
  mv "$data_out_dir/bedrock_server" "$binary_out_dir/bedrock_server"
  chmod +x "$binary_out_dir/bedrock_server"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
