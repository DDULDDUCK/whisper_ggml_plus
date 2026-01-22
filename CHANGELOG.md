## 1.0.3

* Refactored native bridge for better thread safety and persistent context management.
* Optimized model switching logic to prevent memory leaks and race conditions.
* Standardized version reporting across all platforms.

## 1.0.2

* Enabled CoreML and Metal hardware acceleration for iOS and MacOS.
* Added dynamic CoreML bridge (whisper-encoder.mm) without Xcode auto-generation dependencies.
* Fully optimized Large-v3-Turbo (128-mel) models using Apple Neural Engine.
* Improved stability and performance for heavy models on mobile devices.

## 1.0.1

* Added support for Large-v3-Turbo models (128 mel bands).
* Fixed silent hangs by adding robust NULL checks during model initialization.
* Improved error messaging for memory allocation failures (OOM).
* Renamed package to `whisper_ggml_plus` and updated all internal imports.

## 1.0.0

* Initial fork of `whisper_ggml`.
* Added support for Large-v3-Turbo models (128 mel bands).
* Renamed package to `whisper_ggml_plus`.
