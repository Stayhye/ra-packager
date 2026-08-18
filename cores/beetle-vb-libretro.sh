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

## Compile core normally for platform=ps2
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

## Recursively find and package ALL compiled object files into the static library archive
rm -f beetle-vb-libretro_ps2.a
find . -name "*.o" | xargs mips64r5900el-ps2-elf-ar rcs beetle-vb-libretro_ps2.a

if [ ! -f "beetle-vb-libretro_ps2.a" ]; then
    echo "Error: Failed to generate beetle-vb-libretro_ps2.a archive"
    exit 1
fi

mips64r5900el-ps2-elf-ranlib beetle-vb-libretro_ps2.a || { exit 1; }

cd .. || { exit 1; }

## Ensure the destination folder exists and move the archive into place for generate_retroarch.sh
mkdir -p beetle-vb-libretro
rm -f beetle-vb-libretro/beetle-vb-libretro_ps2.a
mv -f "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }