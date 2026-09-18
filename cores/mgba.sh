#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/mgba"
REPO_FOLDER="mgba"
BRANCH_NAME="ps2"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Fix locale_t conflict for PS2 SDK
sed -i 's/#elif !defined(HAVE_LOCALE)/#elif !defined(HAVE_LOCALE) \&\& !defined(_SYS__LOCALE_H_)/g' include/mgba-util/formatting.h

## Compile core
make -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }