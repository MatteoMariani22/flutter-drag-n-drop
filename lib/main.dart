import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'drag_drop_controller.dart';

void main() {
  runApp(const DragDropDemoApp());
}

class DragDropDemoApp extends StatefulWidget {
  const DragDropDemoApp({super.key});

  @override
  State<DragDropDemoApp> createState() => _DragDropDemoAppState();
}

class _DragDropDemoAppState extends State<DragDropDemoApp> {
  late final DragDropController _controller;
  final _dragLayerKey = GlobalKey();
  final _gridViewportKey = GlobalKey();
  final _gridScrollController = ScrollController();
  DateTime? _lastReorderTime;

  @override
  void initState() {
    super.initState();
    _controller = DragDropController()..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter drag & drop',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6E9BFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF10141D),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drag & drop'),
      ),
      body: SafeArea(
        child: Listener(
          onPointerMove: (event) => _handlePointerMove(event.position),
          onPointerUp: (_) => _endDrag(),
          onPointerCancel: (_) => _endDrag(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_controller.isEditingMode) _controller.exitEditMode();
            },
            child: Stack(
              key: _dragLayerKey,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.isEditingMode
                            ? 'Edit mode'
                            : 'Long-press a card to move it',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _controller.isEditingMode
                            ? 'Move over another card to reorder. Tap to exit.'
                            : 'Dragging starts after a long press.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(child: _buildGrid()),
                    ],
                  ),
                ),
                if (_controller.isDragging &&
                    _controller.draggedItem != null &&
                    _controller.dragPosition != null)
                  _buildDragOverlay(_controller.draggedItem!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        const spacing = 12.0;
        const childAspectRatio = 0.92;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final tileHeight = tileWidth / childAspectRatio;
        final rows = (_controller.items.length / columns).ceil();
        final contentHeight = rows * tileHeight + (rows - 1) * spacing;

        return SizedBox.expand(
          key: _gridViewportKey,
          child: SingleChildScrollView(
            controller: _gridScrollController,
            child: SizedBox(
              width: constraints.maxWidth,
              height: contentHeight,
              child: Stack(
                children: [
                  for (var index = 0; index < _controller.items.length; index++)
                    _buildGridCard(
                      card: _controller.items[index],
                      index: index,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      spacing: spacing,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCard({
    required DragCard card,
    required int index,
    required double tileWidth,
    required double tileHeight,
    required double spacing,
  }) {
    final isDragged = _controller.isDragging &&
        _controller.draggedItemId == card.id;

    return AnimatedPositioned(
      key: ValueKey('position-${card.id}'),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuint,
      left: (index % 3) * (tileWidth + spacing),
      top: (index ~/ 3) * (tileHeight + spacing),
      width: tileWidth,
      height: tileHeight,
      child: Opacity(
        key: ValueKey('grid-${card.id}'),
        opacity: isDragged ? 0 : 1,
        child: GestureDetector(
          onLongPressStart: (details) {
            HapticFeedback.heavyImpact();
            _lastReorderTime = null;
            _controller.startDrag(
              index: index,
              position: details.globalPosition,
            );
          },
          child: _buildCard(card),
        ),
      ),
    );
  }

  Widget _buildCard(DragCard card) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      scale: _controller.isEditingMode ? 0.94 : 1,
      child: _buildCardFace(card),
    );
  }

  Widget _buildDragOverlay(DragCard card) {
    final layerContext = _dragLayerKey.currentContext;
    if (layerContext == null) return const SizedBox.shrink();
    final layer = layerContext.findRenderObject()! as RenderBox;
    final position = layer.globalToLocal(_controller.dragPosition!);
    final gridContext = _gridViewportKey.currentContext;
    final gridWidth = gridContext == null
        ? 0.0
        : (gridContext.findRenderObject()! as RenderBox).size.width;
    final tileWidth = (gridWidth - 24) / 3;
    final tileHeight = tileWidth / 0.92;

    return Positioned(
      left: position.dx - tileWidth / 2,
      top: position.dy - tileHeight / 2,
      width: tileWidth,
      height: tileHeight,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          elevation: 20,
          borderRadius: BorderRadius.circular(15),
          child: _buildCard(card),
        ),
      ),
    );
  }

  void _handlePointerMove(Offset globalPosition) {
    if (!_controller.isDragging) return;
    _controller.updateDragPosition(globalPosition);

    final index = _indexAt(globalPosition);
    final sourceIndex = _controller.sourceIndex;
    if (index == null || index == sourceIndex) return;

    final now = DateTime.now();
    if (_lastReorderTime != null &&
        now.difference(_lastReorderTime!).inMilliseconds < 400) {
      return;
    }

    _lastReorderTime = now;
    _controller.dropOn(index);
  }

  int? _indexAt(Offset globalPosition) {
    final gridContext = _gridViewportKey.currentContext;
    if (gridContext == null) return null;
    final grid = gridContext.findRenderObject()! as RenderBox;
    final position = grid.globalToLocal(globalPosition);
    if (!(Offset.zero & grid.size).contains(position)) return null;

    const columns = 3;
    const spacing = 12.0;
    const childAspectRatio = 0.92;
    final tileWidth = (grid.size.width - spacing * (columns - 1)) / columns;
    final tileHeight = tileWidth / childAspectRatio;
    final contentY = position.dy + _gridScrollController.offset;
    final column = (position.dx / (tileWidth + spacing)).floor();
    final row = (contentY / (tileHeight + spacing)).floor();

    if (column < 0 ||
        column >= columns ||
        row < 0 ||
        position.dx - column * (tileWidth + spacing) >= tileWidth ||
        contentY - row * (tileHeight + spacing) >= tileHeight) {
      return null;
    }

    final index = row * columns + column;
    return index < _controller.items.length ? index : null;
  }

  void _endDrag() {
    if (_controller.isDragging) _controller.endDrag();
  }

  Widget _buildCardFace(DragCard card) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: card.color.withOpacity(0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(card.icon, color: card.color, size: 34),
            const SizedBox(height: 10),
            Text(
              card.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
