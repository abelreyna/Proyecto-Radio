import 'package:flutter/widgets.dart';

/// Rectángulo en pantalla del widget que abrió el diálogo de compartir. En
/// iPad el diálogo nativo se ancla a esta posición.
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
