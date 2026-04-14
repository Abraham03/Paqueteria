import 'package:flutter/material.dart';

class InfiniteScrollListWidget extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreData;
  final EdgeInsetsGeometry? padding;

  const InfiniteScrollListWidget({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMoreData,
    this.padding,
  });

  @override
  State<InfiniteScrollListWidget> createState() => _InfiniteScrollListWidgetState();
}

class _InfiniteScrollListWidgetState extends State<InfiniteScrollListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;

    // --- REGLA DE ORO ---
    // Si la lista no es scrolleable, o si el usuario NO ha movido 
    // la pantalla hacia abajo (currentScroll en 0), nos quedamos quietos.
    if (maxScroll <= 0 || currentScroll <= 0) return;

    // Solo disparamos la carga si el usuario bajó y está a 100 píxeles del fondo
    if (currentScroll >= (maxScroll - 100)) {
      if (!widget.isLoadingMore && widget.hasMoreData) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      // Sumamos 1 al itemCount si está cargando para mostrar el indicador al final
      itemCount: widget.itemCount + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.itemCount) {
          // Este es el último elemento falso: El indicador de carga
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        // Elemento normal de tu lista
        return widget.itemBuilder(context, index);
      },
    );
  }
}