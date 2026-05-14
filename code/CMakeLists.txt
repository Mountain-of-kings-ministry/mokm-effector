cmake_minimum_required(VERSION 3.16)

# ── vcpkg bootstrap ──────────────────────────────────────────
if(DEFINED ENV{VCPKG_ROOT} AND NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
        CACHE STRING "")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ── Project Options ──────────────────────────────────────────
option(MOKM_ENABLE_NODES     "Node graph editor (Qt-Node-editor)" ON)
option(MOKM_ENABLE_SCRIPTING "QuickJS scripting engine"          OFF)
option(MOKM_ENABLE_INTEROP   "OTIO + OpenFX interoperability"    OFF)
option(MOKM_ENABLE_ALL       "Enable all optional components"    OFF)

if(MOKM_ENABLE_ALL)
  set(MOKM_ENABLE_NODES     ON CACHE BOOL "" FORCE)
  set(MOKM_ENABLE_SCRIPTING ON CACHE BOOL "" FORCE)
  set(MOKM_ENABLE_INTEROP   ON CACHE BOOL "" FORCE)
endif()

# ── vcpkg Manifest Features ──────────────────────────────────
# NOTE: All optional features are now handled via local subdirectories
# or temporarily disabled to ensure build success with standalone sources.
set(VCPKG_MANIFEST_FEATURES "")

project(mokm_effector VERSION 0.1 LANGUAGES C CXX)

# ── Standard Setup ───────────────────────────────────────────
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOMOC ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Qt6 REQUIRED COMPONENTS Quick Widgets OpenGL Multimedia QuickShapes QuickEffects)

qt_standard_project_setup(REQUIRES 6.10)

# ── vcpkg Dependencies ───────────────────────────────────────
find_package(ThorVG REQUIRED)
find_package(FFMPEG REQUIRED)

# ── Executable + QML Module ─────────────────────────────────
qt_add_executable(appmokm_effector
    main.cpp
    resources/resources.qrc
    resources/color_widgets.qrc
)


# ── Local Third Party Libraries ──────────────────────────────

# ── VST3 SDK ─────────────────────────────────────────────────
set(VST3_SDK_ROOT "${CMAKE_SOURCE_DIR}/../third_parties/vst3sdk")
if(EXISTS "${VST3_SDK_ROOT}/CMakeLists.txt")
    # Disable VST3 samples and unnecessary components to speed up build and fix Wayland error
    set(SMTG_ENABLE_VSTGUI_SUPPORT OFF CACHE BOOL "" FORCE)
    set(SMTG_ENABLE_VST3_HOSTING_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(SMTG_ENABLE_VST3_PLUGIN_EXAMPLES OFF CACHE BOOL "" FORCE)
    
    add_subdirectory("${VST3_SDK_ROOT}" "${CMAKE_BINARY_DIR}/vst3sdk" EXCLUDE_FROM_ALL)
    message(STATUS "VST3 SDK included from local source")
else()
    message(WARNING "VST3 SDK NOT found at ${VST3_SDK_ROOT}")
endif()

# ── CLAP Audio Plugin Support ────────────────────────────────
if(EXISTS "${CMAKE_SOURCE_DIR}/../third_parties/clap-main/include/clap/clap.h")
  add_library(CLAP INTERFACE)
  target_include_directories(CLAP INTERFACE
        "${CMAKE_SOURCE_DIR}/../third_parties/clap-main/include")
  message(STATUS "CLAP headers found at third_parties/clap-main")
else()
  message(STATUS "CLAP headers NOT found — audio plugin support disabled")
endif()

add_subdirectory(src)

set_source_files_properties(src/ui/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

file(GLOB_RECURSE CORE_SOURCES "src/core/*.cpp" "src/core/*.h")

qt_add_qml_module(appmokm_effector
    URI mokm_effector
    VERSION 0.1
    QML_FILES
        src/ui/Main.qml
        src/ui/Theme.qml
        src/ui/SplashScreen.qml
        src/ui/ProjectProperties.qml
        src/ui/components/ProjectBin.qml
        src/ui/components/EffectorPropertiesPanel.qml
        src/ui/components/Toolbar.qml
        src/ui/components/TimeRuler.qml
        src/ui/components/Timeline.qml
        src/ui/components/TopBar.qml
        src/ui/components/BottomTabBar.qml
        src/ui/components/KeyframeEditor.qml
        src/ui/components/NodeEditor.qml
        src/ui/components/AudioEditor.qml
        src/ui/components/ColorGradingEditor.qml
        src/ui/components/PreferencesDialog.qml
        src/ui/components/FaderSection.qml
        src/ui/components/PluginRack.qml
        src/ui/components/PluginManagerPopup.qml
        src/ui/components/NodeGraphPopup.qml
    SOURCES ${CORE_SOURCES}
)

# ── Linking ─────────────────────────────────────────────────
target_link_libraries(appmokm_effector
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Widgets
    PRIVATE Qt6::OpenGL
    PRIVATE Qt6::Multimedia
    PRIVATE Qt6::QuickShapes
    PRIVATE Qt6::QuickEffects
    PRIVATE ThorVG::ThorVG
    PRIVATE ${FFMPEG_LIBRARIES}
)

if(TARGET sdk)
    target_link_libraries(appmokm_effector PRIVATE sdk sdk_hosting)
    target_compile_definitions(appmokm_effector PRIVATE MOKM_ENABLE_VST3=1)
endif()

if(TARGET CLAP)
    target_link_libraries(appmokm_effector PRIVATE CLAP)
    target_compile_definitions(appmokm_effector PRIVATE MOKM_ENABLE_CLAP=1)
endif()


if(MOKM_ENABLE_NODES)
  file(GLOB_RECURSE NODE_SOURCES
        CONFIGURE_DEPENDS
        "src/nodes/*.cpp"
        "src/nodes/*.h"
    )

  target_sources(appmokm_effector PRIVATE ${NODE_SOURCES})

  target_include_directories(appmokm_effector PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/nodes
    )

  target_link_libraries(appmokm_effector PRIVATE
        NodeEditor NodeEditorCore Qt6::QuickShapes
    )

  target_compile_definitions(appmokm_effector PRIVATE
        MOKM_ENABLE_NODES
    )

  set_property(TARGET appmokm_effector APPEND PROPERTY
      QT_QML_IMPORT_PATH "${CMAKE_SOURCE_DIR}/../third_parties/Qt-Node-editor/NodeEditor"
  )
endif()

if(MOKM_ENABLE_SCRIPTING)
  target_link_libraries(appmokm_effector PRIVATE qjs)
  target_compile_definitions(appmokm_effector PRIVATE MOKM_ENABLE_SCRIPTING)
endif()

if(MOKM_ENABLE_INTEROP)
  target_link_libraries(appmokm_effector PRIVATE opentimelineio opentime OfxHost OfxSupport)
  target_compile_definitions(appmokm_effector PRIVATE MOKM_ENABLE_INTEROP)
endif()

if(FFMPEG_INCLUDE_DIRS)
  target_include_directories(appmokm_effector PRIVATE ${FFMPEG_INCLUDE_DIRS})
endif()

# ── Include Directories ─────────────────────────────────────
target_include_directories(appmokm_effector PRIVATE src/core)

# ── Install ─────────────────────────────────────────────────
set_target_properties(appmokm_effector PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.mokm.mokmefx
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

install(TARGETS appmokm_effector
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
