#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

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

## Compile core
make -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }

## Package all nested object files recursively into the archive
rm -f libretro_ps2.a
find . -name "*.o" -type f | xargs mips64r5900el-ps2-elf-ar rcs libretro_ps2.a || { exit 1; }
mips64r5900el-ps2-elf-ranlib libretro_ps2.a || { exit 1; }

cd .. || { exit 1; }

## Copy the archive to both locations (Root for Makefile.ps2 and folder for generate_retroarch.sh)
cp -f "$REPO_FOLDER/libretro_ps2.a" ./libretro_ps2.a || { exit 1; }

mkdir -p beetle-vb-libretro
cp -f "$REPO_FOLDER/libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }