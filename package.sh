#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

mkdir -p RA || { exit 1; }
mkdir -p RA/cores || { exit 1; }

./prepare_retroarch.sh || { exit 1; }

./prboom.sh || { exit 1; }
./generate_retroarch.sh libretro-prboom prboom_libretro_ps2 || { exit 1; }


## Salamander to finish
./generate_salamander.sh
