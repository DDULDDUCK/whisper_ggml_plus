cmake_minimum_required(VERSION 3.10)

project(whisper_flutter_library LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)

# Optimization flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -fdata-sections -ffunction-sections")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -fdata-sections -ffunction-sections")

# Source roots
set(WHISPER_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/src")
set(WHISPER_SRC_DIR "${WHISPER_ROOT_DIR}/src")
set(GGML_ROOT_DIR "${WHISPER_ROOT_DIR}/ggml")
set(GGML_SRC_DIR "${GGML_ROOT_DIR}/src")
set(GGML_CPU_SRC_DIR "${GGML_SRC_DIR}/ggml-cpu")

# Include directories
include_directories("${WHISPER_ROOT_DIR}")
include_directories("${WHISPER_ROOT_DIR}/include")
include_directories("${WHISPER_SRC_DIR}")
include_directories("${GGML_ROOT_DIR}/include")
include_directories("${GGML_SRC_DIR}")
include_directories("${GGML_CPU_SRC_DIR}")

# Collect all engine source files
file(GLOB WHISPER_SRC
    "${WHISPER_SRC_DIR}/*.cpp"
    "${WHISPER_SRC_DIR}/*.c"
    "${GGML_SRC_DIR}/*.cpp"
    "${GGML_SRC_DIR}/*.c"
    "${GGML_CPU_SRC_DIR}/*.cpp"
    "${GGML_CPU_SRC_DIR}/*.c"
)

add_library(whisper ${WHISPER_SRC})

if (ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(whisper PRIVATE -march=armv8.2-a+fp16)
elseif (ANDROID_ABI STREQUAL "armeabi-v7a")
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
