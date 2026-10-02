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

# Handle the generated file (since it builds as x1_libretro_ps2.a)
if [ -f "x1_libretro_ps2.a" ]; then
    # Copy/rename it to xmil_libretro_ps2.a so subsequent steps find it
    cp x1_libretro_ps2.a ../xmil_libretro_ps2.a || { exit 1; }
else
    echo "Error: x1_libretro_ps2.a not found!"
    exit 1
fi

cd ../