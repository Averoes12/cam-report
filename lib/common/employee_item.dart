import 'package:camreport/theme/global_colors.dart';
import 'package:flutter/material.dart';

class ListItem<T extends ListDisplayable> extends StatelessWidget {
  final T v;
  final void Function() onDelete;
  final void Function()? onEdit;

  const ListItem({
    super.key,
    required this.v,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(isMobile ? 28 : 999),
        border: Border.all(color: GlobalColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: GlobalColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            v.nip,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: GlobalColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onEdit != null) ...[
                      _ActionButton(
                        icon: Icons.edit_rounded,
                        onTap: onEdit,
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: onDelete,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(v.deptnm, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.start, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(v.end, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: GlobalColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: Text(
                    v.nip,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: GlobalColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(v.deptnm, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.start, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 2),
                        Text(v.end, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (onEdit != null) ...[
                  _ActionButton(icon: Icons.edit_rounded, onTap: onEdit),
                  const SizedBox(width: 10),
                ],
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                ),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 52.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: GlobalColors.textSecondary,
          size: compact ? 18 : 20,
        ),
      ),
    );
  }
}

abstract class ListDisplayable {
  String get name;
  String get nip;
  String get deptnm;
  String get start;
  String get end;
}
