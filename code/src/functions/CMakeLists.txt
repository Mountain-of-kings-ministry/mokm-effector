# Functions module - aggregates all backend function subdirectories

# Existing function subdirectories
add_subdirectory(animation)
add_subdirectory(audio)
add_subdirectory(video)

add_library(functions INTERFACE)
target_link_libraries(functions INTERFACE
    animation
    audio
    video
)
