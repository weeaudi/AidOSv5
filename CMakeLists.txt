cmake_minimum_required(VERSION 3.28)

set(TARGET "x86_64" CACHE STRING "Target architecture")
include("toolchain.cmake")

project(aidos LANGUAGES C CXX ASM_NASM)

enable_language(ASM_NASM)

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_EXTENSIONS OFF)

option(ENABLE_FUZZING "Build host fuzz targets" OFF)
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

# ---- User-tweakable cache variables ----
set(IMAGE_OUT "${CMAKE_SOURCE_DIR}/out/image.img" CACHE STRING "Disk image output path")
set(IMAGE_SIZE_MB 128 CACHE STRING "Total image size in MiB")
set(BOOT_SIZE_MIB 3 CACHE STRING "Boot partition size in MiB")
set(STAGE1_BIN "${CMAKE_BINARY_DIR}/src/bootloader/stage1/stage1.bin" CACHE FILEPATH "Path to 512-byte stage1")
set(STAGE2_BIN "${CMAKE_BINARY_DIR}/src/bootloader/stage2/stage2.bin" CACHE FILEPATH "Path stage2")
set(FAT32_LABEL "AIDOSDATA" CACHE STRING "FAT32 partition label")

message(STATUS ${STAGE1_BIN})
message(STATUS ${STAGE2_BIN})

# ---- Script path (adjust if you place it elsewhere) ----
set(MAKE_IMAGE_SCRIPT "${CMAKE_SOURCE_DIR}/tools/image_gen.sh")

# Ensure output dir exists before the script runs (the script also mkdir -p's, but this helps Ninja/MSBuild track dirs)
add_custom_command(
  OUTPUT ${IMAGE_OUT}
  DEPENDS ${STAGE1_BIN}
  DEPENDS ${STAGE2_BIN}
  COMMAND ${CMAKE_COMMAND} -E make_directory "$<PATH:GET_PARENT_PATH,${IMAGE_OUT}>"
  # Pass variables via environment (script also supports CLI flags if you prefer)
  COMMAND ${CMAKE_COMMAND} -E env
  IMG=${IMAGE_OUT}
  SIZE_MB=${IMAGE_SIZE_MB}
  BOOT_SZ_MIB=${BOOT_SIZE_MIB}
  STAGE1=${STAGE1_BIN}
  STAGE2=${STAGE2_BIN}
  FAT_LABEL="${FAT32_LABEL}"
  bash "${MAKE_IMAGE_SCRIPT}"
  COMMENT "Building disk image: ${IMAGE_OUT}"
  VERBATIM
)

add_custom_target(disk_image ALL DEPENDS ${IMAGE_OUT})
add_dependencies(disk_image stage1_bin stage2_bin)

if(HOST_MODE)
  add_subdirectory(tests)
endif()

if(ENABLE_FUZZING AND HOST_MODE)
  add_subdirectory(fuzz)
endif()
