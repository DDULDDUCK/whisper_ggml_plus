# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. We require 3.13 here because the vendored ggml / whisper
# sub-projects use CMake features (target_link_libraries on INTERFACE
# libraries, etc.) that are only stable from 3.13 onwards.
cmake_minimum_required(VERSION 3.13)

set(PROJECT_NAME "whisper_ggml_plus")
project(${PROJECT_NAME} LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Required so the statically built ggml / whisper object files can be
# linked into our shared plugin library.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(PROJECT_VERSION "1.8.3")
set(SOVERSION 1)

# The shared C++ source tree lives under ../macos/Classes (the Windows
# plugin reuses the same layout via the same relative path).
set(PLATFORM_SHARED_ROOT "${CMAKE_CURRENT_LIST_DIR}/../macos/Classes")
set(WHISPER_ROOT_DIR "${PLATFORM_SHARED_ROOT}/whisper")
set(WHISPER_SRC_DIR "${WHISPER_ROOT_DIR}/src")
set(GGML_ROOT_DIR "${WHISPER_ROOT_DIR}/ggml")
set(JSON_ROOT_DIR "${PLATFORM_SHARED_ROOT}/json")

# Build the vendored libraries as static archives and link them into one
# self-contained libwhisper_ggml_plus.so. Matches the Windows plugin.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build vendored libs static" FORCE)
set(GGML_METAL OFF CACHE BOOL "Disable Metal backend on Linux" FORCE)
set(GGML_ACCELERATE OFF CACHE BOOL "Disable Accelerate on Linux" FORCE)
set(GGML_BLAS OFF CACHE BOOL "Disable BLAS auto-linking on Linux" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "Disable OpenMP for initial Linux support" FORCE)
set(GGML_BACKEND_DL OFF CACHE BOOL "Disable dynamic ggml backends" FORCE)
set(WHISPER_COREML OFF CACHE BOOL "Disable CoreML on Linux" FORCE)
set(WHISPER_OPENVINO OFF CACHE BOOL "Disable OpenVINO on Linux" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "Use default warnings" FORCE)
set(GGML_ALL_WARNINGS OFF CACHE BOOL "Use default warnings" FORCE)

add_compile_definitions(
  WHISPER_VERSION="1.8.3"
  GGML_USE_CPU
)

add_subdirectory("${GGML_ROOT_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/ggml")
add_subdirectory("${WHISPER_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/whisper")

add_library(${PROJECT_NAME} SHARED
  "${CMAKE_CURRENT_LIST_DIR}/whisper_ggml_plus.cpp"
)

target_include_directories(${PROJECT_NAME} PRIVATE
  "${CMAKE_CURRENT_LIST_DIR}"
  "${PLATFORM_SHARED_ROOT}"
  "${WHISPER_ROOT_DIR}"
  "${WHISPER_ROOT_DIR}/include"
  "${WHISPER_SRC_DIR}"
  "${GGML_ROOT_DIR}"
  "${GGML_ROOT_DIR}/include"
  "${GGML_ROOT_DIR}/src"
  "${JSON_ROOT_DIR}"
)

target_link_libraries(${PROJECT_NAME} PRIVATE whisper)

# Hide every symbol from the vendored ggml/whisper static libs. Only
# the two functions explicitly tagged with
# __attribute__((visibility("default"))) in whisper_ggml_plus.h --
# request and free_string -- will be exported from the plugin .so.
#
# The CMake VISIBILITY presets affect our own translation units but do
# not propagate into the static archives produced by the ggml/whisper
# sub-projects, so without a linker-level filter every ggml symbol
# would still be globally visible. The version script restricts the
# dynamic symbol table to exactly the two C entry points.
set(WHISPER_GGML_PLUS_VERSION_SCRIPT
  "${CMAKE_CURRENT_LIST_DIR}/whisper_ggml_plus.version"
)

set_target_properties(${PROJECT_NAME} PROPERTIES
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
  OUTPUT_NAME "whisper_ggml_plus"
  LINK_DEPENDS "${WHISPER_GGML_PLUS_VERSION_SCRIPT}"
)

target_link_options(${PROJECT_NAME} PRIVATE
  "LINKER:--version-script=${WHISPER_GGML_PLUS_VERSION_SCRIPT}"
  # Belt-and-braces: error if the script accidentally hides a symbol
  # that is referenced by another exported symbol or by the runtime.
  "LINKER:--no-undefined-version"
)

# Tell Flutter which artifacts to bundle into the built Linux app. The
# variable name MUST be <plugin_name>_bundled_libraries; the previous
# value (ggml_library_flutter_bundled_libraries) was silently ignored.
if(NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(whisper_ggml_plus_bundled_libraries
    $<TARGET_FILE:${PROJECT_NAME}>
    PARENT_SCOPE
  )
endif()
