#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

./prepare_release.sh || { exit 1; }

./prepare_retroarch.sh || { exit 1; }

#ecwolf
./cores/ecwolf.sh || { exit 1; }
./generate_retroarch.sh ecwolf ecwolf_libretro_ps2 || { exit 1; }

#mame2003-plus-libretro
./cores/mame2003-plus-libretro.sh || { exit 1; }
./generate_retroarch.sh mame2003-plus-libretro mame2003-plus-libretro_ps2 || { exit 1; }

#mame2010-libretro
./cores/mame2010-libretro.sh || { exit 1; }
./generate_retroarch.sh mame2010-libretro mame2010-libretro_ps2 || { exit 1; }

#pokemini
./cores/pokemini.sh || { exit 1; }
./generate_retroarch.sh pokemini pokemini_libretro_ps2 || { exit 1; }

#gw-libretro
./cores/gw-libretro.sh || { exit 1; }
./generate_retroarch.sh gw-libretro gw-libretro_ps2 || { exit 1; }

#fbalpha2012_cps2
./cores/fbalpha2012_cps2.sh || { exit 1; }
./generate_retroarch.sh fbalpha2012_cps2 fbalpha2012_cps2_libretro_ps2 || { exit 1; }

#genesis_plus_gx_libretro
./cores/genesis_plus_gx_libretro.sh || { exit 1; }
./generate_retroarch.sh genesis_plus_gx_libretro genesis_plus_gx_libretro_ps2 || { exit 1; }

#potator
./cores/potator.sh || { exit 1; }
./generate_retroarch.sh potator potator-libretro_ps2 || { exit 1; }

#mednafen-pce-libretro
./cores/mednafen-pce-libretro.sh || { exit 1; }
./generate_retroarch.sh mednafen-pce-libretro mednafen-pce-libretro_ps2 || { exit 1; }

#mednafen-pce-fast-libretro
./cores/mednafen-pce-fast-libretro.sh || { exit 1; }
./generate_retroarch.sh mednafen_pce_fast_libretro mednafen_pce_fast_libretro_ps2 || { exit 1; }

#beetle-wswan-libretro
./cores/mednafen-wswan-libretro.sh || { exit 1; }
./generate_retroarch.sh beetle-wswan-libretro mednafen-wswan-libretro_ps2 || { exit 1; }

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

#mednafen-vb-libretro
./cores/mednafen-vb-libretro.sh || { exit 1; }
./generate_retroarch.sh mednafen-vb-libretro mednafen-vb-libretro_ps2 || { exit 1; }

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
