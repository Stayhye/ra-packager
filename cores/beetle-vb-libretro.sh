#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Download or update the source code cleanly.
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

# Locate whatever static library the core's Makefile built
BUILT_LIB=""
if [ -f "libretro.a" ]; then
    BUILT_LIB="libretro.a"
elif [ -f "mednafen_vb_libretro.a" ]; then
    BUILT_LIB="mednafen_vb_libretro.a"
elif [ -f "libretro_ps2.a" ]; then
    BUILT_LIB="libretro_ps2.a"
else
    # Fallback: pack the object files using the PS2 toolchain archiver if no .a was generated
    mips64r5900el-ps2-elf-ar rcs beetle-vb-libretro_ps2.a *.o mednafen/*.o mednafen/*/*.o libretro-common/*/*.o 2>/dev/null || \
    mips64r5900el-ps2-elf-ar rcs beetle-vb-libretro_ps2.a *.o
    BUILT_LIB="beetle-vb-libretro_ps2.a"
fi

cp "$BUILT_LIB" beetle-vb-libretro_ps2.a || { exit 1; }

cd .. || { exit 1; }

# Place it in the directory structure expected by generate_retroarch.sh ($1/$2.a)
mkdir -p beetle-vb-libretro
cp "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }