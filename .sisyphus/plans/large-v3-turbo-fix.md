# Plan: Fix large-v3-turbo CoreML Detection and Dart API Updates

## TL;DR

> **Quick Summary**: Fix CoreML encoder auto-detection for `large-v3-turbo` models with quantization suffixes, update `WhisperModel` enum, and introduce `timestamp` parameter and audio conversion bypass to the Dart API.
> 
> **Deliverables**:
> - Updated C++ CoreML path logic in `whisper.cpp`.
> - Expanded `WhisperModel` enum in Dart.
> - New fields in `TranscribeRequest` and `TranscribeRequestDto`.
> - Modified `Whisper.transcribe` logic to support `skipConversion`.
> 
> **Estimated Effort**: Short
> **Parallel Execution**: YES - 2 waves
> **Critical Path**: C++ Fix → Dart API Updates → Verification

---

## Context

### Original Request
The user wants to resolve an issue where 'large-v3-turbo' models with various quantization suffixes fail to auto-detect CoreML encoders. Additionally, they want to update the Dart API with new parameters and a conversion bypass.

### Interview Summary
**Key Discussions**:
- **C++ Logic**: The current logic assumes quantization suffixes are exactly 5 characters (e.g., `-q8_0`). This fails for turbo models or models with different suffix lengths (e.g., `-q8`).
- **Dart API**: Support for `largeV3Turbo`, `timestamp` parameter, and `skipConversion` flag is needed.

---

## Work Objectives

### Core Objective
Ensure `large-v3-turbo` models correctly load CoreML encoders regardless of quantization suffix, and provide a more flexible Dart transcription API.

### Concrete Deliverables
- `macos/Classes/whisper/src/whisper.cpp`: Modified `whisper_get_coreml_path_encoder`.
- `lib/src/models/whisper_model.dart`: Added `largeV3Turbo`.
- `lib/src/models/requests/transcribe_request.dart`: Added `timestamp`, `skipConversion`.
- `lib/src/models/requests/transcribe_request_dto.dart`: Added mapping for new fields.
- `lib/src/whisper.dart`: Updated `transcribe` method.

### Definition of Done
- [ ] `large-v3-turbo-q8.bin` correctly identifies `large-v3-turbo-encoder.mlmodelc`.
- [ ] `TranscribeRequest` supports `timestamp` and `skipConversion`.
- [ ] Audio conversion is bypassed when `skipConversion` is true.

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES (Dart unit tests)
- **User wants tests**: YES (Automated DTO tests + Manual C++ verification)
- **Framework**: flutter_test

### Automated Verification (Dart)
Each TODO includes automated procedures:
- Unit tests for `TranscribeRequestDto` JSON serialization.
- Unit tests for `WhisperModel` factory methods.

### Manual Verification (C++)
Since automated testing for native CoreML loading in a CI environment is complex, we will use a dedicated verification script.

---

## Execution Strategy

### Parallel Execution Waves

Wave 1:
├── Task 1: Update WhisperModel Enum
├── Task 2: Modify C++ CoreML Path Logic
└── Task 3: Update TranscribeRequest Models

Wave 2:
├── Task 4: Update Whisper.transcribe logic
└── Task 5: Final Verification and Documentation

---

## TODOs

- [ ] 1. Update WhisperModel Enum

  **What to do**:
  - Add `largeV3Turbo` to `WhisperModel` enum in `lib/src/models/whisper_model.dart`.
  - Update `fromName` factory and `uri` getter.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`dart`]

  **Parallelization**: Wave 1

  **Acceptance Criteria**:
  - [ ] `WhisperModel.fromName('large-v3-turbo')` returns `largeV3Turbo`.
  - [ ] `WhisperModel.largeV3Turbo.uri` points to the correct HuggingFace repo.

- [ ] 2. Modify C++ CoreML Path Logic

  **What to do**:
  - Edit `macos/Classes/whisper/src/whisper.cpp` (and iOS equivalent if separate).
  - Update `whisper_get_coreml_path_encoder` to strip suffixes matching the pattern `-q[0-9].*` before the `.bin` extension.

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: [`cpp`]

  **Parallelization**: Wave 1

  **Acceptance Criteria**:
  - [ ] Manual test: Verify the function returns the correct encoder path for `ggml-large-v3-turbo-q8.bin`.

- [ ] 3. Update TranscribeRequest Models

  **What to do**:
  - Add `timestamp` (bool) and `skipConversion` (bool) to `TranscribeRequest` in `lib/src/models/requests/transcribe_request.dart`.
  - Update `TranscribeRequestDto` in `lib/src/models/requests/transcribe_request_dto.dart` to include these fields in JSON serialization.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`dart`]

  **Parallelization**: Wave 1

  **Acceptance Criteria**:
  - [ ] `TranscribeRequestDto.toJson()` includes `timestamp` and `skip_conversion` keys.

- [ ] 4. Update Whisper.transcribe Logic

  **What to do**:
  - Modify `transcribe` in `lib/src/whisper.dart`.
  - Wrap the `WhisperAudioConvert` logic in an `if (!transcribeRequest.skipConversion)` block.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`dart`]

  **Parallelization**: Wave 2

  **Acceptance Criteria**:
  - [ ] If `skipConversion` is true, no `.wav` file is created and the original path is used.

- [ ] 5. Final Documentation and Response

  **What to do**:
  - Draft the English response for the GitHub issue explaining the fix and the new API features.

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`github`]

  **Parallelization**: Wave 2

---

## Success Criteria

### Verification Commands
```bash
# Verify DTO serialization
flutter test test/models/transcribe_request_dto_test.dart

# Manual C++ check (Logic validation)
# Build and run the app with a large-v3-turbo-q8.bin model on macOS/iOS.
# Check logs for "loaded CoreML encoder from ..."
```
