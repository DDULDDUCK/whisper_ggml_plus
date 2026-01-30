<div align="center">

# Whisper GGML Plus

_High-performance OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using the latest [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) v1.8.3 engine. Fully optimized for Large-v3-Turbo and hardware acceleration._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml_plus">
     <img src="https://img.shields.io/badge/pub-1.2.13-blue?logo=dart" alt="pub">
  </a>
</p>
</div>

## Key Upgrades in "Plus" Version

- **Major Engine Upgrade**: Synchronized with `whisper.cpp` v1.8.3, featuring the new dynamic `ggml-backend` architecture.
- **Large-v3-Turbo Support**: Native support for 128 mel bands, allowing you to use the latest Turbo models with high accuracy and speed.
- **Hardware Acceleration**: Out-of-the-box support for **CoreML (NPU)** and **Metal (GPU)** on iOS and macOS.
- **Persistent Context**: Models are cached in memory. After the first load, subsequent transcriptions start instantly without re-loading weights.
- **GGUF Support**: Compatible with the modern GGUF model format for better performance and memory efficiency.
- **GitHub Release Automation**: Automated release notes generation from `CHANGELOG.md`.

## Supported platforms
...
```dart
final controller = WhisperController();

final result = await controller.transcribe(
    model: model,
    audioPath: audioPath,
    lang: 'auto', // 'en', 'ko', 'ja', or 'auto' for detection
    withTimestamps: true, // Set to false to hide timestamps
    convert: true, // Set to false if audioPath is already 16kHz mono .wav
    threads: 8, // Customize CPU threads
    speedUp: true, // 2-3x faster inference (slight accuracy cost)
    isTranslate: false, // Set to true to translate result to English
);
```

Run `flutter pub get` to install the package.

## Usage

### 1. Import the package
```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
```

### 2. Pick your model
For best performance on mobile, `tiny`, `base`, or `small` are recommended. For high accuracy, use `largeV3Turbo`.

```dart
final model = WhisperModel.largeV3Turbo; // Native support for Turbo (128 mel)
```

### 3. Transcribe Audio
Declare `WhisperController` and use it for transcription.

```dart
final controller = WhisperController();

final result = await controller.transcribe(
    model: model,
    audioPath: audioPath,
    lang: 'auto', // 'en', 'ko', 'ja', or 'auto' for detection
    withTimestamps: true, // Set to false to hide timestamps
    convert: true, // Set to false if audioPath is already 16kHz mono .wav
);
```

### 4. Handle Result
```dart
if (result != null) {
    print("Transcription: ${result.transcription.text}");
    
    // Segments are available if withTimestamps is true
    for (var segment in result.transcription.segments) {
        print("[${segment.fromTs} -> ${segment.toTs}] ${segment.text}");
    }
}
```

## Optimization Tips

- **Release Mode**: Always test performance in `--release` mode. Native optimizations (SIMD/Metal) are significantly more effective.
- **Model Quantization**: Use quantized models (e.g., `q4_0`, `q5_0`, or `q2_k`) to reduce RAM usage, especially when using Large-v3-Turbo on mobile devices.
- **Naming Convention for CoreML**: To ensure CoreML detection works, keep the quantization suffix in the filename using the 5-character format (e.g., `ggml-large-v3-turbo-q5_0.bin`). The engine uses this to correctly locate the `-encoder.mlmodelc` directory.

### CoreML Acceleration (Optional)

For 3x+ faster transcription on Apple Silicon devices (M1+, A14+), you can optionally add a CoreML encoder:

#### What is `.mlmodelc`?

`.mlmodelc` is a **compiled CoreML model directory** (not a single file) containing:
- `model.mil` - CoreML model intermediate language
- `coremldata.bin` - Model weights optimized for Apple Neural Engine
- `metadata.json` - Model configuration

**Important:** `.mlmodelc` is a **directory with multiple files**, not a single file. This affects how you deploy it.

