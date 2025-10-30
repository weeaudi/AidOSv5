/* brief: stage2 bootstrap stub
 * context: boot-only
 * notes: placeholder
 */

#include "shared/shared.h"
#include "std/stdint.h"

extern "C" void (*__init_array_start[])(void);
extern "C" void (*__init_array_end[])(void);

static void run_init_array()
{
    for(auto p = __init_array_start; p != __init_array_end; ++p)
        (*p)();
}

static inline void outb(uint16_t p, uint8_t v) { asm volatile("outb %0,%1" ::"a"(v), "Nd"(p)); }

static volatile int touched = 0;

__attribute__((constructor)) static void ctor1()
{
    outb(0xE9, 'C'); // signal: ctor ran
    touched = 0x42;
}

extern "C" void aidos_stage2_main() { run_init_array(); }
