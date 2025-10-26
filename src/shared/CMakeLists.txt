add_library(aidos_shared STATIC
  shared_example.c
)
target_include_directories(aidos_shared PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
