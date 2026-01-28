Pod::Spec.new do |s|
  s.name             = 'whisper_ggml_plus'
  s.version          = '1.2.7'
  s.summary          = 'Whisper.cpp Flutter plugin with Large-v3-Turbo support.'
  s.description      = <<-DESC
Whisper.cpp Flutter plugin with Large-v3-Turbo (128-mel) support.
                       DESC
  s.homepage         = 'https://github.com/DDULDDUCK/whisper_ggml_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'kapraton@gmail.com' }

  s.dependency 'Flutter'
  s.source           = {
    :git => 'https://github.com/DDULDDUCK/whisper_ggml_plus'
  }
  
  s.platform = :ios, '15.6'
  s.ios.deployment_target  = '15.6'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'IPHONEOS_DEPLOYMENT_TARGET' => '15.6',
    'OTHER_CFLAGS' => '-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL=1 -DGGML_USE_CPU -DGGML_CPU_GENERIC',
    'OTHER_CPLUSPLUSFLAGS' => '-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL=1 -DGGML_USE_CPU -DGGML_CPU_GENERIC',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Classes" "$(PODS_TARGET_SRCROOT)/Classes/whisper/include" "$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml/include" "$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml/src" "$(PODS_TARGET_SRCROOT)/Classes/whisper/ggml/src/ggml-cpu" "$(PODS_TARGET_SRCROOT)/Classes/whisper/src"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }

  # Metal files require MRC (-fno-objc-arc)
  s.subspec 'no-arc' do |ss|
    ss.source_files = 'Classes/whisper/ggml/src/ggml-metal/*.m'
    ss.compiler_flags = '-fno-objc-arc'
  end

  # Main source files
  s.source_files = 'Classes/**/*.{cpp,c,m,mm}'
  
  # Exclude problematic files to prevent duplicate symbols and ARC conflicts
  s.exclude_files = [
    'Classes/whisper/ggml/src/ggml-metal/*.m',
    'Classes/whisper/ggml/src/ggml-cpu/arch/**/*.c',
    'Classes/whisper/ggml/src/ggml-cpu/arch/**/*.cpp'
  ]

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
        
        echo "🔨 Compiling Metal shaders for whisper_ggml_plus iOS..."
        
        cd "${PODS_TARGET_SRCROOT}/Classes/whisper"
        
        # Compile Metal shaders to Air Intermediate Representation, then to Metal Library
        xcrun metal \
          -I"${PODS_TARGET_SRCROOT}/Classes/whisper/ggml/src" \
          -target "air64-${LLVM_TARGET_TRIPLE_VENDOR}-${LLVM_TARGET_TRIPLE_OS_VERSION}${LLVM_TARGET_TRIPLE_SUFFIX:-}" \
          -ffast-math \
          -std=ios-metal2.3 \
          -o "${METAL_LIBRARY_OUTPUT_DIR}/default.metallib" \
          ggml/src/ggml-metal/*.metal
        
        echo "✅ Metal library compiled successfully: ${METAL_LIBRARY_OUTPUT_DIR}/default.metallib"
      SCRIPT
    }
  ]
end
