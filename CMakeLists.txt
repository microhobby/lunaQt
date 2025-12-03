cmake_minimum_required(VERSION 3.16)
project(demo LANGUAGES CXX C)

set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Quick3D Quick3DAssetUtils)

qt_add_executable(demo WIN32
    main.cpp
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(demo PRIVATE QT_QML_DEBUG)
endif()

set_target_properties(demo PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "bin"
    ARCHIVE_OUTPUT_DIRECTORY "lib"
    LIBRARY_OUTPUT_DIRECTORY "lib"
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(demo PRIVATE
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::Quick3D
    Qt::Quick3DAssetUtils
)

qt_add_qml_module(demo
    URI demo
    VERSION 1.0
    QML_FILES
        "QML/main.qml"
        "QML/Scene.ui.qml"
    RESOURCES
        "QML/assets/torizon-logo.png"
        "QML/assets/model.glb"
)

# Copy model.glb to bin folder for runtime loading
add_custom_command(TARGET demo POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_SOURCE_DIR}/QML/assets/model.glb
        $<TARGET_FILE_DIR:demo>/model.glb
    COMMENT "Copying model.glb to output directory"
)
