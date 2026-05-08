cmake_minimum_required(VERSION 3.16)

project(mokm_effector VERSION 0.1 LANGUAGES CXX)

# ── vcpkg bootstrap ──────────────────────────────────────────
if(DEFINED ENV{VCPKG_ROOT} AND NOT CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
        CACHE STRING "")
endif()

# ── project options ──────────────────────────────────────────
option(MOKM_ENABLE_NODES     "Node graph editor (QtNodes)"       OFF)
option(MOKM_ENABLE_SCRIPTING "QuickJS scripting engine"          OFF)
option(MOKM_ENABLE_INTEROP   "OTIO + OpenFX interoperability"    OFF)
option(MOKM_ENABLE_ALL       "Enable all optional components"    OFF)

if(MOKM_ENABLE_ALL)
    set(MOKM_ENABLE_NODES     ON)
    set(MOKM_ENABLE_SCRIPTING ON)
    set(MOKM_ENABLE_INTEROP   ON)
endif()

# ── standard setup ────────────────────────────────────────────
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

# ── vcpkg dependencies ────────────────────────────────────────
find_package(ThorVG REQUIRED)
find_package(FFMPEG REQUIRED)

if(MOKM_ENABLE_NODES)
    find_package(QtNodes REQUIRED)
endif()
if(MOKM_ENABLE_SCRIPTING)
    find_package(quickjs-ng REQUIRED)
endif()
if(MOKM_ENABLE_INTEROP)
    find_package(OpenTimelineIO REQUIRED)
    find_package(OpenFX REQUIRED)
endif()

qt_add_executable(appmokm_effector
    main.cpp
    resources/resources.qrc
)

add_subdirectory(src)

set_source_files_properties(src/ui/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

file(GLOB_RECURSE CORE_SOURCES "src/core/*.cpp" "src/core/*.h")

file(GLOB CORE_SUBDIRS "src/core/*")
foreach(dir ${CORE_SUBDIRS})
    if(IS_DIRECTORY ${dir})
        list(APPEND CORE_INCLUDE_DIRS ${dir})
    endif()
endforeach()
list(APPEND CORE_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/src/core")

qt_add_qml_module(appmokm_effector
    URI mokm_effector
    VERSION 0.1
    QML_FILES
        src/ui/Main.qml
        src/ui/Theme.qml
        src/ui/SplashScreen.qml
    SOURCES ${CORE_SOURCES}
    RESOURCES resources/resources.qrc
)

set_target_properties(appmokm_effector PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appmokm_effector
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appmokm_effector
    PRIVATE Qt6::Quick
    PRIVATE ThorVG::ThorVG
    PRIVATE ${FFMPEG_LIBRARIES}
)

if(MOKM_ENABLE_NODES)
    target_link_libraries(appmokm_effector PRIVATE QtNodes::QtNodes)
endif()
if(MOKM_ENABLE_SCRIPTING)
    target_link_libraries(appmokm_effector PRIVATE quickjs-ng::quickjs-ng)
endif()
if(MOKM_ENABLE_INTEROP)
    target_link_libraries(appmokm_effector PRIVATE OpenTimelineIO::OpenTimelineIO OpenFX::OpenFX)
endif()

if(FFMPEG_INCLUDE_DIRS)
    target_include_directories(appmokm_effector PRIVATE ${FFMPEG_INCLUDE_DIRS})
endif()

if(CORE_INCLUDE_DIRS)
    target_include_directories(appmokm_effector PRIVATE ${CORE_INCLUDE_DIRS})
endif()

install(TARGETS appmokm_effector
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
