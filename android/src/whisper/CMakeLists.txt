cmake_minimum_required(VERSION 3.10)

project(whisper_flutter_library LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)

# Optimization flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -fdata-sections -ffunction-sections")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -fdata-sections -ffunction-sections")

# Include directories
include_directories(src)

# Collect all engine source files
file(GLOB WHISPER_SRC 
    src/*.cpp 
    src/*.c
)

add_library(whisper ${WHISPER_SRC})

if (${ANDROID_ABI} STREQUAL "arm64-v8a")
    target_compile_options(whisper PRIVATE -march=armv8.2-a+fp16)
elseif (${ANDROID_ABI} STREQUAL "armeabi-v7a")
    target_compile_options(whisper PRIVATE -mfpu=neon-vfpv4)
endif ()

# Main bridge library
add_library(whisper_flutter SHARED main.cpp)
target_link_libraries(whisper_flutter PRIVATE whisper)
target_compile_definitions(whisper_flutter PUBLIC DART_SHARED_LIB)

set_target_properties(whisper_flutter PROPERTIES
  PUBLIC_HEADER src/whisper.h 
  OUTPUT_NAME "whisper"
)
