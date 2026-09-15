import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudlo/features/dictionary/presentation/dictionary_colors.dart';

/// The pill-shaped search field. Two modes:
/// - Functional (`readOnly: false`, the default): a normal search field,
///   [controller] drives live filtering. Used inside
///   `DictionaryBrowseScreen`.
/// - Decoy (`readOnly: true`): looks identical but can't be typed into
///   ([IgnorePointer]'d) -- tapping anywhere on the bar fires [onTap]
///   instead. [DictionaryScreen] uses this to open the browse screen while
///   looking like an inline search bar.
class DictionarySearchBar extends StatelessWidget {
  const DictionarySearchBar({
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.fieldKey = const Key('dictionary-search-field'),
    super.key,
  });

  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Distinct per screen -- both the main screen's decoy bar and the
  /// browse screen's real one can be mounted at once (routes stay alive
  /// underneath), so they can't share one key.
  final Key fieldKey;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: fieldKey,
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(color: DictionaryColors.ink, fontSize: 16),
      decoration: InputDecoration(
        // Otherwise TextField reserves extra vertical space for a
        // helper/error line even though this bar never shows one -- that
        // made it visibly taller than the same-height back pill beside it
        // on the browse screen.
        isDense: true,
        hintText: 'search',
        hintStyle: const TextStyle(color: DictionaryColors.ink),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(
            'assets/images/dictionary_search_icon.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: DictionaryColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: readOnly ? IgnorePointer(child: field) : field,
    );
    if (!readOnly) return bar;
    return Semantics(
      button: true,
      label: 'Browse the dictionary',
      child: GestureDetector(
        key: const Key('dictionary-search-bar-tap'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: bar,
      ),
    );
  }
}
