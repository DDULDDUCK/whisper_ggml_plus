<div align="center">

# Whisper GGML Plus

_High-performance OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using the latest [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) v1.8.3 engine. Fully optimized for Large-v3-Turbo and hardware acceleration._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml_plus">
     <img src="https://img.shields.io/badge/pub-1.2.8-blue?logo=dart" alt="pub">
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

| Platform  | Supported | Acceleration | VAD |
|-----------|-----------|--------------|-----|
| Android   | ✅        | CPU (SIMD)   | ❌  |
| iOS       | ✅        | CoreML/Metal | ✅  |
| MacOS     | ✅        | Metal        | ✅  |

## Features

- **Automatic Speech Recognition**: Seamless integration for Flutter apps.
- **Offline Capability**: Can be configured to work fully offline by using models from local assets.
- **Multilingual**: Auto-detect language or specify codes like "en", "ko", "ja", etc.
- **VAD (Voice Activity Detection)**: Automatic silence skipping for 2-3x faster transcription on iOS/macOS.
- **Flash Attention**: Enabled for better performance on supported hardware.

## Installation

Add the library to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  whisper_ggml_plus: ^1.2.8
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

### CoreML Acceleration (Optional)

For 3x+ faster transcription on Apple Silicon devices (M1+, A14+), you can optionally add a CoreML encoder:

**1. Generate CoreML Encoder:**
```bash
# Clone whisper.cpp repository
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp

# Create Python 3.11 environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install torch==2.5.0 "numpy<2.0" coremltools==8.1 openai-whisper ane_transformers

# Generate CoreML encoder (example: large-v3-turbo)
./models/generate-coreml-model.sh large-v3-turbo
# Output: models/ggml-large-v3-turbo-encoder.mlmodelc (1.2GB)
```

**2. Place CoreML Encoder Alongside GGML Model:**
```
/your/app/models/
├── ggml-large-v3-turbo-q3_k.bin
└── ggml-large-v3-turbo-encoder.mlmodelc/  ← Same directory
```

**3. Use Normally:**
```dart
final result = await controller.transcribe(
  model: '/your/app/models/ggml-large-v3-turbo-q3_k.bin',
  audioPath: audioPath,
  lang: 'auto',
);
// whisper.cpp automatically detects and uses CoreML encoder if present
```

**Notes:**
- CoreML encoder works with **all quantization variants** (q3_k, q5_0, etc.)
- If `.mlmodelc` is not present, Metal (GPU) acceleration is used automatically
- CoreML requires ~1.2GB additional storage but provides 3x+ speedup and better battery life

## License

MIT License - Based on the original work by sk3llo/whisper_ggml.
