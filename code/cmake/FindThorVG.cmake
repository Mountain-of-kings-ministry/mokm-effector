# FindThorVG.cmake
# Finds the ThorVG vector graphics library

find_path(ThorVG_INCLUDE_DIR
    NAMES thorvg.h
    PATH_SUFFIXES thorvg-1
)

find_library(ThorVG_LIBRARY
    NAMES thorvg-1 thorvg
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ThorVG DEFAULT_MSG ThorVG_LIBRARY ThorVG_INCLUDE_DIR)

if(ThorVG_FOUND AND NOT TARGET ThorVG::ThorVG)
    add_library(ThorVG::ThorVG UNKNOWN IMPORTED)
    set_target_properties(ThorVG::ThorVG PROPERTIES
        IMPORTED_LOCATION "${ThorVG_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${ThorVG_INCLUDE_DIR}"
    )
endif()

mark_as_advanced(ThorVG_INCLUDE_DIR ThorVG_LIBRARY)
