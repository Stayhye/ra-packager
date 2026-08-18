#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Download or update the source code cleanly using the correct directory name.
REPO_URL="https://github.com/libretro/beetle-vb-libretro"
REPO_FOLDER="beetle-vb-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core normally for platform=ps2
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

cd .. || { exit 1; }

## Ensure destination directory exists and copy/move the output archive
mkdir -p beetle-vb-libretro
rm -f beetle-vb-libretro/beetle-vb-libretro_ps2.a

if [ -f "$REPO_FOLDER/libretro_ps2.a" ]; then
    cp -f "$REPO_FOLDER/libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a
elif [ -f "$REPO_FOLDER/beetle-vb-libretro_ps2.a" ]; then
    cp -f "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a
else
    # Pack objects manually if the Makefile didn't output an archive directly
    mips64r5900el-ps2-elf-ar rcs "$REPO_FOLDER/beetle-vb-libretro_ps2.a" "$REPO_FOLDER"/*.o "$REPO_FOLDER"/mednafen/*.o 2>/dev/null || true
    cp -f "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a
fi

if [ ! -f "beetle-vb-libretro/beetle-vb-libretro_ps2.a" ]; then
    echo "Error: Could not find or create beetle-vb-libretro_ps2.a"
    exit 1
fi