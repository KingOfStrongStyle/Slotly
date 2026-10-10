import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../domain/organization.dart';
import '../domain/service.dart';
import 'widgets/business_photo_view.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({
    super.key,
    required this.organizationName,
    required this.category,
    required this.photos,
    this.initialIndex = 0,
  });

  final String organizationName;
  final ServiceCategory category;
  final List<BusinessPhoto> photos;
  final int initialIndex;

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  final _zoom = TransformationController();
  double _dragOffset = 0;

  bool get _isZoomed => _zoom.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _zoom
      ..removeListener(_onZoomChanged)
      ..dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onZoomChanged() => setState(() {});

  void _resetZoom() => _zoom.value = Matrix4.identity();

  void _onPageChanged(int index) {
    _resetZoom();
    setState(() => _index = index);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(
      () => _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 600),
    );
  }

  // Ян: свайп вниз закрывает галерею, но только без зума, иначе он
  // конфликтует с перемещением увеличенного фото
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final fastSwipe = (details.primaryVelocity ?? 0) > 700;
    if (_dragOffset > 120 || fastSwipe) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    final fade = 1 - (_dragOffset / 600).clamp(0.0, 0.6);
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: AppStrings.galleryClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          total == 0
              ? widget.organizationName
              : AppStrings.galleryPosition(_index + 1, total),
        ),
        actions: [
          if (_isZoomed)
            IconButton(
              tooltip: AppStrings.galleryResetZoom,
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetZoom,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: PageView.builder(
            controller: _pages,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: total,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => Semantics(
              image: true,
              label: AppStrings.photoLabel(widget.organizationName, index + 1),
              hint: AppStrings.galleryHint,
              child: InteractiveViewer(
                transformationController: index == _index ? _zoom : null,
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.s),
                      child: BusinessPhotoView(
                        photo: widget.photos[index],
                        category: widget.category,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
