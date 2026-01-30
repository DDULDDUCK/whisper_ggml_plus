import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:whisper_ggml_plus/src/models/whisper_model.dart';

import 'models/whisper_result.dart';
import 'whisper.dart';

class WhisperController {
  String _modelPath = '';
  String? _dir;

  Future<void> initModel(WhisperModel model) async {
    _dir ??= await getModelDir();
    _modelPath = '$_dir/ggml-${model.modelName}.bin';
  }

  Future<TranscribeResult?> transcribe({
    required WhisperModel model,
    required String audioPath,
    String lang = 'en',
    bool diarize = false,
    bool withTimestamps = true,
    bool convert = true,
  }) async {
    await initModel(model);

    final Whisper whisper = Whisper(model: model);
    final DateTime start = DateTime.now();
    const bool translate = false;
    const bool splitWords = false;

    try {
      String finalAudioPath = audioPath;

      if (convert) {
        final WhisperAudioConvert converter = WhisperAudioConvert(
          audioInput: File(audioPath),
          audioOutput: File('$audioPath.wav'),
        );

        final File? convertedFile = await converter.convert();
        if (convertedFile != null) {
          finalAudioPath = convertedFile.path;
        }
      }

      final WhisperTranscribeResponse transcription = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: finalAudioPath,
          language: lang,
          isTranslate: translate,
          isNoTimestamps: !withTimestamps,
          splitOnWord: splitWords,
          isRealtime: true,
          diarize: diarize,
        ),
        modelPath: _modelPath,
      );

      final Duration transcriptionDuration = DateTime.now().difference(start);

      return TranscribeResult(
        time: transcriptionDuration,
        transcription: transcription,
      );
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  static Future<String> getModelDir() async {
    final Directory libraryDirectory = Platform.isAndroid
        ? await getApplicationSupportDirectory()
        : await getLibraryDirectory();
    return libraryDirectory.path;
  }

  /// Get local path of model file
  Future<String> getPath(WhisperModel model) async {
    _dir ??= await getModelDir();
    return '$_dir/ggml-${model.modelName}.bin';
  }

  /// Download [model] to [destinationPath]
  Future<String> downloadModel(WhisperModel model) async {
    if (!File(await getPath(model)).existsSync()) {
      final request = await HttpClient().getUrl(model.modelUri);

      final response = await request.close();

      final bytes = await consolidateHttpClientResponseBytes(response);

      final File file = File(await getPath(model));
      await file.writeAsBytes(bytes);

      return file.path;
    } else {
      return await getPath(model);
    }
  }
}
