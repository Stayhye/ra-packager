#!/bin/bash
# package.sh 

PROC_NR=$(getconf _NPROCESSORS_ONLN)  

REPO_URL="https://github.com/Stayhye/libretro-meowPC98"
REPO_FOLDER="nekop2_libretro"
BRANCH_NAME="master"

WORKSPACE_ROOT=$(pwd)

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd "$WORKSPACE_ROOT/$REPO_FOLDER" || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Recursively strip any occurrence of -flto from all Makefiles and config files to avoid LTO plugin requirements
find . -type f \( -name "Makefile*" -o -name "*.mk" -o -name "config.mk" \) -exec sed -i 's/-flto//g' {} + || true

# Patch cpu.h to include setjmp.h and provide compatibility fallbacks for sigjmp_buf on bare-metal PS2 newlib
if [ -f "i386c/ia32/cpu.h" ]; then
    sed -i '1i #include <setjmp.h>\n#ifndef sigjmp_buf\ntypedef jmp_buf sigjmp_buf;\n#endif\n#ifndef sigsetjmp\n#define sigsetjmp(env, savemask) setjmp(env)\n#endif\n#ifndef siglongjmp\n#define siglongjmp(env, val) longjmp(env, val)\n#endif' i386c/ia32/cpu.h || true
fi

# Patch retro_timers.h to replace SDL dependency with standard unistd/usleep for PS2
find . -name "retro_timers.h" -exec sed -i 's/#include <SDL\/SDL_timer.h>/#include <unistd.h>/g' {} +
find . -name "retro_timers.h" -exec sed -i 's/SDL_Delay(msec);/usleep(1000 * msec);/g' {} +

# Patch memmap.h to avoid including <sys/mman.h> on PS2
find . -name "memmap.h" -exec sed -i 's/#include <sys\/mman.h>/#ifndef PS2\n#include <sys\/mman.h>\n#endif/g' {} +

# Patch features_cpu.c to handle missing kernel.h and timer.h on PS2 environments
find . -name "features_cpu.c" -exec sed -i 's/#include <kernel.h>/\/\* #include <kernel.h> \*\//g' {} +
find . -name "features_cpu.c" -exec sed -i 's/#include <timer.h>/\/\* #include <timer.h> \*\//g' {} +

cd libretro || { exit 1; }

# Patch Makefile to inject zlib and PS2SDK include paths, explicitly force AR/RANLIB, disable LTO, and disable MMAP
if [ -f "Makefile" ]; then
    sed -i '/ifeq ($(platform), ps2)/a \    CFLAGS += -I$(PS2SDK)/ports/include -I$(PS2SDK)/ee/include -I$(PS2SDK)/common/include -DHAVE_MMAP=0\n    CXXFLAGS += -I$(PS2SDK)/ports/include -I$(PS2SDK)/ee/include -I$(PS2SDK)/common/include -DHAVE_MMAP=0\n    AR = mips64r5900el-ps2-elf-ar\n    RANLIB = mips64r5900el-ps2-elf-ranlib\n    HAVE_LTO = 0\n    HAVE_MMAP = 0' Makefile || true
fi

# Clean previous build artifacts completely
make clean platform=ps2 || true 

# Compile core with LTO and MMAP disabled entirely across all option variables
make -j $PROC_NR platform=ps2 LTO=0 USE_LTO=0 HAVE_LTO=0 HAVE_MMAP=0 || { exit 1; }

## Return back to the workspace root  
cd "$WORKSPACE_ROOT" || { exit 1; }

## Find and copy the generated archive to both expected locations
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" "$REPO_FOLDER/nekop2_libretro_ps2.a" || { exit 1; }
cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }
echo "Successfully built and copied archive."