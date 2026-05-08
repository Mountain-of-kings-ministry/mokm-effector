cmake_minimum_required(VERSION 3.16)

project(mokm_effector VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

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
)

if(CORE_INCLUDE_DIRS)
    target_include_directories(appmokm_effector PRIVATE ${CORE_INCLUDE_DIRS})
endif()

install(TARGETS appmokm_effector
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
