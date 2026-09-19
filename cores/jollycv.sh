#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/jollycv"
REPO_FOLDER="jollycv"
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
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }

## Locate the archive right here where it was built
FOUND_ARCHIVE=$(ls *_ps2.a 2>/dev/null | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

