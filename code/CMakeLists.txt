cmake_minimum_required(VERSION 3.16)

project(untitled VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.4)

qt_add_executable(appmokmvideoeditor
    main.cpp
)

add_subdirectory(src)

file(GLOB_RECURSE ICON_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "src/ui/icons/*.svg")
set_source_files_properties(src/ui/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(appmokmvideoeditor
    URI untitled
    VERSION 1.0
    QML_FILES
        src/ui/Main.qml
        src/ui/Theme.qml
        src/ui/media_bin/MediaBinWorkspace.qml
        src/ui/node_editor/NodeEditorWorkspace.qml
        src/ui/timeline/TimelineWorkspace.qml
        src/ui/attribute_inspector/AttributeInspector.qml
        src/ui/project_settings/ProjectSettingsModal.qml
        src/ui/preferences/PreferencesModal.qml
        src/ui/proxy_manager/ProxyDashboard.qml
        src/ui/plugin_manager/PluginManagerModal.qml
        src/ui/keyboard_shortcuts/ShortcutMapper.qml
    RESOURCES
        ${ICON_FILES}
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appmokmvideoeditor PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appmokmvideoeditor
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appmokmvideoeditor
    PRIVATE Qt6::Quick
    PRIVATE mokm_src
)

install(TARGETS appmokmvideoeditor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
