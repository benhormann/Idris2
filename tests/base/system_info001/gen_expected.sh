#!/bin/sh

if ! NProcs=$(nproc || sysctl -n hw.ncpu) 2>/dev/null; then
  echo "Command 'nproc' not found." >&2
  exit 1
fi

echo "$NProcs processors" > expected
