#!/bin/bash
# package.sh for MAME 2014 PS2

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/mame2014-libretro"
REPO_FOLDER="mame2014_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Fix missing python2 by routing it to python3/python via a local bin wrapper
mkdir -p .local-bin
ln -sf $(which python3 || which python) .local-bin/python2
export PATH="$(pwd)/.local-bin:$PATH"

## Compile core using native platform=ps2 support with static linking and error suppression
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 STATIC_LINKING=1 NOWERROR=1 CFLAGS+="-Wno-error=class-memaccess -Wno-error=nonnull-compare" CXXFLAGS+="-Wno-error=class-memaccess -Wno-error=nonnull-compare" || { exit 1; }

## Inspect binary size and sections locally in the script
FOUND_ARCHIVE=$(find . -maxdepth 1 -name "*.a" | head -n 1)
if [ -n "$FOUND_ARCHIVE" ]; then
    echo "=== File Size ==="
    ls -lh "$FOUND_ARCHIVE"
    
    echo "=== Section Breakdown ==="
    mips64r5900el-ps2-elf-size -A "$FOUND_ARCHIVE"
    
    echo "=== Top 20 Largest Symbols ==="
    mips64r5900el-ps2-elf-nm --size-sort -S "$FOUND_ARCHIVE" | tail -n 20
fi

## Return back to the workspace root
cd .. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -maxdepth 1 -name "*.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p mame2014_libretro
cp -f "$FOUND_ARCHIVE" mame2014_libretro/mame2014_libretro_ps2.a || { exit 1; }

echo "Successfully built and packaged MAME 2014 for PS2!"