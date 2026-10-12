import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_drag_n_drop/drag_drop_controller.dart';

void main() {
  group('DragDropController', () {
    late DragDropController controller;

    setUp(() {
      controller = DragDropController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('moves a card to the drop target position', () {
      final firstCard = controller.items.first;
      final secondCard = controller.items[1];
      final thirdCard = controller.items[2];

      controller.startDrag(index: 0, position: const Offset(10, 20));
      controller.dropOn(2);

      expect(controller.items[2].id, firstCard.id);
      expect(controller.items[0].id, secondCard.id);
      expect(controller.items[1].id, thirdCard.id);
      expect(controller.isEditingMode, isTrue);
      expect(controller.sourceIndex, 2);
    });

    test('tracks the dragged card position across live reorders', () {
      final draggedCard = controller.items.first;

      controller.startDrag(index: 0, position: Offset.zero);
      controller.dropOn(2);
      controller.dropOn(4);

      expect(controller.items[4].id, draggedCard.id);
      expect(controller.draggedItem?.id, draggedCard.id);
      expect(controller.sourceIndex, 4);
    });

    test('ending a drag clears transient state and keeps edit mode active', () {
      controller.startDrag(index: 0, position: const Offset(10, 20));
      controller.updateDragPosition(const Offset(30, 40));
      controller.setTargetIndex(1);

      controller.endDrag();

      expect(controller.isDragging, isFalse);
      expect(controller.isEditingMode, isTrue);
      expect(controller.targetIndex, isNull);
      expect(controller.dragPosition, isNull);
    });

    test('ignores drop and position updates when dragging is inactive', () {
      final originalOrder = controller.items.map((item) => item.id).toList();

      controller.dropOn(2);
      controller.updateDragPosition(const Offset(30, 40));

      expect(controller.items.map((item) => item.id), originalOrder);
      expect(controller.dragPosition, isNull);
    });

    test('exiting edit mode resets the drag state', () {
      controller.startDrag(index: 1, position: const Offset(10, 20));
      controller.setTargetIndex(2);

      controller.exitEditMode();

      expect(controller.isEditingMode, isFalse);
      expect(controller.isDragging, isFalse);
      expect(controller.draggedItemId, isNull);
      expect(controller.sourceIndex, isNull);
      expect(controller.targetIndex, isNull);
      expect(controller.dragPosition, isNull);
    });
  });
}
