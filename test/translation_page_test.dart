import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/data/dictionary/dictionary_data.dart';
import 'package:tudloapp/features/translation/screens/translation_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(DictionaryData.initialize);

  setUp(() {
    AppData.translateHelpDone = true;
  });

  testWidgets('uses the dictionary immediately for Hiligaynon', (tester) async {
    var nmtCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (text) async {
            nmtCalls++;
            return 'unused';
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'maayong aga');
    await tester.pump();

    expect(find.text('good morning'), findsOneWidget);
    expect(nmtCalls, 0);
  });

  testWidgets('debounces NMT and ignores stale results', (tester) async {
    final requests = <String>[];
    final completions = <Completer<String>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TranslationPage(
          translateEnglish: (text) {
            requests.add(text);
            final completion = Completer<String>();
            completions.add(completion);
            return completion.future;
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      'Type English',
    );
    await tester.enterText(find.byType(TextField), 'qzxv blorf');
    await tester.pump(const Duration(milliseconds: 449));
    expect(requests, isEmpty);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(requests, ['qzxv blorf']);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wugga zibble');
    await tester.pump(const Duration(milliseconds: 451));
    await tester.pump();
    completions.first.complete('stale result');
    await tester.pump();

    expect(find.text('stale result'), findsNothing);
    expect(requests, ['qzxv blorf', 'wugga zibble']);

    completions.last.complete('bag-o nga sabat');
    await tester.pump();
    expect(find.text('bag-o nga sabat'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
