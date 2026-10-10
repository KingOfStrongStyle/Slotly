import 'package:flutter/material.dart';

import '../../../core/app_strings.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.onImage = false,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;

  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? colors.error : (onImage ? colors.onSurface : null),
    );
    final tooltip = isFavorite
        ? AppStrings.favoriteRemove
        : AppStrings.favoriteAdd;
    return Semantics(
      toggled: isFavorite,
      child: onImage
          ? IconButton.filledTonal(
              tooltip: tooltip,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface.withValues(alpha: 0.9),
              ),
              onPressed: onPressed,
              icon: icon,
            )
          : IconButton(tooltip: tooltip, onPressed: onPressed, icon: icon),
    );
  }
}

class FavoriteBurst extends StatefulWidget {
  const FavoriteBurst({super.key, required this.trigger});

  final int trigger;

  @override
  State<FavoriteBurst> createState() => _FavoriteBurstState();
}

class _FavoriteBurstState extends State<FavoriteBurst>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(FavoriteBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          final opacity = t < 0.7 ? 1.0 : (1 - t) / 0.3;
          final scale = reduceMotion
              ? 1.0
              : Curves.easeOutBack.transform((t * 2).clamp(0, 1));
          return Center(
            child: Opacity(
              opacity: opacity.clamp(0, 1),
              child: Transform.scale(
                scale: scale,
                child: const Icon(
                  Icons.favorite,
                  size: 72,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 12, color: Colors.black38)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
