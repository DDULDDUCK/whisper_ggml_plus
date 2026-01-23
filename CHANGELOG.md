## 1.1.0

* Major upgrade: Synchronized engine with official whisper.cpp v1.8.3.
* Implemented new dynamic backend architecture (ggml-backend).
* Added full support for Large-v3-Turbo with improved stability.
* Refactored native bridge for better performance and API compatibility.
* Standardized directory structure across all platforms.

## 1.0.6

* Fixed critical integer overflow during Large-v3-Turbo tensor loading.
* Corrected memory size calculation for 1.6GB+ models to prevent pointer corruption.

## 1.0.5

* Fixed critical `EXC_BAD_ACCESS` (Segment Fault) error during model loading.
* Improved memory safety by using heap allocation for model file streams.
* Fixed dangling pointer issue in `whisper_init_from_file_no_state`.

## 1.0.4

* Fixed `Exception: map::at: key not found` error when using K-quantized models (Q2_K, Q3_K, Q4_K, Q5_K, Q6_K).
* Added missing quantization types to memory requirement maps.

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
