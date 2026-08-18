#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Download the source code cleanly.
REPO_URL="https://github.com/libretro/beetle-vb-libretro"
REPO_FOLDER="vb"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
	git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

## Find whatever archive/library the Makefile built and map it to what generate_retroarch.sh expects
FOUND_FILE=""
for f in *.a; do
    if [ -f "$f" ]; then
        FOUND_FILE="$f"
        break
    fi
done

if [ -z "$FOUND_FILE" ]; then
    echo "Error: Could not find any compiled .a static library file!"
    exit 1
fi

echo "Found compiled library: $FOUND_FILE. Copying to beetle-vb-libretro_ps2.a"
cp "$FOUND_FILE" "../beetle-vb-libretro_ps2.a" || { exit 1; }

cd .. || { exit 1; }

# Ensure it's placed where generate_retroarch.sh expects it ($1/$2.a)
mkdir -p beetle-vb-libretro
mv beetle-vb-libretro_ps2.a beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }