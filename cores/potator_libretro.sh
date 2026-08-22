#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/potator"
REPO_FOLDER="potator-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Move into the folder where the Makefile is located
cd platform/libretro || { exit 1; }

## Compile core using native platform=ps2 support
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

# Return to the repository root
cd ../.. || { exit 1; }

## Find and copy the generated static archive dynamically
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_libretro_ps2.a" | head -n 1)

if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find the compiled static archive file!"
    exit 1
fi

echo "Found archive at: $FOUND_ARCHIVE"
cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p potator_libretro
cp -f "$FOUND_ARCHIVE" potator_libretro/potator_libretro_ps2.a || { exit 1; }