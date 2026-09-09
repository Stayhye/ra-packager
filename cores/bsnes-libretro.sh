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

# Recursively strip any occurrence of -flto and -Werror from all Makefiles and config files
find . -type f \( -name "Makefile*" -o -name "*.mk" -o -name "config.mk" \) -exec sed -i 's/-flto//g; s/-Werror//g' {} + || true

# Create a robust local stub include directory for missing POSIX memory and directory mapping APIs
mkdir -p stub_include/sys
mkdir -p stub_include/netinet

cat << 'EOF' > stub_include/sys/mman.h
#ifndef _SYS_MMAN_H
#define _SYS_MMAN_H
#define PROT_READ 1
#define PROT_WRITE 2
#define PROT_EXEC 4
#define MAP_SHARED 1
#define MAP_PRIVATE 2
#define MAP_FAILED ((void*)-1)
inline void* mmap(void* addr, size_t length, int prot, int flags, int fd, off_t offset) { return MAP_FAILED; }
inline int munmap(void* addr, size_t length) { return -1; }
#endif
EOF

cat << 'EOF' > stub_include/dirent.h
#ifndef _STUB_DIRENT_H
#define _STUB_DIRENT_H
#include_next <dirent.h>
#ifndef dirfd
#define dirfd(dir) (-1)
#endif
#ifndef fstatat
#define fstatat(dirfd, path, buf, flags) stat(path, buf)
#endif
#endif
EOF

touch stub_include/dlfcn.h
touch stub_include/pwd.h
touch stub_include/grp.h
touch stub_include/poll.h
touch stub_include/netdb.h
touch stub_include/netinet/in.h
touch stub_include/sys/socket.h
touch stub_include/sys/wait.h

# Patch nall/intrinsics.hpp to force MIPS architecture and avoid endian.h
if [ -f "nall/intrinsics.hpp" ]; then
    sed -i '/#include <endian.h>/i \
#define ARCH_MIPS 1\n\
#define ARCH_LITTLE_ENDIAN 1\n\
#define __LITTLE_ENDIAN__ 1\n' nall/intrinsics.hpp || true
    sed -i 's/#include <endian.h>/\/\/#include <endian.h>/g' nall/intrinsics.hpp || true
fi

# Patch nall/primitives/integer.hpp to fix parentheses warning/error
if [ -f "nall/primitives/integer.hpp" ]; then
    sed -i 's/1ull << Precision - 1/1ull << (Precision - 1)/g' nall/primitives/integer.hpp || true
fi

# Patch Makefile to inject stub include path, PS2 paths, compilation flags, and disable LTO
if [ -f "Makefile" ]; then
    STUB_DIR="$(pwd)/stub_include"
    sed -i "/ifeq (\$(platform), ps2)/a \\
	CFLAGS += -I\$(PS2SDK)/ports/include -I${STUB_DIR} -DPLATFORM_PS2=1 -D__LITTLE_ENDIAN__=1 -w\\n\\
	CXXFLAGS += -I\$(PS2SDK)/ports/include -I${STUB_DIR} -DPLATFORM_PS2=1 -D__linux__ -D__mips__ -D_MIPS_ARCH_R5900 -DARCH_LITTLE_ENDIAN -D__LITTLE_ENDIAN__=1 -DNO_DLFCN -w\\n\\
	AR = mips64r5900el-ps2-elf-ar\\n\\
	RANLIB = mips64r5900el-ps2-elf-ranlib\\n\\
	HAVE_LTO = 0" Makefile || true
fi

# Clean previous build artifacts completely
make clean platform=ps2 || true

# Compile core with LTO disabled entirely and warnings suppressed
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