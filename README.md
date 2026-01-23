<div align="center">

# Whisper GGML Plus

_High-performance OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using the latest [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) v1.8.3 engine. Fully optimized for Large-v3-Turbo and hardware acceleration._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml_plus">
     <img src="https://img.shields.io/badge/pub-1.1.3-blue?logo=dart" alt="pub">
  </a>
</p>
</div>

## Key Upgrades in "Plus" Version

- **Major Engine Upgrade**: Synchronized with `whisper.cpp` v1.8.3, featuring the new dynamic `ggml-backend` architecture.
- **Large-v3-Turbo Support**: Native support for 128 mel bands, allowing you to use the latest Turbo models with high accuracy and speed.
- **Hardware Acceleration**: Out-of-the-box support for **CoreML (NPU)** and **Metal (GPU)** on iOS and macOS.
- **Persistent Context**: Models are cached in memory. After the first load, subsequent transcriptions start instantly without re-loading weights.
- **GGUF Support**: Compatible with the modern GGUF model format for better performance and memory efficiency.

## Supported platforms

| Platform  | Supported | Acceleration |
|-----------|-----------|--------------|
| Android   | ✅        | CPU (SIMD)   |
| iOS       | ✅        | CoreML/Metal |
| MacOS     | ✅        | Metal        |

## Features

- **Automatic Speech Recognition**: Seamless integration for Flutter apps.
- **Offline Capability**: Can be configured to work fully offline by using models from local assets.
- **Multilingual**: Auto-detect language or specify codes like "en", "ko", "ja", etc.
- **VAD (Voice Activity Detection)**: Utilizes built-in VAD for cleaner and faster processing.
- **Flash Attention**: Enabled for better performance on supported hardware.

## Installation

Add the library to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  whisper_ggml_plus: ^1.1.1
```

Run `flutter pub get` to install the package.

## Usage

### 1. Import the package
```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
```

### 2. Pick your model
For best performance on mobile, `tiny`, `base`, or `small` are recommended. For high accuracy, use `largeV3` (Turbo).

```dart
final model = WhisperModel.largeV3; // Supports Large-v3 and Turbo (128 mel)
```

### 3. Transcribe Audio
Declare `WhisperController` and use it for transcription. Note that .wav files must be **16kHz mono**.

```dart
final controller = WhisperController();

final result = await controller.transcribe(
    model: model,
    audioPath: audioPath, // Path to 16kHz mono .wav file
    lang: 'auto', // 'en', 'ko', 'ja', or 'auto' for detection
);
```

### 4. Handle Result
```dart
if (result != null) {
    print("Transcription: ${result.transcription.text}");
    
    for (var segment in result.transcription.segments) {
        print("[${segment.fromTs} -> ${segment.toTs}] ${segment.text}");
    }
}
```

## Optimization Tips

- **Release Mode**: Always test performance in `--release` mode. Native optimizations (SIMD/Metal) are significantly more effective.
- **Model Quantization**: Use quantized models (e.g., `q4_0`, `q5_0`, or `q2_k`) to reduce RAM usage, especially when using Large-v3-Turbo on mobile devices.
- **CoreML on iOS**: Ensure you provide the `.mlmodelc` folder alongside your `.bin` file for maximum NPU acceleration.

## License

MIT License - Based on the original work by sk3llo/whisper_ggml.
