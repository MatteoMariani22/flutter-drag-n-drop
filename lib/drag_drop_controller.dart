import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class DragCard {
  const DragCard({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
}

class DragDropController extends ChangeNotifier {
  DragDropController()
      : _items = List<DragCard>.of(_initialItems);

  static const List<DragCard> _initialItems = [
    DragCard(
      id: 'news',
      title: 'News',
      icon: Icons.article_outlined,
      color: Color(0xFF2864DC),
    ),
    DragCard(
      id: 'folders',
      title: 'Folders',
      icon: Icons.folder_outlined,
      color: Color(0xFF7B50C8),
    ),
    DragCard(
      id: 'saved',
      title: 'Saved',
      icon: Icons.bookmark_border,
      color: Color(0xFF168A83),
    ),
    DragCard(
      id: 'topics',
      title: 'Topics',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFCF6B25),
    ),
    DragCard(
      id: 'videos',
      title: 'Videos',
      icon: Icons.play_circle_outline,
      color: Color(0xFFB53D5A),
    ),
    DragCard(
      id: 'podcasts',
      title: 'Podcasts',
      icon: Icons.headphones_outlined,
      color: Color(0xFF487347),
    ),
  ];

  final List<DragCard> _items;

  List<DragCard> get items => List.unmodifiable(_items);

  DragCard? get draggedItem {
    final id = draggedItemId;
    if (id == null) return null;
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool isEditingMode = false;
  bool isDragging = false;
  String? draggedItemId;
  int? sourceIndex;
  int? targetIndex;
  Offset? dragPosition;

  void startDrag({required int index, required Offset position}) {
    RangeError.checkValidIndex(index, _items, 'index');

    isEditingMode = true;
    isDragging = true;
    draggedItemId = _items[index].id;
    sourceIndex = index;
    targetIndex = null;
    dragPosition = position;
    notifyListeners();
  }

  void updateDragPosition(Offset position) {
    if (!isDragging) return;
    dragPosition = position;
    notifyListeners();
  }

  void setTargetIndex(int? index) {
    if (!isDragging || targetIndex == index) return;
    if (index != null) RangeError.checkValidIndex(index, _items, 'index');
    targetIndex = index;
    notifyListeners();
  }

  void dropOn(int index) {
    if (!isDragging || sourceIndex == null) return;
    RangeError.checkValidIndex(index, _items, 'index');

    final source = sourceIndex!;
    if (source != index) {
      final movedItem = _items.removeAt(source);
      _items.insert(index, movedItem);
      sourceIndex = index;
    }
    targetIndex = index;
    notifyListeners();
  }

  void endDrag() {
    isDragging = false;
    targetIndex = null;
    dragPosition = null;
    notifyListeners();
  }

  void enterEditMode() {
    isEditingMode = true;
    isDragging = false;
    draggedItemId = null;
    targetIndex = null;
    dragPosition = null;
    notifyListeners();
  }

  void exitEditMode() {
    isEditingMode = false;
    isDragging = false;
    draggedItemId = null;
    sourceIndex = null;
    targetIndex = null;
    dragPosition = null;
    notifyListeners();
  }
}
