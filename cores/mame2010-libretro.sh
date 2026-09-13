#!/bin/bash
# package.sh

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/mame2010-libretro.git"
##REPO_URL="https://github.com/libretro/mame2000-libretro.git"
REPO_FOLDER="mame2010-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

# Patch alpha68k.c to fix -Werror format string and cast-align issues
echo "Patching src/mame/drivers/alpha68k.c..."
sed -i 's/logerror("%04x:  Alpha write trigger at %04x (%04x)\\n", cpu_get_pc(space->cpu), offset, data);/logerror("%04x:  Alpha write trigger at %04x (%04x)\\n", (unsigned int)cpu_get_pc(space->cpu), (unsigned int)offset, (unsigned int)data);/g' src/mame/drivers/alpha68k.c
sed -i 's/logerror("%04x:  Alpha read trigger at %04x\\n", cpu_get_pc(space->cpu), offset);/logerror("%04x:  Alpha read trigger at %04x\\n", (unsigned int)cpu_get_pc(space->cpu), (unsigned int)offset);/g' src/mame/drivers/alpha68k.c
sed -i 's/uint16_t \*rom = (uint16_t \*)memory_region(machine, "maincpu");/uint16_t *rom = (uint16_t *)(void *)memory_region(machine, "maincpu");/g' src/mame/drivers/alpha68k.c

# Patch src/emu/mmry.h to fix cast-align warnings on direct read functions
echo "Patching src/emu/mmry.h..."
sed -i 's/return \*(uint16_t \*)&space->direct.decrypted\[byteaddress & space->direct.bytemask\];/return \*(uint16_t \*)(void *)&space->direct.decrypted[byteaddress & space->direct.bytemask];/g' src/emu/mmry.h
sed -i 's/return \*(uint32_t \*)&space->direct.decrypted\[byteaddress & space->direct.bytemask\];/return \*(uint32_t \*)(void *)&space->direct.decrypted[byteaddress & space->direct.bytemask];/g' src/emu/mmry.h
sed -i 's/return \*(uint64_t \*)&space->direct.decrypted\[byteaddress & space->direct.bytemask\];/return \*(uint64_t \*)(void *)&space->direct.decrypted[byteaddress & space->direct.bytemask];/g' src/emu/mmry.h
sed -i 's/return \*(uint16_t \*)&space->direct.raw\[byteaddress & space->direct.bytemask\];/return \*(uint16_t \*)(void *)&space->direct.raw[byteaddress & space->direct.bytemask];/g' src/emu/mmry.h
sed -i 's/return \*(uint32_t \*)&space->direct.raw\[byteaddress & space->direct.bytemask\];/return \*(uint32_t \*)(void *)&space->direct.raw[byteaddress & space->direct.bytemask];/g' src/emu/mmry.h
sed -i 's/return \*(uint64_t \*)&space->direct.raw\[byteaddress & space->direct.bytemask\];/return \*(uint64_t \*)(void *)&space->direct.raw[byteaddress & space->direct.bytemask];/g' src/emu/mmry.h

## Compile core using native platform=ps2 support from the root directory
make -j $PROC_NR platform=ps2 || { exit 1; }

## Inspect binary size and sections locally in the script (without destroying symbols)
FOUND_ARCHIVE=$(find . -name "*_ps2.a" | head -n 1)
if [ -n "$FOUND_ARCHIVE" ]; then
    echo "=== File Size ==="
    ls -lh "$FOUND_ARCHIVE"
    
    echo "=== Section Breakdown ==="
    mips64r5900el-ps2-elf-size -A "$FOUND_ARCHIVE"
    
    echo "=== Top 20 Largest Symbols ==="
    mips64r5900el-ps2-elf-nm --size-sort -S "$FOUND_ARCHIVE" | tail -n 20
fi

## Return back to the workspace root
cd .. || { exit 1; }

## Find and copy the generated archive
FOUND_ARCHIVE=$(find "$REPO_FOLDER" -name "*_ps2.a" | head -n 1)
if [ -z "$FOUND_ARCHIVE" ]; then
    echo "Error: Could not find generated static archive (*_ps2.a)"
    exit 1
fi

cp -f "$FOUND_ARCHIVE" ./libretro_ps2.a || { exit 1; }

mkdir -p mame2010_libretro
cp -f "$FOUND_ARCHIVE" mame2010_libretro/mame2010_libretro_ps2.a || { exit 1; }