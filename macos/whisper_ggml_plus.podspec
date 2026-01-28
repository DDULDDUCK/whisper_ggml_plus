Pod::Spec.new do |s|
  s.name             = 'whisper_ggml_plus'
  s.version          = '1.2.7'
  s.summary          = 'Whisper.cpp Flutter plugin with Large-v3-Turbo support.'
  s.description      = <<-DESC
Whisper.cpp Flutter plugin with Large-v3-Turbo (128-mel) support.
                       DESC
  s.homepage         = 'https://github.com/DDULDDUCK/whisper_ggml_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'www.antonkarpenko.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'MACOSX_DEPLOYMENT_TARGET' => '10.15',
    'OTHER_CFLAGS' => '-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL=1 -DGGML_USE_CPU',
    'OTHER_CPLUSPLUSFLAGS' => '-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL=1 -DGGML_USE_CPU',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Classes/whisper" "$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml-cpu" "$(PODS_TARGET_SRCROOT)/Classes/whisper/coreml"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }
  s.frameworks = 'CoreML', 'Metal', 'Foundation'
  s.swift_version = '5.0'

  # Compile Metal shaders to default.metallib during pod install
  s.script_phases = [
    {
      :name => 'Compile Metal Shaders',
      :input_files => ["${PODS_TARGET_SRCROOT}/Classes/whisper/ggml/src/ggml-metal/*.metal"],
      :output_files => ["${METAL_LIBRARY_OUTPUT_DIR}/default.metallib"],
      :execution_position => :after_compile,
      :script => <<-SCRIPT
        set -e
        set -u
        set -o pipefail
        
        echo "🔨 Compiling Metal shaders for whisper_ggml_plus macOS..."
        
        cd "${PODS_TARGET_SRCROOT}/Classes/whisper"
        
        # Compile Metal shaders to Air Intermediate Representation, then to Metal Library
        xcrun metal \
          -I"${PODS_TARGET_SRCROOT}/Classes/whisper/ggml/src" \
          -target "air64-${LLVM_TARGET_TRIPLE_VENDOR}-${LLVM_TARGET_TRIPLE_OS_VERSION}${LLVM_TARGET_TRIPLE_SUFFIX:-}" \
          -ffast-math \
          -std=macos-metal2.3 \
          -o "${METAL_LIBRARY_OUTPUT_DIR}/default.metallib" \
          ggml/src/ggml-metal/*.metal
        
        echo "✅ Metal library compiled successfully: ${METAL_LIBRARY_OUTPUT_DIR}/default.metallib"
      SCRIPT
    }
  ]
end