#### 1. Generate CoreML Encoder

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
# Output: models/ggml-large-v3-turbo-encoder.mlmodelc/ (directory, ~1.2GB)
```

#### 2. Deploy CoreML Model

**⚠️ CRITICAL: `.mlmodelc` cannot be bundled via Flutter assets!**

Flutter assets system doesn't preserve directory structures for custom folders, which breaks CoreML models. You must use one of these deployment methods:

##### Option A: Download at Runtime (Recommended)
```dart
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<String> downloadCoreMLModel() async {
  final appSupport = await getApplicationSupportDirectory();
  final modelDir = Directory('${appSupport.path}/models');
  await modelDir.create(recursive: true);
  
  final mlmodelcDir = Directory('${modelDir.path}/ggml-large-v3-turbo-encoder.mlmodelc');
  if (!await mlmodelcDir.exists()) {
    // Download and extract .mlmodelc directory from your server
    // Each file inside .mlmodelc must be downloaded separately
    await mlmodelcDir.create(recursive: true);
    await downloadFile('https://your-cdn.com/model.mil', '${mlmodelcDir.path}/model.mil');
    await downloadFile('https://your-cdn.com/coremldata.bin', '${mlmodelcDir.path}/coremldata.bin');
    await downloadFile('https://your-cdn.com/metadata.json', '${mlmodelcDir.path}/metadata.json');
  }
  
  return '${modelDir.path}/ggml-large-v3-turbo-q3_k.bin';
}
```

##### Option B: iOS/macOS Native Bundle (Advanced)
For iOS, manually add `.mlmodelc` to Xcode project:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `.mlmodelc` folder to project navigator
3. Ensure "Create folder references" (not "Create groups") is selected
4. Add to target: Runner

Then access via bundle path:
```dart
import 'dart:io';

String getCoreMLPath() {
  if (Platform.isIOS || Platform.isMacOS) {
    // Xcode bundles .mlmodelc as folder reference
    return '/path/in/bundle/ggml-large-v3-turbo-encoder.mlmodelc';
  }
  return '';
}
```

#### 3. Place CoreML Encoder Alongside GGML Model

```
/app/support/models/
├── ggml-large-v3-turbo-q3_k.bin
└── ggml-large-v3-turbo-encoder.mlmodelc/  ← Must be in same directory
    ├── model.mil
    ├── coremldata.bin
    └── metadata.json
```

**Naming Convention:**
- GGML model: `ggml-{model-name}-{quantization}.bin`
- CoreML model: `ggml-{model-name}-encoder.mlmodelc/` (base name must match)

Example pairs:
- `ggml-large-v3-turbo-q3_k.bin` + `ggml-large-v3-turbo-encoder.mlmodelc/`
- `ggml-base-q5_0.bin` + `ggml-base-encoder.mlmodelc/`

#### 4. Use Normally

```dart
final result = await controller.transcribe(
  model: '/app/support/models/ggml-large-v3-turbo-q3_k.bin',
  audioPath: audioPath,
  lang: 'auto',
);
// whisper.cpp automatically detects and uses CoreML encoder if present
```

#### How Detection Works

When you load a GGML model (e.g., `ggml-large-v3-turbo-q3_k.bin`), whisper.cpp automatically:
1. Strips quantization suffix: `ggml-large-v3-turbo-q3_k.bin` → `ggml-large-v3-turbo`
2. Looks for `ggml-large-v3-turbo-encoder.mlmodelc/` in the same directory
3. If found and valid: Uses CoreML (NPU) acceleration
4. If not found: Falls back to Metal (GPU) acceleration

**No code changes needed** - detection is automatic!

#### Troubleshooting

**CoreML model not detected:**
```
[CoreML Debug] whisper_coreml_init called
[CoreML Error] Model file/directory does not exist at path: /path/to/model.mlmodelc
```

**Common causes:**
1. **Wrong path:** `.mlmodelc` must be in same directory as `.bin` file
2. **Not a directory:** `.mlmodelc` is a directory, not a file - check with file manager
3. **Flutter assets:** Cannot bundle via `pubspec.yaml` assets - use runtime download or native bundle
4. **Name mismatch:** Base names must match (e.g., `ggml-base-q5.bin` needs `ggml-base-encoder.mlmodelc`)

**Check if CoreML is working:**
```
[CoreML Debug] CoreML model loaded successfully!
```

If you see this log, CoreML (NPU) is active. Otherwise, Metal (GPU) is used.

#### Performance Comparison

| Acceleration | Device | Speed | Battery | Storage |
|--------------|--------|-------|---------|---------|
| **CoreML (NPU)** | Apple Silicon | 3-5x faster | Best | +1.2GB |
| **Metal (GPU)** | iOS/macOS | 2-3x faster | Good | - |
| **CPU (SIMD)** | Android | 1x (baseline) | Fair | - |

**Recommendation:**
- **Large-v3-Turbo**: Use CoreML if storage allows - significant speed + battery improvement
- **Base/Small models**: Metal is sufficient - CoreML overhead not worth it
- **Android**: CoreML not available - CPU SIMD only

#### Notes

- CoreML encoder works with **all quantization variants** (q3_k, q5_0, q8_0, etc.) of the same base model
- If `.mlmodelc` is not present, Metal (GPU) acceleration is used automatically on iOS/macOS
- CoreML requires ~1.2GB additional storage per model but provides 3x+ speedup and better battery life
- Android does not support CoreML - CPU optimization only

## License

MIT License - Based on the original work by sk3llo/whisper_ggml.
