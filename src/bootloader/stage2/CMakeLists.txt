set(ASM_SOURCES
    arch/${TARGET}/data_grab.asm
    arch/${TARGET}/entry.asm
    arch/${TARGET}/header.asm
)

set(C_SOURCES
    stage2_stub.c
)


add_library(aidos_boot_stage2 OBJECT
    ${ASM_SOURCES}
    ${C_SOURCES}
)

set_source_files_properties(
    ${ASM_SOURCES}
    PROPERTIES COMPILE_FLAGS "-g -F dwarf"
)

set(STAGE2_PUB_INC "${CMAKE_CURRENT_SOURCE_DIR}/include")
set(STAGE2_PRIV_INC "${CMAKE_CURRENT_SOURCE_DIR}/internal")

target_include_directories(aidos_boot_stage2
    PUBLIC "${STAGE2_PUB_INC}"
    PUBLIC $<$<BOOL:${HOST_MODE}>:${STAGE2_PRIV_INC}>
    PRIVATE $<$<NOT:$<BOOL:${HOST_MODE}>>:${STAGE2_PRIV_INC}>
)

set(LDSCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/linker.ld")

target_link_libraries(aidos_boot_stage2 PRIVATE aidos_shared)

add_executable(stage2.elf $<TARGET_OBJECTS:aidos_boot_stage2>)
target_link_options(stage2.elf PRIVATE
    -nostdlib -static -n
    -T "${LDSCRIPT}"
    -Wl,-Map,stage2.map
)
target_link_libraries(stage2.elf PRIVATE aidos_shared)
set_target_properties(stage2.elf PROPERTIES LINK_DEPENDS "${LDSCRIPT}")

set(STAGE2_BIN "${CMAKE_CURRENT_BINARY_DIR}/stage2.bin")
add_custom_command(
    OUTPUT "${STAGE2_BIN}"
    COMMAND "${CMAKE_OBJCOPY}" -O binary $<TARGET_FILE:stage2.elf> "${STAGE2_BIN}"
    DEPENDS stage2.elf
    COMMENT "Objcopy stage2.elf → stage2.bin"
    VERBATIM
)
add_custom_target(stage2_bin ALL DEPENDS "${STAGE2_BIN}")
