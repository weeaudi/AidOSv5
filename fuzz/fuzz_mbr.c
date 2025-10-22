#include <stddef.h>
#include <stdint.h>

int aidos_add(int a, int b); /* placeholder use */

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if(size >= 2) {
        (void)aidos_add(data[0], data[1]);
    }
    return 0;
}
