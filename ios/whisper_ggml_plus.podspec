Pod::Spec.new do |s|
  s.name             = 'whisper_ggml_plus'
  s.version          = '1.3.1'
  s.summary          = 'Whisper.cpp Flutter plugin with Large-v3-Turbo support.'
  s.description      = <<-DESC
Whisper.cpp Flutter plugin with Large-v3-Turbo (128-mel) support.
                       DESC
  s.homepage         = 'https://github.com/DDULDDUCK/whisper_ggml_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'www.antonkarpenko.com' }
  s.source           = { :path => '.' }
  s.source_files = 'whisper_ggml_plus/Classes/**/*.{cpp,c,h,hpp,m,mm}'
  s.requires_arc = ['whisper_ggml_plus/Classes/whisper/src/coreml/*.{m,mm}']
  # ARM and x86 sources guard their implementations by target architecture.
  s.exclude_files = '**/*.metal',
                    'whisper_ggml_plus/Classes/whisper/ggml/src/ggml-cpu/arch/powerpc/**/*',
                    'whisper_ggml_plus/Classes/whisper/ggml/src/ggml-cpu/arch/loongarch/**/*',
                    'whisper_ggml_plus/Classes/whisper/ggml/src/ggml-cpu/arch/riscv/**/*',
                    'whisper_ggml_plus/Classes/whisper/ggml/src/ggml-cpu/arch/s390/**/*',
                    'whisper_ggml_plus/Classes/whisper/ggml/src/ggml-cpu/arch/wasm/**/*'
  s.public_header_files = 'whisper_ggml_plus/Classes/whisper/include/whisper.h'
  s.resource_bundles = {
    'whisper_ggml_plus' => ['whisper_ggml_plus/Resources/default.metallib']
  }
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => '12.0',
    'OTHER_CFLAGS' => "-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL=1 -DGGML_USE_CPU -DWHISPER_VERSION='\"1.8.3\"' -DGGML_VERSION='\"0.9.5\"' -DGGML_COMMIT='\"unknown\"'",
    'OTHER_CPLUSPLUSFLAGS' => "-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL=1 -DGGML_USE_CPU -DWHISPER_VERSION='\"1.8.3\"' -DGGML_VERSION='\"0.9.5\"' -DGGML_COMMIT='\"unknown\"'",
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper" "$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper/include" "$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper/src" "$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper/src/coreml" "$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper/ggml/include" "$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper/ggml/src" "$(PODS_TARGET_SRCROOT)/whisper_ggml_plus/Classes/whisper/ggml/src/ggml-cpu"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.frameworks = 'CoreML', 'Metal', 'Foundation', 'Accelerate'
  s.swift_version = '5.0'
end
