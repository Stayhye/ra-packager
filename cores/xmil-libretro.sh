#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/xmil-libretro"
REPO_FOLDER="xmil-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

cd libretro || { exit 1; }

## Compile core
make -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }

# Debug: List files matching *.a to see what the actual filename is
echo "Listing generated static libraries:"
ls -la *.a

# Move the generated file up 1 folder (adjust name if it differs, e.g., xmil_libretro.a)
if [ -f "xmil_libretro_ps2.a" ]; then
    mv xmil_libretro_ps2.a ../ || { exit 1; }
elif [ -f "xmil_libretro.a" ]; then
    mv xmil_libretro.a ../ || { exit 1; }
else
    # Fallback to moving any .a file produced in this directory
    mv *.a ../ || { exit 1; }
fi

cd ../