#!/bin/bash
# package.sh by Francisco Javier Trujillo Mata (fjtrujy@gmail.com)

PROC_NR=$(getconf _NPROCESSORS_ONLN)

REPO_URL="https://github.com/Stayhye/amiberry"
REPO_FOLDER="amiberry"
BRANCH_NAME="master"


if test ! -d "$REPO_FOLDER"; then
    git clone --recurse-submodules --depth 1 -b $BRANCH_NAME $REPO_URL $REPO_FOLDER || { exit 1; }
fi

cd $REPO_FOLDER || { exit 1; }
git fetch origin
git reset --hard origin/${BRANCH_NAME}
git checkout ${BRANCH_NAME} || { exit 1; }

cd libretro || { exit 1; }

# Patch libco/sjlj.c for PS2 setjmp and remove unsupported sigaltstack blocks
sed -i 's/sigjmp_buf/jmp_buf/g' libco/sjlj.c
sed -i 's/sigsetjmp/setjmp/g' libco/sjlj.c
sed -i 's/siglongjmp/longjmp/g' libco/sjlj.c
sed -i 's/setjmp(\([^,]*\),\s*0)/setjmp(\1)/g' libco/sjlj.c
sed -i 's/if(stack.ss_sp &&.*sigaltstack.*;/if(0) {/g' libco/sjlj.c
sed -i 's/SA_ONSTACK/0/g' libco/sjlj.c
sed -i 's/struct sigaction/int/g' libco/sjlj.c
sed -i 's/sigaction(/,\/./g' libco/sjlj.c

# Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }