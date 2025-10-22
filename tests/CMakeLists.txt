enable_testing()

add_executable(aidos_unit tests_main.c tests_shared.c)
target_link_libraries(aidos_unit PRIVATE aidos_shared)

if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
  option(ENABLE_COVERAGE "Enable coverage" ON)
  if(ENABLE_COVERAGE)
    target_compile_options(aidos_unit PRIVATE -fprofile-arcs -ftest-coverage)
    target_link_libraries(aidos_unit PRIVATE gcov)
  endif()
endif()

add_test(NAME unit COMMAND aidos_unit)
