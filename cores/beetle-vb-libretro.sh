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

## Compile core with platform=ps2
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

## Beetle-vb outputs a static library. Let's find it securely.
TARGET_A="beetle-vb-libretro_ps2.a"
rm -f "$TARGET_A"

if [ -f "libretro_ps2.a" ]; then
    cp libretro_ps2.a "$TARGET_A"
elif [ -f "mednafen_vb_libretro.a" ]; then
    cp mednafen_vb_libretro.a "$TARGET_A"
elif [ -f "libretro.a" ]; then
    cp libretro.a "$TARGET_A"
else
    # If the Makefile compiled griffin or individual objects, archive them using the toolchain ar
    mips64r5900el-ps2-elf-ar rcs "$TARGET_A" *.o mednafen/*.o mednafen/*/*.o libretro-common/*/*.o 2>/dev/null || \
    mips64r5900el-ps2-elf-ar rcs "$TARGET_A" *.o
fi

if [ ! -f "$TARGET_A" ]; then
    echo "Error: Could not find or generate $TARGET_A"
    exit 1
fi

cd .. || { exit 1; }

# Place it in the directory expected by generate_retroarch.sh ($1/$2.a)
mkdir -p beetle-vb-libretro
cp "$REPO_FOLDER/$TARGET_A" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }