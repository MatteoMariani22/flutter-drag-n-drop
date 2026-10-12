import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_drag_n_drop/main.dart';

void main() {
  testWidgets('reorders cards while dragging and keeps edit mode active',
      (tester) async {
    await tester.pumpWidget(const DragDropDemoApp());
    await tester.pumpAndSettle();

    final firstCard = find.byKey(const ValueKey('grid-news'));
    final secondCard = find.byKey(const ValueKey('grid-folders'));
    final firstPosition = tester.getTopLeft(firstCard);
    final secondPosition = tester.getTopLeft(secondCard);
    final gesture = await tester.startGesture(tester.getCenter(firstCard));

    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(secondCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 401));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Edit mode'), findsOneWidget);
    expect(
      tester.getTopLeft(firstCard).dx,
      closeTo(secondPosition.dx, 1),
    );
    expect(
      tester.getTopLeft(secondCard).dx,
      closeTo(firstPosition.dx, 1),
    );

    await tester.tap(find.text('Edit mode'));
    await tester.pumpAndSettle();
    expect(find.text('Long-press a card to move it'), findsOneWidget);
  });
}
