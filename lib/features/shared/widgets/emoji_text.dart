import 'package:flutter/widgets.dart';

/// Renders [emoji] as a color emoji regardless of the app's global font theme.
///
/// GoogleFonts sets [fontFamily] to 'Inter' app-wide via textTheme. On iOS this
/// can prevent the system emoji fallback from firing, making emoji invisible.
/// Explicitly listing ['Apple Color Emoji', 'Noto Color Emoji'] in
/// [fontFamilyFallback] forces Flutter to use the color emoji font for any
/// code-point that Inter doesn't contain (i.e. all emoji).
class EmojiText extends StatelessWidget {
  final String emoji;
  final double fontSize;
  final double? height;

  const EmojiText(
    this.emoji, {
    super.key,
    this.fontSize = 24,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: fontSize,
        height: height,
        fontFamily: 'NotoColorEmoji',
        fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji'],
        // Inherit nothing else — no color override that could tint emoji on
        // platforms that render emoji as regular glyphs.
        inherit: false,
      ),
    );
  }
}

/// A [TextStyle] that forces color-emoji rendering.
/// Use this in existing [Text] widgets instead of replacing them with [EmojiText].
TextStyle emojiStyle({double fontSize = 24, double? height}) => TextStyle(
      fontSize: fontSize,
      height: height,
      fontFamily: 'NotoColorEmoji',
      fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji'],
      inherit: false,
    );
