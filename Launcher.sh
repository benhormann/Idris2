#!/bin/sh

# Prints a launcher for running idris2 during build.

if uname | grep -q _NT; then CWD=$(cygpath --mixed "$PWD"); else CWD=$PWD; fi

cat <<EOF
#!/bin/sh

export LD_LIBRARY_PATH="$PWD/build/$1/exec/idris2_app\${LD_LIBRARY_PATH:+:}\$LD_LIBRARY_PATH"
export DYLD_LIBRARY_PATH="$PWD/build/$1/exec/idris2_app"

export IDRIS2_INC_SRC="$CWD/build/$1/exec/idris2_app"

export IDRIS2_DATA="$CWD/support"
export IDRIS2_LIBS="$CWD/support/c"
export IDRIS2_PACKAGE_PATH="$CWD/libs"
export IDRIS2_PATH="$CWD/build/$1/ttc"

EOF

if [ $# -lt 2 ]; then
    echo "DIR=\"$PWD/build/$1/exec\""
    tail -n 1 "build/$1/exec/idris2"
    exit
fi

cat <<EOF
"$2" $3 "$PWD/$4" "\$@"
EOF
