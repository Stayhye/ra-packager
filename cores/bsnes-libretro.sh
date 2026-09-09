#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/bsnes-libretro"
REPO_FOLDER="bsnes-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Recursively strip any occurrence of -flto from all Makefiles and config files
find . -type f \( -name "Makefile*" -o -name "*.mk" -o -name "config.mk" \) -exec sed -i 's/-flto//g' {} + || true

# Patch nall/intrinsics.hpp to force MIPS architecture and avoid endian.h
if [ -f "nall/intrinsics.hpp" ]; then
    sed -i '/#include <endian.h>/i \
#define ARCH_MIPS 1\n\
#define ARCH_LITTLE_ENDIAN 1\n\
#define __LITTLE_ENDIAN__ 1\n' nall/intrinsics.hpp || true
    sed -i 's/#include <endian.h>/\/\/#include <endian.h>/g' nall/intrinsics.hpp || true
fi

# Patch nall/platform.hpp to bypass missing dlfcn.h, pwd.h, and grp.h on PS2
if [ -f "nall/platform.hpp" ]; then
    sed -i 's/#include <dlfcn.h>/#if !defined(PLATFORM_PS2)\n  #include <dlfcn.h>\n#endif/' nall/platform.hpp || true
    sed -i '/#include <pwd.h>/d' nall/platform.hpp || true
    sed -i '/#include <grp.h>/d' nall/platform.hpp || true
fi

# Patch Makefile to inject PS2 paths, compilation flags, platform definition, and disable LTO
if [ -f "Makefile" ]; then
    sed -i '/ifeq ($(platform), ps2)/a \
	CFLAGS += -I$(PS2SDK)/ports/include -DPLATFORM_PS2=1 -D__LITTLE_ENDIAN__=1\n\
	CXXFLAGS += -I$(PS2SDK)/ports/include -DPLATFORM_PS2=1 -D__linux__ -D__mips__ -D_MIPS_ARCH_R5900 -DARCH_LITTLE_ENDIAN -D__LITTLE_ENDIAN__=1 -DNO_DLFCN\n\
	AR = mips64r5900el-ps2-elf-ar\n\
	RANLIB = mips64r5900el-ps2-elf-ranlib\n\
	HAVE_LTO = 0' Makefile || true
fi

# Clean previous build artifacts completely
make clean platform=ps2 || true

# Compile core with LTO disabled entirely
make -j $PROC_NR platform=ps2 LTO=0 USE_LTO=0 HAVE_LTO=0 || { exit 1; }

## Return back to the workspace root
cd ../.. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p bsnes-libretro
cp -f "$FOUND_ARCHIVE" bsnes-libretro/bsnes_libretro_ps2.a || { exit 1; }