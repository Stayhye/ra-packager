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

# Force -O0 specifically for the problematic reSIDfp config translation units to bypass GCC reload ICE
cat << 'EOF' >> Makefile

# Bypass GCC reload ICE by dropping optimization to -O0 for these two files
$(filter %FilterModelConfig.o, $(OBJECTS)): CXXFLAGS := $(subst -O3,-O0,$(subst -O2,-O0,$(subst -O1,-O0,$(CXXFLAGS)))) -O0
$(filter %FilterModelConfig8580.o, $(OBJECTS)): CXXFLAGS := $(subst -O3,-O0,$(subst -O2,-O0,$(subst -O1,-O0,$(CXXFLAGS)))) -O0
EOF

## Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }