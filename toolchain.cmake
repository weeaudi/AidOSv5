# cmake/cross-preproject.cmake
# Must be included BEFORE the first project() call.

# --- Configurable ---
set(TOOLCHAIN_PREFIX "${TARGET}-elf" CACHE STRING "Cross tool prefix (e.g. x86_64-elf, i686-elf, arm-none-eabi)")
# If you target bare metal, keep Generic. Change if you target a known OS.
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

option(HOST_MODE "Set for if building tests or tools" OFF)

if (HOST_MODE)
  return()
endif()

# ---------- helpers ----------
function(_find_prefixed OUT name)
  set(_tooltemp "")
  unset(_tooltemp)
  unset(_tooltemp CACHE)
  find_program(_tooltemp "${TOOLCHAIN_PREFIX}-${name}")
  if (NOT _tooltemp)
    find_program(_tooltemp "${TOOLCHAIN_PREFIX}-${name}" PATHS /opt/cross/bin NO_DEFAULT_PATH)
  endif()
  set(${OUT} "${_tooltemp}" PARENT_SCOPE)
endfunction()

function(_validate_target COMP VAR_OK)
  set(_ok FALSE)
  if (EXISTS "${COMP}")
    execute_process(
      COMMAND "${COMP}" -dumpmachine
      OUTPUT_VARIABLE _triple
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET
    )
    if (_triple MATCHES "^${TOOLCHAIN_PREFIX}($|[-_])")
      set(_ok TRUE)
    endif()
  endif()
  set(${VAR_OK} ${_ok} PARENT_SCOPE)
endfunction()

# ---------- C (mandatory, strict) ----------
if (CMAKE_C_COMPILER)
  get_filename_component(_cname "${CMAKE_C_COMPILER}" NAME)
  if (NOT _cname MATCHES "^${TOOLCHAIN_PREFIX}-gcc$")
    message(FATAL_ERROR "C compiler must be ${TOOLCHAIN_PREFIX}-gcc (got '${CMAKE_C_COMPILER}')")
  endif()
else()
  _find_prefixed(_cc gcc)
  if (NOT _cc)
    message(FATAL_ERROR "Could not find ${TOOLCHAIN_PREFIX}-gcc in PATH or /opt/cross/bin")
  endif()
  set(CMAKE_C_COMPILER "${_cc}" CACHE FILEPATH "" FORCE)
endif()
_validate_target("${CMAKE_C_COMPILER}" _c_ok)
if (NOT _c_ok)
  message(FATAL_ERROR "Compiler '${CMAKE_C_COMPILER}' does not target '${TOOLCHAIN_PREFIX}-*'")
endif()

# ---------- C++ (optional but strict if present) ----------
if (CMAKE_CXX_COMPILER)
  get_filename_component(_cxxname "${CMAKE_CXX_COMPILER}" NAME)
  if (NOT _cxxname MATCHES "^${TOOLCHAIN_PREFIX}-g\\+\\+$")
    message(FATAL_ERROR "C++ compiler must be ${TOOLCHAIN_PREFIX}-g++ (got '${CMAKE_CXX_COMPILER}')")
  endif()
  _validate_target("${CMAKE_CXX_COMPILER}" _cxx_ok)
  if (NOT _cxx_ok)
    message(FATAL_ERROR "C++ compiler '${CMAKE_CXX_COMPILER}' does not target '${TOOLCHAIN_PREFIX}-*'")
  endif()
else()
  _find_prefixed(_cxx g++)
  if (_cxx)
    set(CMAKE_CXX_COMPILER "${_cxx}" CACHE FILEPATH "" FORCE)
    _validate_target("${CMAKE_CXX_COMPILER}" _cxx_ok)
    if (NOT _cxx_ok)
      message(FATAL_ERROR "C++ compiler '${CMAKE_CXX_COMPILER}' does not target '${TOOLCHAIN_PREFIX}-*'")
    endif()
  endif()
endif()

# ---------- Binutils (prefixed only) ----------
foreach(_t IN ITEMS ar ranlib nm strip objcopy objdump ld)
  _find_prefixed(_tool "${_t}")
  if (_tool)
    if (_t STREQUAL "ar")
      set(CMAKE_AR "${_tool}" CACHE FILEPATH "" FORCE)
      message(STATUS "Cross ar : ${_tool}")
    elseif (_t STREQUAL "ranlib")
      set(CMAKE_RANLIB "${_tool}" CACHE FILEPATH "" FORCE)
      message(STATUS "Cross ranlib : ${_tool}")
    elseif (_t STREQUAL "nm")
      set(CMAKE_NM "${_tool}" CACHE FILEPATH "" FORCE)
      message(STATUS "Cross nm : ${_tool}")
    elseif (_t STREQUAL "strip")
      set(CMAKE_STRIP "${_tool}" CACHE FILEPATH "" FORCE)
      message(STATUS "Cross strip : ${_tool}")
    elseif (_t STREQUAL "objcopy")
      set(CMAKE_OBJCOPY "${_tool}" CACHE FILEPATH "" FORCE)
      message(STATUS "Cross objcopy : ${_tool}")
    elseif (_t STREQUAL "objdump")
      set(OBJDump_EXECUTABLE "${_tool}" CACHE FILEPATH "objdump for this toolchain")
      message(STATUS "Cross objdump : ${_tool}")
    elseif (_t STREQUAL "ld" AND NOT DEFINED CMAKE_LINKER)
      set(CMAKE_LINKER "${_tool}" CACHE FILEPATH "" FORCE)
      message(STATUS "Cross ld : ${_tool}")
    endif()
  endif()
endforeach()

# ---------- NASM ----------
find_program(NASM_EXECUTABLE nasm)
if (NOT NASM_EXECUTABLE)
  find_program(NASM_EXECUTABLE nasm PATHS /opt/cross/bin NO_DEFAULT_PATH)
endif()
if (NOT NASM_EXECUTABLE)
  message(FATAL_ERROR "NASM not found (need 'nasm' in PATH or /opt/cross/bin)")
endif()
set(CMAKE_ASM_NASM_COMPILER "${NASM_EXECUTABLE}" CACHE FILEPATH "" FORCE)

# Object format default based on prefix; override with -DASM_NASM_OBJECT_FORMAT=...
if (NOT DEFINED ASM_NASM_OBJECT_FORMAT)
  if (TOOLCHAIN_PREFIX MATCHES "^x86_64")
    set(ASM_NASM_OBJECT_FORMAT "elf64")
  elseif (TOOLCHAIN_PREFIX MATCHES "^(i[3-6]86|x86)")
    set(ASM_NASM_OBJECT_FORMAT "elf32")
  else()
    set(ASM_NASM_OBJECT_FORMAT "elf64") # fallback; override for non-x86
  endif()
endif()
set(CMAKE_ASM_NASM_OBJECT_FORMAT "${ASM_NASM_OBJECT_FORMAT}" CACHE STRING "NASM object format (elf64, elf32, ...)")

message(STATUS "Cross prefix : ${TOOLCHAIN_PREFIX}")
message(STATUS "C compiler   : ${CMAKE_C_COMPILER}")
if (CMAKE_CXX_COMPILER)
  message(STATUS "C++ compiler : ${CMAKE_CXX_COMPILER}")
endif()
message(STATUS "NASM         : ${CMAKE_ASM_NASM_COMPILER} (format: ${ASM_NASM_OBJECT_FORMAT})")
