import 'package:flutter/material.dart';

/// Opens a menu under the button whose [context] this is.
///
/// A button in the right half of the window gets its menu lined up with the
/// button's right side, opening leftwards, so the menu is never pushed
/// against the window's edge or cut off by it.
Future<void> showMenuUnder(
  BuildContext context,
  List<PopupMenuEntry<void>> items,
) {
  final button = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final below = Offset(0, button.size.height);
  return showMenu<void>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(below, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + below,
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    ),
    items: items,
  );
}

/// A choice in a menu, with a tick in front of the current one.
PopupMenuItem<void> tickedMenuItem({
  required String label,
  required bool ticked,
  required VoidCallback onTap,
}) => PopupMenuItem<void>(
  onTap: onTap,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.check_rounded,
        size: 18,
        color: ticked ? null : Colors.transparent,
      ),
      const SizedBox(width: 12),
      // A menu has a greatest width; a longer name wraps inside it.
      Flexible(child: Text(label)),
    ],
  ),
);
