

add_subdirectory(shared)
add_subdirectory(hal)
add_subdirectory(bootloader/stage1)
add_subdirectory(bootloader/stage2)
add_subdirectory(kernel)

set(MBR_SRC ${CMAKE_CURRENT_SOURCE_DIR}/mbr.asm)
set(MBR_BIN ${CMAKE_CURRENT_BINARY_DIR}/mbr.bin)

add_custom_command(
    OUTPUT ${MBR_BIN}
    COMMAND ${CMAKE_ASM_NASM_COMPILER} -f bin ${MBR_SRC} -o ${MBR_BIN}
    DEPENDS ${MBR_SRC}
    COMMENT "Assembling ${MBR_SRC} -> ${MBR_BIN}"
    VERBATIM
)

add_custom_target(mbr ALL DEPENDS ${MBR_BIN})
