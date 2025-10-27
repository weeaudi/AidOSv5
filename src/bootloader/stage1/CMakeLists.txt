if(HOST_MODE)
    message("Host mode is on. Skipping stage one assembly")
endif()

set(STAGE1_ARCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}")
if(NOT EXISTS "${STAGE1_ARCH_DIR}")
    message(FATAL_ERROR "Unknown stage1 target '${TARGET}'. Expected subdirectory: ${STAGE1_ARCH_DIR}")
endif()

message(STATUS "Building stage1 for target: ${TARGET}")

set(STAGE1_SOURCES
    "${STAGE1_ARCH_DIR}/stage1.asm"
)

add_library(stage1_objs OBJECT ${STAGE1_SOURCES})
target_compile_options(stage1_objs PRIVATE -g -F dwarf)

set(LDSCRIPT "${STAGE1_ARCH_DIR}/linker.ld")

add_executable(stage1.elf $<TARGET_OBJECTS:stage1_objs>)
target_link_options(stage1.elf PRIVATE
    -nostdlib -static -n
    -T "${LDSCRIPT}"
    -Wl,-Map,stage1.map
)
set_target_properties(stage1.elf PROPERTIES LINKER_LANGUAGE C)
set_target_properties(stage1.elf PROPERTIES LINK_DEPENDS "${LDSCRIPT}")

set(STAGE1_BIN "${CMAKE_CURRENT_BINARY_DIR}/stage1.bin")
add_custom_command(
    OUTPUT "${STAGE1_BIN}"
    COMMAND "${CMAKE_OBJCOPY}" -O binary $<TARGET_FILE:stage1.elf> "${STAGE1_BIN}"
    DEPENDS stage1.elf
    COMMENT "Objcopy stage1.elf → stage1.bin"
    VERBATIM
)
add_custom_target(stage1_bin ALL DEPENDS "${STAGE1_BIN}")
