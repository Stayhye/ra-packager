#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/Gearsystem"
REPO_FOLDER="gearsystem"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

cd platforms/libretro || { exit 1; }
## Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }

## Copy and rename the compiled library to the repository root directory
if [ -f "libretro_ps2.a" ]; then
    cp libretro_ps2.a ../../gearsystem_libretro_ps2.a
else
    # Fallback to catch any variant naming convention
    find . -maxdepth 1 -name "*.a" -exec cp {} ../../gearsystem_libretro_ps2.a \;
fi