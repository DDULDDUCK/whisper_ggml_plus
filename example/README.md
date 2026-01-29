# Whisper GGML Plus - Example App

This example demonstrates how to use `whisper_ggml_plus` for speech recognition in Flutter.

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Download Models

This example requires Whisper models. You can download them from:
- [Official Whisper GGML Models](https://huggingface.co/ggerganov/whisper.cpp/tree/main)
- [Quantized Models (Recommended for mobile)](https://huggingface.co/ggerganov/whisper.cpp)

**Recommended models for mobile:**
- `ggml-tiny.bin` (75 MB) - Fastest, good for testing
- `ggml-base-q5_0.bin` (47 MB) - Good balance
- `ggml-small-q5_0.bin` (77 MB) - Better accuracy
- `ggml-large-v3-turbo-q3_k.bin` (829 MB) - Best accuracy, Apple Silicon recommended

### 3. Place Models

Models cannot be bundled in Flutter assets due to size. Use runtime download:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<String> setupModel() async {
  final appSupport = await getApplicationSupportDirectory();
  final modelPath = '${appSupport.path}/models/ggml-base-q5_0.bin';
  
  final file = File(modelPath);
  if (!await file.exists()) {
    await file.create(recursive: true);
    // Download model from your CDN or server
    final response = await http.get(Uri.parse('https://your-cdn.com/ggml-base-q5_0.bin'));
    await file.writeAsBytes(response.bodyBytes);
  }
  
  return modelPath;
}
```

### 4. Run the Example
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# macOS
flutter run -d macos
```

## CoreML Setup (iOS/macOS Only)

For 3x+ faster transcription on Apple devices, you can add CoreML encoder.

### Generate CoreML Model

```bash
# Clone whisper.cpp
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp

# Setup Python environment
python3.11 -m venv venv
source venv/bin/activate
pip install torch==2.5.0 "numpy<2.0" coremltools==8.1 openai-whisper ane_transformers

# Generate CoreML encoder for base model
./models/generate-coreml-model.sh base
# Output: models/ggml-base-encoder.mlmodelc/ (~800MB directory)

# Or for large-v3-turbo
./models/generate-coreml-model.sh large-v3-turbo
# Output: models/ggml-large-v3-turbo-encoder.mlmodelc/ (~1.2GB directory)
```

### Deploy CoreML Model

**Option A: Download at Runtime (Recommended)**

```dart
Future<void> setupCoreMLModel() async {
  final appSupport = await getApplicationSupportDirectory();
  final mlmodelcDir = Directory('${appSupport.path}/models/ggml-base-encoder.mlmodelc');
  
  if (!await mlmodelcDir.exists()) {
    await mlmodelcDir.create(recursive: true);
    
    // Download each file inside .mlmodelc directory
    final files = ['model.mil', 'coremldata.bin', 'metadata.json'];
    for (final file in files) {
      final response = await http.get(
        Uri.parse('https://your-cdn.com/ggml-base-encoder.mlmodelc/$file')
      );
      await File('${mlmodelcDir.path}/$file').writeAsBytes(response.bodyBytes);
    }
  }
}
```

**Option B: iOS Native Bundle (Advanced)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `ggml-base-encoder.mlmodelc` folder into project navigator
3. **Important:** Select "Create folder references" (blue folder icon), NOT "Create groups"
4. Ensure it's added to Runner target
5. Access via bundle path in code

### Verify CoreML is Working

Check Xcode console for these logs:

**Success:**
```
[CoreML Debug] whisper_coreml_init called
[CoreML Debug] Attempting to load from: /path/to/model.mlmodelc
[CoreML Debug] File exists: 1, Is directory: 1
[CoreML Debug] Starting MLModel initialization...
[CoreML Debug] CoreML model loaded successfully!
```

**Failure:**
```
[CoreML Error] Model file/directory does not exist at path: /path/to/model.mlmodelc
[CoreML Debug] Parent directory (...) contains:
[CoreML Debug]   - ggml-base-q5_0.bin
[CoreML Debug]   - (no .mlmodelc directory found)
```

## File Structure Example

### Without CoreML (Metal acceleration)
```
/app/support/models/
└── ggml-base-q5_0.bin
```

### With CoreML (NPU acceleration)
```
/app/support/models/
├── ggml-base-q5_0.bin
└── ggml-base-encoder.mlmodelc/          ← Must be directory
    ├── model.mil                         ← CoreML model IR
    ├── coremldata.bin                    ← Model weights
    └── metadata.json                     ← Model config
```

**Critical Rules:**
1. `.mlmodelc` **must be a directory**, not a file
2. `.mlmodelc` **must be in same directory** as `.bin` file
3. Base names must match: `ggml-base-*.bin` → `ggml-base-encoder.mlmodelc`
4. **Cannot use Flutter assets** - directory structure breaks

## Usage Example

### Basic Transcription

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

final controller = WhisperController();

// Transcribe audio file (must be 16kHz mono WAV)
final result = await controller.transcribe(
  model: '/path/to/models/ggml-base-q5_0.bin',
  audioPath: '/path/to/audio.wav',
  lang: 'auto', // or 'en', 'ko', 'ja', etc.
);

if (result != null) {
  print('Full text: ${result.transcription.text}');
  
  // Print segments with timestamps
  for (final segment in result.transcription.segments) {
    print('[${segment.fromTs} -> ${segment.toTs}] ${segment.text}');
  }
}
```

### Convert Audio to 16kHz Mono WAV

Whisper requires specific audio format. Use `ffmpeg_kit_flutter`:

```dart
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

Future<String> convertToWav(String inputPath) async {
  final outputPath = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_16k_mono.wav');
  
  await FFmpegKit.execute(
    '-i "$inputPath" -ar 16000 -ac 1 -c:a pcm_s16le "$outputPath"'
  );
  
  return outputPath;
}
```

### Using Pre-defined Models

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

// Download pre-defined models automatically
final result = await controller.transcribe(
  model: WhisperModel.base,  // tiny, base, small, medium, largeV3
  audioPath: audioPath,
  lang: 'en',
);
```

## Performance Tips

### Model Selection

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| `tiny` | 75 MB | Fastest | Low | Testing, prototyping |
| `base` | 142 MB | Fast | Good | General use, mobile |
| `small` | 466 MB | Medium | Better | Quality transcription |
| `large-v3-turbo` | 1.6 GB | Slow (3x with CoreML) | Best | Apple Silicon only |

### Quantization

Use quantized models to reduce RAM:
- `q2_k` - Smallest, lowest quality (not recommended)
- `q3_k` - Good balance for large models
- `q5_0` - Best balance for base/small models
- `q8_0` - Minimal quality loss, larger size

### Acceleration Priority (iOS/macOS)

1. **CoreML (NPU)** - 3-5x faster, best battery (if `.mlmodelc` present)
2. **Metal (GPU)** - 2-3x faster (automatic fallback)
3. **CPU (SIMD)** - Baseline speed (used if Metal unavailable)

### Android Optimization

- Use `q5_0` or `q3_k` quantization
- Prefer `base` or `small` models (large models too slow on mobile CPU)
- Test in `--release` mode (SIMD optimizations only work in release)

## Troubleshooting

### "Model not found" Error

**Symptom:**
```
Exception: Model file not found: /path/to/model.bin
```

**Solution:**
- Check file exists: `await File(modelPath).exists()`
- Use absolute path, not relative
- Verify path is in app's accessible directory (use `path_provider`)

### CoreML Not Detected

**Symptom:**
```
[CoreML Error] Model file/directory does not exist
```

**Solution:**
1. Verify `.mlmodelc` is a **directory** (not a file)
2. Check `.mlmodelc` is in **same directory** as `.bin` file
3. Verify base names match: `ggml-base-*.bin` → `ggml-base-encoder.mlmodelc`
4. Do NOT bundle via Flutter assets - use runtime download

### Slow Transcription

**Symptom:**
- Takes 30+ seconds for 10-second audio
- Battery drains quickly

**Solution:**
- **iOS/macOS:** Add CoreML encoder (3x+ speedup)
- **Android:** Use smaller model (`base` instead of `large`)
- Always test in `--release` mode (debug mode is 5-10x slower)
- Use quantized models (`q5_0`, `q3_k`)

### Segmentation Issues (Large-v3-Turbo)

**Symptom:**
- All text in single segment
- No timestamps between sentences

**Solution:**
- This is fixed in v1.2.6+ (automatic beam search for Turbo models)
- If using older version, upgrade to latest:
  ```yaml
  dependencies:
    whisper_ggml_plus: ^1.2.10
  ```

### Out of Memory Crash

**Symptom:**
```
Fatal Exception: NSException
Memory allocation failed
```

**Solution:**
- Use smaller model (`base` instead of `large`)
- Use quantized variant (`q3_k`, `q5_0`)
- Large-v3 requires ~4GB RAM - use on high-end devices only

## Resources

- [Official Documentation](https://github.com/DDULDDUCK/whisper_ggml_plus)
- [Whisper.cpp Repository](https://github.com/ggerganov/whisper.cpp)
- [Pre-trained Models](https://huggingface.co/ggerganov/whisper.cpp/tree/main)
- [GGML Quantization Guide](https://github.com/ggerganov/ggml#quantization)

## License

MIT License - See [LICENSE](../LICENSE) file for details.
