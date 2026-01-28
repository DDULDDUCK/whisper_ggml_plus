# Fix for Large-v3-Turbo Single Segment Issue

## Problem

When using `ggml-large-v3-turbo-q3_k.bin`, transcription returns only one large segment (통짜) instead of multiple time-stamped segments like the base model does.

## Root Cause

The issue is caused by whisper.cpp's distilled model detection logic:

```cpp
// whisper.cpp line 6983
const bool is_distil = ctx->model.hparams.n_text_layer == 2 && ctx->model.hparams.n_vocab != 51866;
if (is_distil && !params.no_timestamps) {
    WHISPER_LOG_WARN("forcing no_timestamps for distilled models");
    params.no_timestamps = true;
}
```

When `no_timestamps` is forced to `true`, the segmentation logic treats it the same as `single_segment` mode:

```cpp
// whisper.cpp line 7395
if (params.single_segment || params.no_timestamps) {
    result_len = i + 1;
    seek_delta = 100*WHISPER_CHUNK_SIZE;  // Skip to end, creating one large segment
}
```

## Solution Applied (v1.2.4)

### 1. Explicitly Prevent Single Segment Mode

**Files Modified:**
- `ios/Classes/whisper_flutter_plus.cpp`
- `macos/Classes/whisper_ggml.cpp`
- `android/src/whisper/main.cpp`

**Change:**
```cpp
whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
// ... other params ...
wparams.single_segment = false;  // NEW: Explicitly prevent single segment
```

This ensures that even if the model is detected as distilled, it won't use single-segment mode.

### 2. Added Debug Logging

To help diagnose the issue, debug logging was added:

**iOS/macOS:**
```cpp
fprintf(stderr, "[DEBUG] Model info - n_text_layer: %d, n_vocab: %d\n", 
        whisper_model_n_text_layer(g_ctx), 
        whisper_model_n_vocab(g_ctx));

fprintf(stderr, "[DEBUG] Transcription params - no_timestamps: %d, single_segment: %d, split_on_word: %d, max_len: %d\n",
        wparams.no_timestamps, wparams.single_segment, wparams.split_on_word, wparams.max_len);
```

**Android:**
```cpp
__android_log_print(ANDROID_LOG_DEBUG, "WhisperFlutter", 
                    "[DEBUG] Model info - n_text_layer: %d, n_vocab: %d", ...);
```

## How to Test

### 1. Check Debug Output

After rebuilding your app, transcribe audio with Large-v3-Turbo and check the console/logcat for debug messages:

**Expected output:**
```
[DEBUG] Model info - n_text_layer: 4, n_vocab: 51866  # Large-v3-Turbo
[DEBUG] Transcription params - no_timestamps: 0, single_segment: 0, split_on_word: 0, max_len: 0
```

**What to look for:**
- If `n_text_layer: 2` → Model is being detected as distilled
- If `no_timestamps: 1` → Timestamps are being forced off
- If `single_segment: 1` → Single segment mode is active (should now be 0)

### 2. Test Transcription

```dart
final result = await controller.transcribe(
  model: WhisperModel.largeV3,
  audioPath: audioPath,
  isNoTimestamps: false,  // Ensure timestamps enabled
);

print("Segment count: ${result.transcription.segments.length}");
for (var segment in result.transcription.segments) {
  print("[${segment.fromTs} -> ${segment.toTs}] ${segment.text}");
}
```

**Expected behavior:**
- Multiple segments with different timestamps
- Not a single segment covering entire audio

### 3. Compare with Base Model

Test the same audio with both models:

```dart
// Test 1: Base model (should work - baseline)
final baseResult = await controller.transcribe(
  model: WhisperModel.base,
  audioPath: audioPath,
);
print("Base segments: ${baseResult.transcription.segments.length}");

// Test 2: Large-v3-Turbo (should now work like base)
final turboResult = await controller.transcribe(
  model: WhisperModel.largeV3,
  audioPath: audioPath,
);
print("Turbo segments: ${turboResult.transcription.segments.length}");
```

## Alternative Workaround (if issue persists)

If the problem continues, try enabling `splitOnWord`:

```dart
final result = await controller.transcribe(
  model: WhisperModel.largeV3,
  audioPath: audioPath,
  splitOnWord: true,  // Force word-level segmentation
);
```

This activates token-level timestamps with `max_len = 1`, which forces finer-grained segmentation.

## Model Characteristics Reference

| Model | n_text_layer | n_vocab | Distilled? | Expected Behavior |
|-------|--------------|---------|------------|-------------------|
| Tiny | 4 | 51864 | No | ✅ Segments work |
| Base | 6 | 51864 | No | ✅ Segments work |
| Small | 12 | 51864 | No | ✅ Segments work |
| Medium | 24 | 51864 | No | ✅ Segments work |
| Large-v3 | 32 | 51866 | No | ✅ Should work |
| Large-v3-Turbo | 4 | 51866 | No | ✅ Should work now |
| Distilled (v1) | 2 | 51864 | Yes | ⚠️ Single segment (by design) |

## Next Steps

1. **Rebuild your app** with the updated plugin (v1.2.4)
2. **Check debug logs** to see model parameters
3. **Test transcription** with Large-v3-Turbo
4. **Report results** - does segmentation now work correctly?

If the issue persists after this fix, please provide:
- Debug log output (model info + transcription params)
- Segment count returned
- Model file name being used

## Version Changes

- **pubspec.yaml**: 1.2.3 → 1.2.4
- **ios/whisper_ggml_plus.podspec**: 1.2.3 → 1.2.4
- **macos/whisper_ggml_plus.podspec**: 1.2.3 → 1.2.4
- **CHANGELOG.md**: Added v1.2.4 entry

## Files Modified

1. `ios/Classes/whisper_flutter_plus.cpp` - Added `single_segment = false` + debug logs
2. `macos/Classes/whisper_ggml.cpp` - Added `single_segment = false` + debug logs
3. `android/src/whisper/main.cpp` - Added `single_segment = false` + debug logs
4. `pubspec.yaml` - Version bump to 1.2.4
5. `ios/whisper_ggml_plus.podspec` - Version bump to 1.2.4
6. `macos/whisper_ggml_plus.podspec` - Version bump to 1.2.4
7. `CHANGELOG.md` - Added v1.2.4 release notes
