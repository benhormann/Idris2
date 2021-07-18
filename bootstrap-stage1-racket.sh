#!/bin/sh

set -e # exit on any error

if [ -z "$IDRIS2_VERSION" ]; then
    echo "Required IDRIS2_VERSION env is not set."
    exit 1
fi
echo "Bootstrapping IDRIS2_VERSION=$IDRIS2_VERSION"

# Compile the bootstrap scheme
cd bootstrap-build
echo "Building idris2-boot.zo from idris2-boot.rkt"
"${RACKET_RACO:-raco}" make idris2_app/idris2-boot.rkt

# Put the result in the usual place where the target goes
mkdir -p ../build/exec/idris2_app/compiled
install ../bootstrap/idris2-rktboot.sh ../build/exec/idris2
install idris2_app/*idris2* ../build/exec/idris2_app
install idris2_app/compiled/* ../build/exec/idris2_app/compiled
