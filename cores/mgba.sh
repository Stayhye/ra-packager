#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/mgba"
REPO_FOLDER="mgba"
BRANCH_NAME="ps2"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Robustly patch formatting.h to prevent locale_t conflict on PS2
python3 -c '
path = "include/mgba-util/formatting.h"
with open(path, "r") as f:
    content = f.read()
target = "typedef const char* locale_t;"
replacement = "#ifndef _SYS__LOCALE_H_\ntypedef const char* locale_t;\n#endif"
if target in content and "_SYS__LOCALE_H_" not in content:
    content = content.replace(target, replacement)
    with open(path, "w") as f:
        f.write(content)
    print("Patched formatting.h successfully.")
'

## Compile core
make -f Makefile.libretro -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile.libretro -j $PROC_NR platform=ps2 || { exit 1; }