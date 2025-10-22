/* brief: unit test for shared_example */
int aidos_add(int a, int b);

int test_shared_example(void) {
  return aidos_add(2, 2) == 4 ? 0 : 1;
}
