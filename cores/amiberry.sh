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

# Correctly patch libco/sjlj.c for PS2 setjmp/longjmp and bypass unsupported signal stacks
sed -i 's/sigjmp_buf/jmp_buf/g' libco/sjlj.c
sed -i 's/sigsetjmp/setjmp/g' libco/sjlj.c
sed -i 's/siglongjmp/longjmp/g' libco/sjlj.c
sed -i 's/setjmp(\([^,]*\),\s*0)/setjmp(\1)/g' libco/sjlj.c

# Safely disable the sigaltstack/sigaction block to prevent struct errors on PS2
sed -i '/stack_t stack/,/}/c\  void *stack_base = __builtin_alloca(stack_size);' libco/sjlj.c
sed -i 's/if(stack.ss_sp &&.*sigaltstack.*;/if(0) {/' libco/sjlj.c
sed -i 's/struct sigaction.*/int dummy_sig = 0;/g' libco/sjlj.c
sed -i 's/sigaction(.*/;/g' libco/sjlj.c
sed -i 's/sigemptyset(.*/;/g' libco/sjlj.c

# Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }