import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
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

    final isTherapy = v.category == 'therapy';
    final leadingIcon =
        isTherapy ? Icons.healing_rounded : Icons.description_outlined;
    final leadingIconColor =
        isTherapy ? const Color(0xFF059669) : GlobalColors.textSecondary;
    final leadingBgColor =
        isTherapy ? const Color(0xFFECFDF5) : Colors.white;

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
                      decoration: BoxDecoration(
                        color: leadingBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        leadingIcon,
                        color: leadingIconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(v.name, style: theme.textTheme.titleMedium),
                              _TypeBadge(category: v.category),
                            ],
                          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${v.deptnm}${v.status != null && v.status!.trim().isNotEmpty ? ' • ${v.status}' : ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rp ${Utils.formatNumber(v.grandTotal)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: GlobalColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
                  decoration: BoxDecoration(
                    color: leadingBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    leadingIcon,
                    color: leadingIconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(v.name, style: theme.textTheme.titleMedium),
                          _TypeBadge(category: v.category),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${v.deptnm}${v.status != null && v.status!.trim().isNotEmpty ? ' • ${v.status}' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
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
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Harga',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: GlobalColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rp ${Utils.formatNumber(v.grandTotal)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GlobalColors.primary,
                        ),
                      ),
                    ],
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

class _TypeBadge extends StatelessWidget {
  final String? category;

  const _TypeBadge({this.category});

  @override
  Widget build(BuildContext context) {
    final isTherapy = category == 'therapy';
    final label = isTherapy ? 'Berobat' : 'Kunjungan';
    final bgColor = isTherapy
        ? const Color(0xFFECFDF5)
        : const Color(0xFFEFF6FF);
    final textColor = isTherapy
        ? const Color(0xFF059669)
        : const Color(0xFF2563EB);
    final borderColor = isTherapy
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFBFDBFE);
    final icon = isTherapy
        ? Icons.healing_rounded
        : Icons.local_hospital_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
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
  String? get status;
  String get start;
  String get end;
  int get grandTotal;
  String? get category;
}
