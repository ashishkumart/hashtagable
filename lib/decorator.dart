import 'package:flutter/cupertino.dart';

/// DataModel to explain the unit of word in decoration system
class Decoration extends Comparable<Decoration> {
  Decoration({@required this.range, this.style, this.emojiStartPoint});

  final TextRange range;
  final TextStyle style;
  final int emojiStartPoint;

  @override
  int compareTo(Decoration other) {
    return range.start.compareTo(other.range.start);
  }
}

/// Hold functions to decorate tagged text
///
/// Return the list of [Decoration] in [getDecorations]
class Decorator {
  final TextStyle textStyle;
  final TextStyle decoratedStyle;
 /* static final hashTagRegExp = RegExp(
    "(?!\\n)(?:^|\\s)(#([·・ー_ぁ-んァ-ンa-zA-Z0-9一-龠０-９ａ-ｚＡ-ＺáàãâéêíóôõúüçÁÀÃÂÉÊÍÓÔÕÚÜÇ]+))", */
    static final hashTagRegExp = RegExp(
    "(?!\\n)(?:^|\\s)(#([·・ー_ぁ-んァ-ンa-zA-Z0-9一-龠０-９ａ-ｚＡ-ＺáàãâéêíóôõúçäöüÁÀÃÂÉÊÍÓÔÕÚÇÄÖÜß]+))",
    multiLine: true,
  );
  Decorator({this.textStyle, this.decoratedStyle});

  List<Decoration> _getSourceDecorations(
      List<RegExpMatch> tags, String copiedText) {
    TextRange previousItem;
    final result = List<Decoration>();
    for (var tag in tags) {
      ///Add untagged content
      if (previousItem == null) {
        if (tag.start > 0) {
          result.add(Decoration(
              range: TextRange(start: 0, end: tag.start), style: textStyle));
        }
      } else {
        result.add(Decoration(
            range: TextRange(start: previousItem.end, end: tag.start),
            style: textStyle));
      }

      ///Add tagged content
      result.add(Decoration(
          range: TextRange(start: tag.start, end: tag.end),
          style: decoratedStyle));
      previousItem = TextRange(start: tag.start, end: tag.end);
    }

    ///Add remaining untagged content
    if (result.last.range.end < copiedText.length) {
      result.add(Decoration(
          range:
              TextRange(start: result.last.range.end, end: copiedText.length),
          style: textStyle));
    }
    return result;
  }

  ///Decorate tagged content, filter out the ones includes emoji.
  List<Decoration> _getEmojiFilteredDecorations(
      {List<Decoration> source,
      String copiedText,
      List<RegExpMatch> emojiMatches}) {
    final result = List<Decoration>();
    for (var item in source) {
      int emojiStartPoint;
      for (var emojiMatch in emojiMatches) {
        final decorationContainsEmoji = (item.range.start < emojiMatch.start &&
            emojiMatch.end <= item.range.end);
        if (decorationContainsEmoji) {
          /// If the current Emoji's range.start is the smallest in the tag, update emojiStartPoint
          emojiStartPoint = (emojiStartPoint != null)
              ? ((emojiMatch.start < emojiStartPoint)
                  ? emojiMatch.start
                  : emojiStartPoint)
              : emojiMatch.start;
        }
      }
      if (item.style == decoratedStyle && emojiStartPoint != null) {
        result.add(Decoration(
          range: TextRange(start: item.range.start, end: emojiStartPoint),
          style: decoratedStyle,
        ));
        result.add(Decoration(
            range: TextRange(start: emojiStartPoint, end: item.range.end),
            style: textStyle));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  /// Return the list of decorations with tagged and untagged text
  List<Decoration> getDecorations(String copiedText) {
    /// Text to change emoji into replacement text
    final fullWidthRegExp = RegExp(
        r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

    final fullWidthRegExpMatches =
        fullWidthRegExp.allMatches(copiedText).toList();
    final japaneseRegExp = RegExp(r'[・ぁ-んーァ-ヶ一-龥０-９ａ-ｚＡ-Ｚ]');
    final emojiMatches = fullWidthRegExpMatches
        .where((match) => (!japaneseRegExp
            .hasMatch(copiedText.substring(match.start, match.end))))
        .toList();

    /// This is to avoid the error caused by 'regExp' which counts the emoji's length 1.
    emojiMatches.forEach((emojiMatch) {
      final emojiLength = emojiMatch.group(0).length;
      final replacementText = "a" * emojiLength;
      copiedText = copiedText.replaceRange(
          emojiMatch.start, emojiMatch.end, replacementText);
    });

    final tags = hashTagRegExp.allMatches(copiedText).toList();
    if (tags.isEmpty) {
      return [];
    }

    final sourceDecorations = _getSourceDecorations(tags, copiedText);

    final emojiFilteredResult = _getEmojiFilteredDecorations(
        copiedText: copiedText,
        emojiMatches: emojiMatches,
        source: sourceDecorations);

    return emojiFilteredResult;
  }
}
