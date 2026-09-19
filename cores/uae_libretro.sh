#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/libretro-uae"
REPO_FOLDER="uae_libretro"
BRANCH_NAME="master"


if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

## Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }

# Fix conflicting integer types between sysdeps.h and types.h for PS2 toolchain
sed -i '/typedef unsigned int uae_u32;/s/^/\/\//' sources/src/include/sysdeps.h
sed -i '/typedef int uae_s32;/s/^/\/\//' sources/src/include/sysdeps.h
sed -i '/typedef uae_u32 uaecptr;/s/^/\/\//' sources/src/include/sysdeps.h

# Fix timezone macro conflict
sed -i '/#define timezone 0/s/^/\/\//' sources/src/include/sysdeps.h

# Create a dummy dlfcn.h header to satisfy uae_dlopen.c on platforms without dynamic loading
cat << 'EOF' > sources/src/include/dlfcn.h
#ifndef DLFCN_H
#define DLFCN_H

#define RTLD_LAZY 1
#define RTLD_NOW 2

static inline void *dlopen(const char *file, int mode) { (void)file; (void)mode; return (void*)0; }
static inline void *dlsym(void *handle, const char *name) { (void)handle; (void)name; return (void*)0; }
static inline int dlclose(void *handle) { (void)handle; return 0; }
static inline char *dlerror(void) { return "Dynamic loading not supported on PS2"; }

#endif
EOF

make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }