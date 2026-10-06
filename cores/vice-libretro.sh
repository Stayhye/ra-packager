#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/vice-libretro"
REPO_FOLDER="vice-libretro"
BRANCH_NAME="master"


if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Lower optimization specifically for the problematic reSIDfp config files to avoid GCC reload ICE bug
sed -i 's/-O3/-O2/g' Makefile

# Override optimization for FilterModelConfig files to -O1 by appending custom rules or modifying flags
cat << 'EOF' >> Makefile

# Custom overrides to fix GCC reload ICE on PS2
$(REROOT)/vice/src/residfp/builders/residfp-builder/residfp/FilterModelConfig.o: CXXFLAGS := $(subst -O3,-O1,$(CXXFLAGS))
$(REROOT)/vice/src/residfp/builders/residfp-builder/residfp/FilterModelConfig8580.o: CXXFLAGS := $(subst -O3,-O1,$(CXXFLAGS))
EOF

## Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }