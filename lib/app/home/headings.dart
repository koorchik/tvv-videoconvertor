import 'package:flutter/material.dart';

import '../theme.dart';

/// The name of a pane. In the professional look it is in spaced capitals,
/// like the legend on a piece of equipment; the capitals are made here, and
/// translations stay in ordinary case.
class PaneTitle extends StatelessWidget {
  const PaneTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!AppLook.of(context).capsHeadings) {
      return Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      text.toUpperCase(),
      semanticsLabel: text,
      maxLines: 1,
      softWrap: false,
      style: theme.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// The name of a control or of a group of values; in the professional look,
/// in small spaced capitals.
class ControlLabel extends StatelessWidget {
  const ControlLabel(this.text, {super.key, this.strong = false});

  final String text;

  /// For the title of a card rather than the label of one control.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!AppLook.of(context).capsHeadings) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: strong ? FontWeight.w600 : null,
        ),
      );
    }
    return Text(
      text.toUpperCase(),
      semanticsLabel: text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: strong
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
