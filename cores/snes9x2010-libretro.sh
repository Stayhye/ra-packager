#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/libretro/snes9x2010"
REPO_FOLDER="snes9x2010"
BRANCH_NAME="master"

ROOT_DIR=$(pwd)

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd "$REPO_FOLDER" || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# --- PATCH POSIX_MEMALIGN FOR PS2 ---
cat << 'EOF' >> libretro/libretro.c

#ifdef __PS2__
#include <stdlib.h>
#include <malloc.h>
int posix_memalign(void **memptr, size_t alignment, size_t size)
{
   if (!memptr)
      return -1;
   *memptr = memalign(alignment, size);
   if (!*memptr && size != 0)
      return -1;
   return 0;
}
#endif
EOF
# ------------------------------------

make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }

## Locate the archive
FOUND_ARCHIVE=$(ls *.a 2>/dev/null | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    FOUND_ARCHIVE=$(find . -name "*_ps2.a" | head -n 1)
fi

if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

## Copy using absolute paths back to the workspace root
cp -f "$FOUND_ARCHIVE" "$ROOT_DIR/libretro_ps2.a" || { exit 1; }

mkdir -p "$ROOT_DIR/$REPO_FOLDER"
cp -f "$FOUND_ARCHIVE" "$ROOT_DIR/$REPO_FOLDER/snes9x2010_libretro_ps2.a" || { exit 1; }

echo "Successfully built and packaged $FOUND_ARCHIVE"