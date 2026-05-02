# UI module - aggregates all UI subdirectories

# Existing UI subdirectories
add_subdirectory(audio_editor)
add_subdirectory(color_grading_editor)
add_subdirectory(export_page)
add_subdirectory(node_editor)
add_subdirectory(preferences)
add_subdirectory(project_settings)
add_subdirectory(proxy_manager)
add_subdirectory(video_editor)

# New UI subdirectories
add_subdirectory(media_bin)
add_subdirectory(timeline)
add_subdirectory(attribute_inspector)
add_subdirectory(keyframe_editor)
add_subdirectory(marker_list)
add_subdirectory(effects_browser)
add_subdirectory(history_panel)
add_subdirectory(plugin_manager)
add_subdirectory(keyboard_shortcuts)

add_library(ui INTERFACE)
target_link_libraries(ui INTERFACE
    audio_editor
    color_grading_editor
    export_page
    node_editor
    preferences
    project_settings
    proxy_manager
    video_editor
    media_bin
    timeline
    attribute_inspector
    keyframe_editor
    marker_list
    effects_browser
    history_panel
    plugin_manager
    keyboard_shortcuts
)
