if(HOST_MODE)
  set(HAL_BACKEND_DIR ${CMAKE_CURRENT_SOURCE_DIR}/host)
else()
  set(HAL_BACKEND_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET})
endif()

file(GLOB_RECURSE HAL_SRCS CONFIGURE_DEPENDS
  ${HAL_BACKEND_DIR}/*.cpp
  ${HAL_BACKEND_DIR}/*.c
)

add_library(hal STATIC ${HAL_SRCS})

target_include_directories(hal
  PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)

if(HOST_MODE)
  target_compile_definitions(hal PUBLIC HAL_HOST_MODE=1)
else()
  target_compile_definitions(hal PUBLIC HAL_HOST_MODE=0 HAL_TARGET_STR="${TARGET}")
endif()

if(NOT HOST_MODE)
  target_compile_options(hal PRIVATE
    -ffreestanding -fno-exceptions -fno-rtti -fno-pic -fno-stack-protector -g -O0
  )
  target_link_options(hal PRIVATE
    -nostdlib -Wl,--gc-sections -no-pie
  )
endif()