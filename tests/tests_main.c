#include <stdio.h>
#include <stdlib.h>

typedef int (*test_fn)(void);

extern int test_shared_example(void);

static struct {
    const char *name;
    test_fn fn;
} tests[] = {
    {"shared_example", test_shared_example},
};

int main(void)
{
    int fails = 0;
    size_t ntests = sizeof(tests) / sizeof(*tests);
    for(size_t i = 0; i < ntests; ++i) {
        int r = tests[i].fn();
        if(r) {
            fprintf(stderr, "FAIL: %s (%d)\n", tests[i].name, r);
            fails++;
        } else {
            fprintf(stdout, "OK  : %s\n", tests[i].name);
        }
    }
    return fails ? EXIT_FAILURE : EXIT_SUCCESS;
}