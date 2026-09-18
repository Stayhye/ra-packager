#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/a5200"
REPO_FOLDER="a5200"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }


# Clean previous build artifacts completely
make clean platform=ps2 || true

# Compile core with LTO disabled entirely across all option variables
make -j $PROC_NR platform=ps2 LTO=0 USE_LTO=0 HAVE_LTO=0 || { exit 1; }

## Inspect binary size and sections locally in the script
FOUND_ARCHIVE=$(find . -name "*.a" | head -n 1)


cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p a5200
cp -f "$FOUND_ARCHIVE" /a5200_libretro_ps2.a || { exit 1; }