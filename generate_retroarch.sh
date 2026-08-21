#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

# Convert hyphens to underscores for the library file name
LIB_NAME=$(echo "$2" | tr '-' '_')

# Copy from core folder to Ra using the correct filename
cp $1/$LIB_NAME.a RetroArch/libretro_ps2.a || { exit 1; }

cd RetroArch || { exit 1; }

## Compile core
make -f Makefile.ps2 -j $PROC_NR release || { exit 1; }

## Rename and copy elf
cp retroarchps2.elf ../RA/cores/$2.elf

cd .. || { exit 1; }