import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class NmtTranslationService {
  static const _modelAsset = 'assets/models/nmt_model.onnx';
  static const _tokenizerAsset = 'assets/models/tokenizer.model';
  static const _bosId = 2;
  static const _eosId = 3;
  static const _maxSourceLength = 128;
  static const _maxDecodeLength = 32;

  Future<({OrtSession session, SentencePieceTokenizer tokenizer})>? _resources;
  Future<String>? _activeTranslation;
  bool _closed = false;

  Future<String> translate(String text) {
    if (_closed) throw StateError('Translation service is closed.');
    final translation = _translate(text);
    _activeTranslation = translation;
    return translation.whenComplete(() {
      if (identical(_activeTranslation, translation)) {
        _activeTranslation = null;
      }
    });
  }

  Future<String> _translate(String text) async {
    final resources = await _getResources();
    var sourceIds = resources.tokenizer.encode(text).ids.toList();
    if (sourceIds.length > _maxSourceLength) {
      sourceIds = sourceIds.sublist(0, _maxSourceLength);
      sourceIds[_maxSourceLength - 1] = _eosId;
    }

    final sourceTensor = await OrtValue.fromList(
      Int64List.fromList(sourceIds),
      [1, sourceIds.length],
    );
    final generated = <int>[_bosId];

    try {
      for (var step = 0; step < _maxDecodeLength; step++) {
        final targetTensor = await OrtValue.fromList(
          Int64List.fromList(generated),
          [1, generated.length],
        );
        Map<String, OrtValue> outputs = {};
        try {
          outputs = await resources.session.run({
            'src_tokens': sourceTensor,
            'tgt_tokens': targetTensor,
          });
          final values = await outputs['next_token']!.asFlattenedList();
          final nextToken = values.single as int;
          if (nextToken == _eosId) break;
          generated.add(nextToken);

          // ponytail: reject a looping checkpoint; remove after model quality
          // tests show repeated-token decoding is fixed.
          if (_repeatsLastToken(generated)) return '';
        } finally {
          await targetTensor.dispose();
          for (final output in outputs.values) {
            await output.dispose();
          }
        }
      }
    } finally {
      await sourceTensor.dispose();
    }

    return resources.tokenizer.decode(generated);
  }

  Future<({OrtSession session, SentencePieceTokenizer tokenizer})>
  _getResources() async {
    final pending = _resources ??= _loadResources();
    try {
      return await pending;
    } catch (_) {
      if (identical(_resources, pending)) _resources = null;
      rethrow;
    }
  }

  Future<({OrtSession session, SentencePieceTokenizer tokenizer})>
  _loadResources() async {
    final session = await OnnxRuntime().createSessionFromAsset(
      _modelAsset,
      options: OrtSessionOptions(
        intraOpNumThreads: 1,
        interOpNumThreads: 1,
        providers: [OrtProvider.CPU],
      ),
    );
    try {
      final data = await rootBundle.load(_tokenizerAsset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final tokenizer = SentencePieceTokenizer.fromBytes(
        bytes,
        config: const SentencePieceConfig(addBosToken: true, addEosToken: true),
      );
      return (session: session, tokenizer: tokenizer);
    } catch (_) {
      await session.close();
      rethrow;
    }
  }

  bool _repeatsLastToken(List<int> tokens) {
    if (tokens.length < 5) return false;
    final last = tokens.last;
    return tokens.sublist(tokens.length - 4).every((token) => token == last);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _activeTranslation;
    } catch (_) {
      // A failed translation still needs its session closed.
    }
    final pending = _resources;
    if (pending == null) return;
    try {
      await (await pending).session.close();
    } catch (_) {
      // Initialization failed before a session became available.
    }
  }
}
