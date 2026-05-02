add_subdirectory(ui)
add_subdirectory(functions)
add_subdirectory(third_party)

add_library(mokm_src INTERFACE)
target_link_libraries(mokm_src INTERFACE ui functions)
