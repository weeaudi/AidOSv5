cmake_minimum_required(VERSION 3.28)

set(TARGET "x86_64" CACHE STRING "Target architecture")
include("toolchain.cmake")

project(aidos LANGUAGES C CXX ASM_NASM)

enable_language(ASM_NASM)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_EXTENSIONS OFF)

option(ENABLE_FUZZING   "Build host fuzz targets" OFF)
option(ENABLE_RTTI_SOME "Allow RTTI selectively" OFF)

# Freestanding defaults (target code)
add_compile_options($<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:-ffreestanding\;-fno-builtin\;-Wall\;-Wextra\;-Werror\;-Wpedantic>)
add_compile_options($<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>)
if(NOT ENABLE_RTTI_SOME)
  add_compile_options($<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>)
endif()

# Kernel/boot specifics
add_compile_options($<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:-mno-red-zone\;-mcmodel=kernel>)

add_subdirectory(src)

if(HOST_MODE)
  add_subdirectory(tests)
endif()

if(ENABLE_FUZZING AND HOST_MODE)
  add_subdirectory(fuzz)
endif()
