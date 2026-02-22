import 'package:flutter/material.dart';

class ContainerShadow extends StatelessWidget {
  final Widget? child;
  final double paddingHorizontal, paddingVertical, radius, width;
  final bool reverse, useShadow;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final BoxBorder? border;
  final double? height;

  const ContainerShadow({
    super.key,
    this.child,
    this.paddingHorizontal = 0.0,
    this.paddingVertical = 0.0,
    this.radius = 4.0,
    this.reverse = false,
    this.useShadow = true,
    this.margin,
    this.color = Colors.white,
    this.border,
    this.height,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: border,
        boxShadow: [
          if (useShadow)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: reverse ? const Offset(4, 0) : const Offset(0, 4),
            ),
        ],
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
      child: child,
    );
  }
}
