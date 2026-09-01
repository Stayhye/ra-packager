#!/bin/bash
# package.sh for NJEMU-libretro (PS2)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/NJEMU-libretro"
REPO_FOLDER="NJEMU-libretro"
BRANCH_NAME="master"

if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; } 

# Patch emumain.h to use PS2 headers instead of PSP headers when building for PS2
if [ -f "emumain.h" ]; then
    sed -i 's|#include "psp/psp.h"|#ifdef PS2\n#include "ps2/ps2.h"\n#else\n#include "psp/psp.h"\n#endif|g' emumain.h
fi

# Overwrite the repo Makefile with our custom PS2 Makefile
cat << 'EOF' > Makefile
SYSTEM   = cps2
platform = ps2
DEBUG    = 0

TARGET_NAME = njemu

ifeq ($(platform), ps2)
   TARGET := $(TARGET_NAME)_$(SYSTEM)_libretro_$(platform).a
   CC = mips64r5900el-ps2-elf-gcc
   CXX = mips64r5900el-ps2-elf-g++
   AR = mips64r5900el-ps2-elf-ar
   CFLAGS += -G0 -DPS2 -DABGR1555
   CXXFLAGS += -G0 -DPS2 -DABGR1555 -D__linux__ -D__mips__ -D_MIPS_ARCH_R5900 -DARCH_LITTLE_ENDIAN -DNO_DLFCN
   STATIC_LINKING=1
else
   TARGET := $(TARGET_NAME)_$(SYSTEM)_libretro_$(platform).a
   CC = gcc
   CXX = g++
   AR = ar
endif

DEFINES  += -D__LIBRETRO__ -DPS2
DEFINES  += -DRELEASE=0 -DINLINE='static __inline'
DEFINES  += -Ddriver=njemu_driver -Ddriver_t=njemu_driver_t

## CPS1 ##
ifeq ($(SYSTEM), cps1)
DEFINES += -DBUILD_CPS1PS2=1
INCDIRS := -Icps1
OBJS    := cps1/cps1.o cps1/driver.o cps1/memintrf.o cps1/inptport.o cps1/dipsw.o cps1/timer.o
OBJS    += cps1/vidhrdw.o cps1/sprite.o cps1/eeprom.o cps1/kabuki.o sound/2151intf.o sound/ym2151.o sound/qsound.o
OBJS    += cpu/m68000/m68000.o cpu/m68000/c68k.o cpu/z80/z80.o cpu/z80/cz80.o common/coin.o

## CPS2 ##
else ifeq ($(SYSTEM), cps2)
DEFINES += -DBUILD_CPS2PS2=1
INCDIRS := -Icps2
OBJS    := cps2/cps2.o cps2/cps2crpt.o cps2/driver.o cps2/memintrf.o cps2/inptport.o cps2/timer.o
OBJS    += cps2/vidhrdw.o cps2/sprite.o cps2/eeprom.o sound/qsound.o
OBJS    += cpu/m68000/m68000.o cpu/m68000/c68k.o cpu/z80/z80.o cpu/z80/cz80.o common/coin.o
OBJS    += cps2/romcnv.o cps2/rominfo.o

## MVS ##
else ifeq ($(SYSTEM), mvs)
DEFINES += -DBUILD_MVSPS2=1
INCDIRS := -Imvs
OBJS    := mvs/mvs.o mvs/driver.o mvs/memintrf.o mvs/inptport.o mvs/dipsw.o mvs/timer.o
OBJS    += mvs/vidhrdw.o mvs/sprite.o mvs/pd4990a.o mvs/neocrypt.o mvs/biosmenu.o sound/2610intf.o sound/ym2610.o
OBJS    += cpu/m68000/m68000.o cpu/m68000/c68k.o cpu/z80/z80.o cpu/z80/cz80.o

## NCDZ ##
else
DEFINES += -DBUILD_NCDZPS2=1
INCDIRS := -Incdz
OBJS    := ncdz/ncdz.o ncdz/cdda.o ncdz/cdrom.o ncdz/driver.o ncdz/memintrf.o ncdz/inptport.o ncdz/timer.o
OBJS    += ncdz/vidhrdw.o ncdz/sprite.o sound/2610intf.o sound/ym2610.o
OBJS    += cpu/m68000/m68000.o cpu/m68000/c68k.o cpu/z80/z80.o cpu/z80/cz80.o

endif

ifeq ($(DEBUG), 1)
    CFLAGS += -O0 -g
    CXXFLAGS += -O0 -g
else
    CFLAGS += -O2
    CXXFLAGS += -O2
endif

CFLAGS  += $(DEFINES)
CXXFLAGS += $(DEFINES)

CFLAGS += -fstrict-aliasing -falign-functions=32 -falign-loops -falign-labels -falign-jumps -Wall -Wundef -Wpointer-arith -Wbad-function-cast -Wwrite-strings -Wmissing-prototypes -Wsign-compare -DZLIB_CONST
CFLAGS += -fomit-frame-pointer

CXXFLAGS += -fstrict-aliasing -falign-functions=32 -falign-loops -falign-labels -falign-jumps -Wall -Wundef -Wpointer-arith -Wwrite-strings -Wsign-compare -DZLIB_CONST
CXXFLAGS += -fomit-frame-pointer

OBJS += zip/zfile.o
OBJS += common/cache.o common/loadrom.o common/state.o
OBJS += ps2/filer.o ps2/ui_text.o ps2/input.o ps2/ticker.o ps2/sound.o ps2/video.o
OBJS += sound/sndintrf.o

OBJS += emumain.o
OBJS += libretro.o

INCDIRS += -I.
ifdef PS2SDK
INCDIRS += -I$(PS2SDK)/ee/include -I$(PS2SDK)/common/include
endif

all: $(TARGET)

$(TARGET): $(OBJS)
	$(AR) rcs $@ $(OBJS)

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(INCDIRS)

%.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(INCDIRS)

clean-objs:
	rm -f $(OBJS)

clean:
	rm -f $(OBJS)
	rm -f $(TARGET)

.PHONY: clean clean-objs $(TARGET)
EOF

## Build all supported systems for NJEMU (cps1, cps2, mvs, ncdz)
for sys in cps1 cps2 mvs ncdz; do
    echo "Building NJEMU system: $sys"
    make -j $PROC_NR platform=ps2 SYSTEM=$sys clean || { exit 1; }
    make -j $PROC_NR platform=ps2 SYSTEM=$sys || { exit 1; }
done

cd .. || { exit 1; }

## Copy the generated static archives
mkdir -p njemu-libretro
for sys in cps1 cps2 mvs ncdz; do
    if [ -f "$REPO_FOLDER/njemu_${sys}_libretro_ps2.a" ]; then
        cp -f "$REPO_FOLDER/njemu_${sys}_libretro_ps2.a" ./njemu_${sys}_libretro_ps2.a || { exit 1; }
        cp -f "$REPO_FOLDER/njemu_${sys}_libretro_ps2.a" njemu-libretro/ || { exit 1; }
    fi
done