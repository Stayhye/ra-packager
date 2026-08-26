Bash

#!/bin/bash
# package.sh 

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/snes9x2010"
REPO_FOLDER="snes9x2010-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# --- PATCH POSIX_MEMALIGN FOR PS2 ---
# snes9x2010 uses libretro/libretro.cpp or libretro.cpp
LIBRETRO_FILE=$(find . -name "libretro.cpp" -o -name "libretro.c" | head -n 1)
if [ -n "$LIBRETRO_FILE" ]; then
    cat << 'EOF' >> "$LIBRETRO_FILE"

#ifdef __PS2__
#include <stdlib.h>
#include <malloc.h>
#ifdef __cplusplus
extern "C" {
#endif
int posix_memalign(void **memptr, size_t alignment, size_t size)
{
   if (!memptr)
      return -1;
   *memptr = memalign(alignment, size);
   if (!*memptr && size != 0)
      return -1;
   return 0;
}
#ifdef __cplusplus
}
#endif
#endif
EOF
fi
# ------------------------------------

## Compile core using native platform=ps2 support from the root directory
make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }

## Return back to the workspace root
cd .. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p "$REPO_FOLDER"
# Only copy if the source and destination paths aren't identical
if [ "$FOUND_ARCHIVE" != "$REPO_FOLDER/snes9x2010_libretro_ps2.a" ]; then
    cp -f "$FOUND_ARCHIVE" "$REPO_FOLDER/snes9x2010_libretro_ps2.a" || { exit 1; }
fi