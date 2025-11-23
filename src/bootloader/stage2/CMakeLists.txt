set(ASM_SOURCES
    arch/${TARGET}/data_grab.asm
    arch/${TARGET}/entry.asm
    arch/${TARGET}/header.asm
    arch/${TARGET}/init32.asm
    arch/${TARGET}/init64.asm
)

set(C_SOURCES
    stage2_init.cpp
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

target_link_libraries(aidos_boot_stage2 PRIVATE aidos_shared hal)
target_include_directories(aidos_boot_stage2 PRIVATE
    ${CMAKE_SOURCE_DIR}/include/
    ${CMAKE_CURRENT_LIST_LINE}/include
    ${CMAKE_CURRENT_LIST_LINE}/internal
)

# Helper to ask the active compiler where a file lives.
function(compiler_file OUT NAME)
    # Try C compiler, then C++ compiler.
    execute_process(COMMAND ${CMAKE_C_COMPILER} -print-file-name=${NAME}
        OUTPUT_VARIABLE _p1 OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT _p1 OR _p1 STREQUAL "${NAME}")
        execute_process(COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=${NAME}
            OUTPUT_VARIABLE _p1 OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif()
    # If the compiler echoes the name unchanged, treat as not found.
    if(NOT _p1 OR _p1 STREQUAL "${NAME}")
        set(_p1 "")
    endif()
    set(${OUT} "${_p1}" PARENT_SCOPE)
endfunction()

compiler_file(CRTBEGIN_PATH crtbegin.o)
compiler_file(CRTEND_PATH crtend.o)

add_library(crti_obj OBJECT arch/${TARGET}/crti.asm)
add_library(crtn_obj OBJECT arch/${TARGET}/crtn.asm)
set_source_files_properties(
    arch/${TARGET}/crti.asm arch/${TARGET}/crtn.asm
    PROPERTIES COMPILE_FLAGS "-g -F dwarf"
)

add_executable(stage2.elf)
target_sources(stage2.elf PRIVATE
    $<TARGET_OBJECTS:crti_obj>
    ${CRTBEGIN_PATH}
    $<TARGET_OBJECTS:aidos_boot_stage2>
    ${CRTEND_PATH}
    $<TARGET_OBJECTS:crtn_obj>
)
target_link_options(stage2.elf PRIVATE
    -nostdlib -static -n
    -T "${LDSCRIPT}"
    -Wl,-Map,stage2.map
)
target_link_libraries(stage2.elf PRIVATE aidos_shared hal)
target_include_directories(stage2.elf PRIVATE
    ${CMAKE_SOURCE_DIR}/include/
)
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
