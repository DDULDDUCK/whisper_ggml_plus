## 1.2.7

* **CoreML Activation Fix**: Fixed CoreML (NPU) not being detected despite setup due to incorrect compiler flag.
* **Root Cause**: Podspec defined `-DWHISPER_COREML` but whisper.cpp source code checks for `#ifdef WHISPER_USE_COREML` (different flag name), causing CoreML detection code to be excluded at compile time.
* **Solution**: Changed iOS/macOS podspecs to use correct `-DWHISPER_USE_COREML` flag matching whisper.cpp expectations.
* **Impact**: CoreML encoder will now be properly detected and loaded when `.mlmodelc` file is present alongside GGML model, providing 3x+ faster transcription on Apple Silicon devices (M1+, A14+) with better battery efficiency.
* Changed from `WHISPER_COREML_ALLOW_LOW_LATENCY` to `WHISPER_COREML_ALLOW_FALLBACK` flag for graceful Metal fallback when CoreML model is unavailable.
* Added CoreML framework to macOS podspec (was missing).

## 1.2.6

* **Segmentation Fix for Large-v3-Turbo (Beam Search Solution)**: Fixed issue where Large-v3-Turbo produces single segment instead of multiple timestamps.
* **Root Cause**: Large-v3-Turbo (4 decoder layers, distilled) doesn't generate timestamp tokens naturally in greedy sampling mode due to weak timestamp prediction, causing all text to be treated as one segment.
* **Solution**: Automatically enable beam search sampling (`beam_size=3`) for Large-v3-Turbo models instead of greedy sampling. Beam search explores multiple token candidates simultaneously, increasing probability of selecting timestamp tokens for natural segmentation.
* **Why Beam Search Works**: Proven by whisper-cli (beam_size=5) producing perfect multi-segment results on macOS. Our beam_size=3 balances speed vs quality trade-off.
* **Performance Impact**: ~2-3x slower than greedy sampling, but produces proper segmentation matching other Whisper models (base, large-v3).
* Added Turbo model auto-detection (`n_text_layer=4`, `n_vocab=51866`) with automatic beam search strategy selection.
* Removed `max_len=50` forced segmentation approach (v1.2.5) which was ineffective for dense languages like Korean.
* Added comprehensive debug logging for sampling strategy and beam search parameters.

## 1.2.5

* **Segmentation Fix for Large-v3-Turbo (Deprecated)**: Attempted fix using forced segmentation (`max_len=50`).
* **Issue**: This approach was ineffective for dense languages (Korean, Japanese) where entire segments fit within 50 characters.
* **Superseded by**: v1.2.6 beam search solution.

## 1.2.3

* **Performance Enhancement**: Added VAD (Voice Activity Detection) support with Silero VAD model.
* VAD automatically detects and processes only speech segments, skipping silence for 2-3x faster transcription.
* Bundled ggml-silero-v6.2.0.bin model (864KB) for out-of-the-box VAD support on iOS/macOS.
* VAD reduces battery consumption by skipping silence processing.
* Android VAD support planned for future release.
* Fixed `whisper_vad_init_from_file_with_params: failed to open VAD model '(null)'` crash.

## 1.2.2

* **Critical Fix**: Added missing `GGML_USE_CPU` compiler flag for iOS/macOS.
* Fixed `GGML_ASSERT(device) failed` crash when CPU backend was not registered.
* CPU backend is now properly initialized alongside Metal backend on iOS/macOS.
* Resolves issue where `ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU)` returned NULL.

## 1.2.1

* **Critical Fix**: Added Metal shader compilation for iOS/macOS.
* Implemented automatic Metal library compilation via CocoaPods script phases.
* Fixed `GGML_ASSERT(device) failed` crash on iOS devices due to missing Metal shaders.
* Pre-compiles `ggml-metal.metal` to `default.metallib` for faster startup and better performance.
* Reduces app bundle size (~100KB vs ~416KB source file).
* Requires Xcode Metal Toolchain (one-time install via `xcodebuild -downloadComponent MetalToolchain`).

## 1.2.0

* Refactored codebase to version 1.2.0 for improved structure and compatibility.

## 1.1.3

* Completed missing sub-directory hierarchy for `ggml-cpu` and `coreml`.
* Fixed `unary-ops.h` and other implicit header dependency errors.
* Optimized include paths in Podspec and CMake for better v1.8.3 compatibility.

## 1.1.2

* Restored `ggml-cpu` directory hierarchy to match official v1.8.3 structure.
* Fixed missing header dependencies: `ggml-threading.h`, `quants.h`.
* Updated build configurations (Podspec, CMake) for subdirectory support.

## 1.1.1

* Fixed missing header dependencies for whisper.cpp v1.8.3 (traits.h, whisper-compat.h, gguf.h).
* Improved Android directory structure for better compatibility.

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
