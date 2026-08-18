#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
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

## Compile core for platform=ps2 using the cross-compiler
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

## Package using the explicit MIPS PS2 archiver tool so it's never "incompatible"
rm -f beetle-vb-libretro_ps2.a
mips64r5900el-ps2-elf-ar rcs beetle-vb-libretro_ps2.a *.o mednafen/*.o mednafen/*/*.o libretro-common/*/*.o 2>/dev/null || \
mips64r5900el-ps2-elf-ar rcs beetle-vb-libretro_ps2.a *.o || { exit 1; }

cd .. || { exit 1; }

## Place it precisely where generate_retroarch.sh copies it from
mkdir -p beetle-vb-libretro
cp "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }