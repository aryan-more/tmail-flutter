import 'package:core/presentation/extensions/list_extensions.dart';
import 'package:core/presentation/views/text/rich_text_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
  );
  const highlightTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 16,
  );
  Widget buildRichText({
    required String textOrigin,
    required String wordToStyle,
    String? preMarkedText,
    bool ensureHighlightVisible = false,
  }) => MaterialApp(home: Scaffold(
    body: RichTextBuilder(
      textOrigin: textOrigin,
      wordToStyle: wordToStyle,
      styleOrigin: normalTextStyle,
      styleWord: highlightTextStyle,
      preMarkedText: preMarkedText,
      ensureHighlightVisible: ensureHighlightVisible,
    ),
  ));

  Finder findNormalStyledText(String text, {int occurence = 1}) {
    final normalSpan = TextSpan(text: text, style: normalTextStyle);
    return find.byWidgetPredicate((widget) {
      return widget is RichText
        && ((widget.text as TextSpan).children!.first as TextSpan).children!.contains(normalSpan)
        && ((widget.text as TextSpan).children!.first as TextSpan).children!.countOccurences(normalSpan) == occurence;
    });
  }

  Finder findHighlightStyledText(String text, {int occurence = 1}) {
    final highlightSpan = TextSpan(text: text, style: highlightTextStyle);
    return find.byWidgetPredicate((widget) {
      return widget is RichText
        && ((widget.text as TextSpan).children!.first as TextSpan).children!.contains(highlightSpan)
        && ((widget.text as TextSpan).children!.first as TextSpan).children!.countOccurences(highlightSpan) == occurence;
    });
  }

  group('rich text builder test:', () {
    testWidgets(
      'should not highlight any text '
      'when wordToStyle is empty '
      'and preMarkedText is null',
    (tester) async {
      // arrange
      const textOrigin = 'This is a test';
      final richText = buildRichText(
        textOrigin: textOrigin,
        wordToStyle: '',
      );
      
      // act
      await tester.pumpWidget(richText);
      
      // assert
      expect(
        findNormalStyledText(textOrigin),
        findsOneWidget,
      );
    });

    testWidgets(
      'should highlight text with wordToStyle '
      'when wordToStyle is not empty '
      'and preMarkedText is null',
    (tester) async {
      // arrange
      const textOrigin = 'This is a test of test';
      const wordToStyle = 'test';
      final richText = buildRichText(
        textOrigin: textOrigin,
        wordToStyle: wordToStyle,
      );
      final numberOfHighlights = wordToStyle.allMatches(textOrigin).length;
      final normalStyledTexts = textOrigin
        .split(wordToStyle)
        ..removeWhere((text) => text.isEmpty);
      
      // act
      await tester.pumpWidget(richText);
      
      // assert
      for (final text in normalStyledTexts) {
        expect(
          findNormalStyledText(
            text,
            occurence: normalStyledTexts.countOccurences(text),
          ),
          findsOneWidget,
        );
      }
      expect(
        findHighlightStyledText(wordToStyle, occurence: numberOfHighlights),
        findsOneWidget,
      );
    });

    testWidgets(
      'should highlight text with <mark> '
      'when preMarkedText is not null ',
    (tester) async {
      // arrange
      const preMarkedText = 'This is <mark>test</mark> '
        'of <mark>test text</mark> with duplicate <mark>test</mark>This is ';
      final richText = buildRichText(
        textOrigin: '',
        wordToStyle: '',
        preMarkedText: preMarkedText,
      );
      
      final highlightMatches = RegExp('<mark>(.*?)</mark>').allMatches(preMarkedText);
      final highlightStyledTexts = highlightMatches
        .map((match) => match.group(1)!)
        .toList();
      final normalStyledTexts = <String>[];
      int lastIndex = 0;
      for (final match in highlightMatches) {
        normalStyledTexts.add(preMarkedText.substring(lastIndex, match.start));
        lastIndex = match.end;
      }
      normalStyledTexts
        ..add(preMarkedText.substring(lastIndex))
        ..removeWhere((text) => text.isEmpty);
      
      // act
      await tester.pumpWidget(richText);
      
      // assert
      for (final text in normalStyledTexts) {
        expect(
          findNormalStyledText(
            text,
            occurence: normalStyledTexts.countOccurences(text),  
          ),
          findsOneWidget,
        );
      }
      for (final text in highlightStyledTexts) {
        expect(
          findHighlightStyledText(
            text,
            occurence: highlightStyledTexts.countOccurences(text)
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets(
      'should highlight text with <mark> '
      'when preMarkedText is not null '
      'and both textOrigin and wordToStyle are not empty',
    (tester) async {
      // arrange
      const preMarkedText = 'This is <mark>test</mark> '
        'of <mark>test text</mark> with duplicate <mark>test</mark>';
      final richText = buildRichText(
        textOrigin: 'something something',
        wordToStyle: 'some',
        preMarkedText: preMarkedText,
      );
      
      final highlightMatches = RegExp('<mark>(.*?)</mark>').allMatches(preMarkedText);
      final highlightStyledTexts = highlightMatches
        .map((match) => match.group(1)!)
        .toList();
      final normalStyledTexts = <String>[];
      int lastIndex = 0;
      for (final match in highlightMatches) {
        normalStyledTexts.add(preMarkedText.substring(lastIndex, match.start));
        lastIndex = match.end;
      }
      normalStyledTexts
        ..add(preMarkedText.substring(lastIndex))
        ..removeWhere((text) => text.isEmpty);
      
      // act
      await tester.pumpWidget(richText);
      
      // assert
      for (final text in normalStyledTexts) {
        expect(
          findNormalStyledText(text),
          findsOneWidget,
        );
      }
      for (final text in highlightStyledTexts) {
        expect(
          findHighlightStyledText(
            text,
            occurence: highlightStyledTexts.countOccurences(text)
          ),
          findsOneWidget,
        );
      }
    });
  });
}