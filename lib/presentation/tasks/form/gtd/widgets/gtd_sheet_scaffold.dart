import 'package:flutter/material.dart';

/// Draggable sheet chrome shared by every step of the GTD guide.
///
/// Owns the sheet sizing, the scroll view, and the slide/fade transition
/// between nodes. [nodeKey] drives the transition — give it the current node so
/// the switcher animates on every step change.
class GtdSheetScaffold extends StatelessWidget {
  const GtdSheetScaffold({
    required this.header,
    required this.nodeKey,
    required this.nodeBuilder,
    super.key,
  });

  final Widget header;
  final Key nodeKey;
  final WidgetBuilder nodeBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            header,
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: nodeKey,
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Builder(builder: nodeBuilder),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
