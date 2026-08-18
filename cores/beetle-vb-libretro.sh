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

## Create the archive explicitly from the compiled object files if an archive doesn't exist
if [ -f "libretro.o" ]; then
    # Create the static library archive expected by the PS2 toolchain packaging script
    ar rcs beetle-vb-libretro_ps2.a *.o mednafen/*.o mednafen/*/*.o libretro-common/*/*.o 2>/dev/null || ar rcs beetle-vb-libretro_ps2.a *.o
fi

# Fallback: if any other .a file was made, use it
if [ ! -f "beetle-vb-libretro_ps2.a" ]; then
    for f in *.a; do
        if [ -f "$f" ]; then
            cp "$f" beetle-vb-libretro_ps2.a
            break
        fi
    done
fi

if [ ! -f "beetle-vb-libretro_ps2.a" ]; then
    echo "Error: Failed to generate beetle-vb-libretro_ps2.a"
    exit 1
fi

cd .. || { exit 1; }

# Place it in the directory structure expected by generate_retroarch.sh ($1/$2.a -> beetle-vb-libretro/beetle-vb-libretro_ps2.a)
mkdir -p beetle-vb-libretro
mv "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }