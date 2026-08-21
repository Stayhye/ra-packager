#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

# Try multiple filename variations to support different core naming conventions (underscores vs hyphens)
LIB_NAME_1=$(echo "$2" | tr '-' '_')
LIB_NAME_2=$(echo "$2" | tr '_' '-')

if [ -f "$1/$LIB_NAME_1.a" ]; then
    cp "$1/$LIB_NAME_1.a" RetroArch/libretro_ps2.a || { exit 1; }
elif [ -f "$1/$LIB_NAME_2.a" ]; then
    cp "$1/$LIB_NAME_2.a" RetroArch/libretro_ps2.a || { exit 1; }
elif [ -f "$1/$2.a" ]; then
    cp "$1/$2.a" RetroArch/libretro_ps2.a || { exit 1; }
else
    echo "Error: Could not find static archive for $2 in $1/"
    exit 1
fi

cd RetroArch || { exit 1; }

## Compile core
make -f Makefile.ps2 -j $PROC_NR release || { exit 1; }

## Rename and copy elf
cp retroarchps2.elf ../RA/cores/$2.elf

cd .. || { exit 1; }[cite: 6]