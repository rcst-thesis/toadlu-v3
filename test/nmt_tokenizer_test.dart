import 'dart:io';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NMT source tokens match the exported SentencePiece model', () {
    final tokenizer = SentencePieceTokenizer.fromBytes(
      File('assets/models/tokenizer.model').readAsBytesSync(),
    );

    expect(
      [2, ...tokenizer.encode('hello', addSpecialTokens: false).ids, 3],
      [2, 6919, 3],
    );
  });
}
