#!/bin/bash
# package.sh 

PROC_NR=$(getconf _NPROCESSORS_ONLN)  

REPO_URL="https://github.com/Stayhye/libretro-meowPC98"
REPO_FOLDER="nekop2_libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Recursively strip any occurrence of -flto from all Makefiles and config files to avoid LTO plugin requirements
find . -type f \( -name "Makefile*" -o -name "*.mk" -o -name "config.mk" \) -exec sed -i 's/-flto//g' {} + || true

# Patch cpu.h to define POSIX feature macros and include setjmp.h for sigjmp_buf
if [ -f "i386c/ia32/cpu.h" ]; then
    sed -i '1i #ifndef _POSIX_C_SOURCE\n#define _POSIX_C_SOURCE 200809L\n#endif\n#include <setjmp.h>' i386c/ia32/cpu.h || true
fi

cd libretro || { exit 1; }

# Patch Makefile to inject zlib search path and explicitly force AR/RANLIB and disable LTO flags
if [ -f "Makefile" ]; then
    sed -i '/ifeq ($(platform), ps2)/a \    CFLAGS += -I$(PS2SDK)/ports/include\n    CXXFLAGS += -I$(PS2SDK)/ports/include\n    AR = mips64r5900el-ps2-elf-ar\n    RANLIB = mips64r5900el-ps2-elf-ranlib\n    HAVE_LTO = 0' Makefile || true
fi

# Clean previous build artifacts completely
make clean platform=ps2 || true

# Compile core with LTO disabled entirely across all option variables
make -j $PROC_NR platform=ps2 LTO=0 USE_LTO=0 HAVE_LTO=0 || { exit 1; }

## Inspect binary size and sections locally in the script (without destroying symbols)
FOUND_ARCHIVE=$(find . -name "*_ps2.a" | head -n 1)
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
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }