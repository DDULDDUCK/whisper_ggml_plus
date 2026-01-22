<div align="center">

# Whisper GGML Plus

_OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp). Supports Large-v3-Turbo (128 mel bands)._

<p align="center">
  <a href="https://pub.dev/packages/whisper_ggml_plus">
     <img src="https://img.shields.io/badge/pub-1.0.0-blue?logo=dart" alt="pub">
  </a>
</p>
</div>


## Supported platforms


| Platform  | Supported |
|-----------|-----------|
| Android   | ✅        |
| iOS       | ✅        |
| MacOS     | ✅        |


## Features



- Automatic Speech Recognition integration for Flutter apps.

- Supports automatic model downloading and initialization. Can be configured to work fully offline by using `assets` models (see example folder).

- Seamless iOS and Android support with optimized performance.

- Can be configured to use specific language ("en", "fr", "de", etc) or auto-detect ("auto").

- Utilizes [CORE ML](https://github.com/ggml-org/whisper.cpp/tree/master?tab=readme-ov-file#core-ml-support) for enhanced processing on iOS devices.

- **Support for Large-v3-Turbo models (128 mel bands).**



## Installation



To use this library in your Flutter project, follow these steps:



1. Add the library to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  whisper_ggml_plus: ^1.0.0
```

2. Run `flutter pub get` to install the package.



## Usage



To integrate Whisper ASR in your Flutter app:



1. Import the package:

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
```

2. Run `flutter pub get` to install the package.



## Usage



To integrate Whisper ASR in your Flutter app:



1. Import the package:

```dart
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
```



2. Pick your model. Smaller models are more performant, but the accuracy may be lower. Recommended models are `tiny` and `small`.

```dart
final model = WhisperModel.tiny;
```

3. Declare `WhisperController` and use it for transcription:

```dart
final controller = WhisperController();

final result = await controller.transcribe(
    model: model, /// Selected WhisperModel
    audioPath: audioPath, /// Path to .wav file
    lang: 'en', /// Language to transcribe
);
```

4. Use the `result` variable to access the transcription result:

```dart
if (result?.transcription.text != null) {
    /// Do something with the transcription
    print(result!.transcription.text);
}
```



## Notes



Transcription processing time is about `5x` times faster when running in release mode.