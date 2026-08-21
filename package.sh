#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

./prepare_release.sh || { exit 1; }

./prepare_retroarch.sh || { exit 1; }

#ecwolf
./cores/ecwolf.sh || { exit 1; }
./generate_retroarch.sh ecwolf ecwolf_libretro_ps2 || { exit 1; }

#mednafen-wswan-libretro
./cores/mednafen-wswan-libretro.sh || { exit 1; }
./generate_retroarch.sh mednafen-wswan-libretro mednafen-wswan-libretro_ps2 || { exit 1; }

#libretro-prboom
./cores/libretro-prboom.sh || { exit 1; }
./generate_retroarch.sh libretro-prboom prboom_libretro_ps2 || { exit 1; }

#libretro-samples
./cores/libretro-samples.sh || { exit 1; }
./generate_retroarch.sh libretro-samples test_libretro_ps2 || { exit 1; }

#picodrive
./cores/picodrive.sh || { exit 1; }
./generate_retroarch.sh picodrive picodrive_libretro_ps2 || { exit 1; }

#mgba
./cores/libretro-mgba.sh || { exit 1; }
./generate_retroarch.sh mgba mgba_libretro_ps2 || { exit 1; }

#gambatte-libretro.sh
./cores/gambatte-libretro.sh || { exit 1; }
./generate_retroarch.sh gambatte-libretro gambatte_libretro_ps2 || { exit 1; }

#snes9x2002
./cores/snes9x2002.sh || { exit 1; }
./generate_retroarch.sh snes9x2002 snes9x2002_libretro_ps2 || { exit 1; }

#libretro-lutro
./cores/libretro-lutro.sh || { exit 1; }
./generate_retroarch.sh libretro-lutro lutro_libretro_ps2 || { exit 1; }

#gpsp
./cores/gpsp.sh || { exit 1; }
./generate_retroarch.sh gpsp gpsp_libretro_ps2 || { exit 1; }

#beetle-vb-libretro
./cores/beetle-vb-libretro.sh || { exit 1; }
./generate_retroarch.sh beetle-vb-libretro beetle-vb-libretro_ps2 || { exit 1; }

#mame2000-libretro
./cores/mame2000-libretro.sh || { exit 1; }
./generate_retroarch.sh mame2000-libretro mame2000-libretro_ps2 || { exit 1; }

#libretro-fceumm
./cores/libretro-fceumm.sh || { exit 1; }
./generate_retroarch.sh libretro-fceumm fceumm_libretro_ps2 || { exit 1; }

## Copy info folder
./libretro-core-info.sh || { exit 1; }

## Salamander to finish
./generate_salamander.sh
