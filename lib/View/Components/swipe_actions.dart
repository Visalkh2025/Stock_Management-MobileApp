import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';

/// Wraps a row/card so a left swipe reveals Edit + Delete buttons behind it (same "swipe to reveal" pattern as iOS Mail) instead of showing those icons inline all the time.
class AppSwipeActions extends StatefulWidget {
  const AppSwipeActions({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final BorderRadius borderRadius;

  @override
  State<AppSwipeActions> createState() => _AppSwipeActionsState();
}

class _AppSwipeActionsState extends State<AppSwipeActions> with SingleTickerProviderStateMixin {
  static const double _buttonWidth = 64;
  static const double _buttonGap = 6;
  // Now applied on both sides (left AND right) — counted once here.
  static const double _actionsHorizontalInset = 8;
  static const double _actionsWidth = _buttonWidth * 2 + _buttonGap + _actionsHorizontalInset * 2;

  // 0 = closed (actions hidden), 1 = fully open (actions fully revealed).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _controller.value -= details.primaryDelta! / _actionsWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      _controller.animateTo(1);
    } else if (velocity > 300) {
      _controller.animateTo(0);
    } else {
      // No decisive flick — snap to whichever side it's closer to.
      _controller.animateTo(_controller.value > 0.5 ? 1 : 0);
    }
  }

  void _close() => _controller.animateTo(0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: _actionsWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _actionsHorizontalInset),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.brand700.withAlpha(200),
                      onTap: () {
                        _close();
                        widget.onEdit();
                      },
                    ),
                    const SizedBox(width: _buttonGap),
                    _actionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.dangerBg1.withAlpha(110),
                      iconColor: AppColors.danger,
                      onTap: () {
                        _close();
                        widget.onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_actionsWidth * _controller.value, 0),
                  child: child,
                );
              },
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    return SizedBox(
      width: _buttonWidth,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Center(child: Icon(icon, size: 25, color: iconColor)),
        ),
      ),
    );
  }
}
