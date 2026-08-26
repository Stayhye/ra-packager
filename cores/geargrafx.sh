#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/Geargrafx"
REPO_FOLDER="geargrafx-libretro"
BRANCH_NAME="main"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd "$REPO_FOLDER" || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Navigate into platforms/libretro and build
cd platforms/libretro || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

## Locate the archive right here where it was built
FOUND_ARCHIVE=$(ls *_ps2.a 2>/dev/null | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

## Copy it to the workspace root (up two levels from platforms/libretro)
cp -f "$FOUND_ARCHIVE" ../../libretro_ps2.a || { exit 1; }

## Create target directory in the workspace root and copy it there too
mkdir -p ../../"$REPO_FOLDER"
cp -f "$FOUND_ARCHIVE" ../../"$REPO_FOLDER"/geargrafx_libretro_ps2.a || { exit 1; }

## Return back to workspace root cleanly
cd ../.. || true