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

make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

rm -f libretro_ps2.a
mips64r5900el-ps2-elf-ar rcs libretro_ps2.a *.o mednafen/*.o mednafen/*/*.o libretro-common/*/*.o 2>/dev/null || \
mips64r5900el-ps2-elf-ar rcs libretro_ps2.a *.o || { exit 1; }

mips64r5900el-ps2-elf-ranlib libretro_ps2.a || { exit 1; }

cd .. || { exit 1; }

# Copy libretro_ps2.a directly to the root folder alongside Makefile.ps2
cp -f "$REPO_FOLDER/libretro_ps2.a" ./libretro_ps2.a || { exit 1; }

# Also keep the structure expected by generate_retroarch.sh
mkdir -p beetle-vb-libretro
cp -f "$REPO_FOLDER/libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }