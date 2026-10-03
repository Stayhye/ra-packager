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

# Apply the libco patch here (or inside libretro depending on repo tree layout)
if [ -f "libco/sjlj.c" ]; then
    SJLJ_PATH="libco/sjlj.c"
elif [ -f "libretro/libco/sjlj.c" ]; then
    SJLJ_PATH="libretro/libco/sjlj.c"
else
    # Fallback to searching for it
    SJLJ_PATH=$(find . -name "sjlj.c" | head -n 1)
fi

if [ -n "$SJLJ_PATH" ]; then
    echo "==> Patching $SJLJ_PATH for PS2..."
    sed -i 's/sigjmp_buf/jmp_buf/g' "$SJLJ_PATH"
    sed -i 's/sigsetjmp/setjmp/g' "$SJLJ_PATH"
    sed -i 's/siglongjmp/longjmp/g' "$SJLJ_PATH"
    sed -i 's/setjmp(\([^,]*\),\s*0)/setjmp(\1)/g' "$SJLJ_PATH"
    sed -i 's/stack_size/16384/g' "$SJLJ_PATH"
    sed -i '/stack_t stack/,/}/c\  void *stack_base = __builtin_alloca(16384);' "$SJLJ_PATH"
    sed -i 's/if(stack.ss_sp &&.*sigaltstack.*;/if(0) {/' "$SJLJ_PATH"
    sed -i 's/struct sigaction.*/int dummy_sig = 0;/g' "$SJLJ_PATH"
    sed -i 's/sigaction(.*/;/g' "$SJLJ_PATH"
    sed -i 's/sigemptyset(.*/;/g' "$SJLJ_PATH"
fi

cd libretro || { exit 1; }

# Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }