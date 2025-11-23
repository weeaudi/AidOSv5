add_library(aidos_shared STATIC
  pci.cpp
)
target_include_directories(aidos_shared PUBLIC ${CMAKE_SOURCE_DIR}/include)
