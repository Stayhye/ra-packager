#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

## Determine the maximum number of processes that Make can work with.
PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Download the source code.
REPO_URL="https://github.com/libretro/beetle-vb-libretro"
REPO_FOLDER="vb"
BRANCH_NAME="master"
if test ! -d "$REPO_FOLDER"; then
	git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL && cd $REPO_FOLDER || { exit 1; }
else
	cd $REPO_FOLDER && git fetch origin && git reset --hard origin/${BRANCH_NAME} && git checkout ${BRANCH_NAME} || { exit 1; }
fi

## Compile core
make -j $PROC_NR platform=ps2 clean || { exit 1; }
make -j $PROC_NR platform=ps2 || { exit 1; }

## Package all compiled object files into the static library archive (.a) expected by RetroArch
rm -f beetle-vb-libretro_ps2.a
# Gather object files recursively from the repository directory structure
find . -name "*.o" ! -path "./libretro-common/*" > o_files.txt
# If you want libretro-common objects included if they aren't linked otherwise, include them or let the wildcard handle it:
ar rcs beetle-vb-libretro_ps2.a *.o mednafen/*.o mednafen/*/*.o libretro-common/*/*.o 2>/dev/null || true

# Fallback if the hardcoded paths didn't match everything, use the file list
if [ ! -f "beetle-vb-libretro_ps2.a" ] || [ ! -s "beetle-vb-libretro_ps2.a" ]; then
    ar rcs beetle-vb-libretro_ps2.a $(cat o_files.txt) || { exit 1; }
fi
rm -f o_files.txt

# Move it up to the parent directory root where generate_retroarch.sh expects to find $1/$2.a ($REPO_FOLDER/$2.a)
# Wait, generate_retroarch.sh looks for $1/$2.a where $1 is the first argument passed (which is matrix.core_opts[0] -> beetle-vb-libretro)
# But our REPO_FOLDER is "vb". Let's place it correctly:
cd .. || { exit 1; }

# Ensure a directory matching the core name exists, and put the .a file inside it
mkdir -p beetle-vb-libretro
cp "$REPO_FOLDER/beetle-vb-libretro_ps2.a" beetle-vb-libretro/beetle-vb-libretro_ps2.a || { exit 1; }