# Fuzzing with GCC uses AFL++ (afl-gcc/afl-cc). Optional.
find_program(AFL_GCC NAMES afl-gcc afl-cc)
if(NOT AFL_GCC)
  message(STATUS "AFL++ (afl-gcc/afl-cc) not found; fuzz target skipped. Install 'afl++' to enable.")
  return()
endif()

add_executable(fuzz_mbr fuzz_mbr.c)
# Build with normal GCC flags; you can recompile with AFL by invoking tools/build_fuzz_afl.sh
target_link_libraries(fuzz_mbr PRIVATE aidos_shared)

add_custom_target(fuzz-build-afl
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../tools/build_fuzz_afl.sh ${CMAKE_CURRENT_SOURCE_DIR}/fuzz_mbr.c ${CMAKE_BINARY_DIR}/fuzz_mbr_afl
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Building fuzz_mbr with AFL++"
)
