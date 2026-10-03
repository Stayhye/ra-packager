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

# Create directories if they don't exist
mkdir -p libco libretro/libco

# Write a clean, working libco/sjlj.c for PS2 directly
cat << 'EOF' > libco/sjlj.c
#include <stdint.h>
#include <setjmp.h>
#include <stdlib.h>

#define LIBCO_C
#include "libco.h"

typedef struct {
  jmp_buf context;
  void *memory;
  void (*entry)(void);
} cothread_struct;

static thread_local cothread_struct* main_thread = NULL;
static thread_local cothread_struct* current_thread = NULL;

cothread_t co_active(void) {
  if (!main_thread) {
    main_thread = (cothread_struct*)malloc(sizeof(cothread_struct));
    current_thread = main_thread;
  }
  return (cothread_t)current_thread;
}

cothread_t co_derive(void* memory, unsigned int size, void (*coentry)(void)) {
  cothread_struct* thread = (cothread_struct*)memory;
  if (!main_thread) {
    main_thread = (cothread_struct*)malloc(sizeof(cothread_struct));
    current_thread = main_thread;
  }
  thread->memory = memory;
  thread->entry = coentry;
  if (setjmp(thread->context) == 0) {
    return (cothread_t)thread;
  }
  current_thread->entry();
  return 0;
}

cothread_t co_create(unsigned int size, void (*coentry)(void)) {
  void* memory = malloc(size);
  if (!memory) return 0;
  return co_derive(memory, size, coentry);
}

void co_delete(cothread_t handle) {
  cothread_struct* thread = (cothread_struct*)handle;
  if (thread && thread != main_thread) {
    free(thread->memory);
  }
}

void co_switch(cothread_t handle) {
  cothread_struct* old_thread = current_thread;
  current_thread = (cothread_struct*)handle;
  if (setjmp(old_thread->context) == 0) {
    longjmp(current_thread->context, 1);
  }
}

int co_serialise(cothread_t handle, void* buffer) {
  return 0;
}

cothread_t co_deserialise(void const* buffer) {
  return 0;
}
EOF

# Copy to libretro location as well
cp libco/sjlj.c libretro/libco/sjlj.c

cd libretro || { exit 1; }

# Compile core
make -f Makefile -j $PROC_NR platform=ps2 clean || { exit 1; }
make -f Makefile -j $PROC_NR platform=ps2 || { exit 1; }