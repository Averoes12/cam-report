import 'package:camreport/pages/employee/index.dart';
import 'package:camreport/pages/invoice/index.dart';
import 'package:camreport/pages/medicine/index.dart';
import 'package:camreport/pages/medicine/report.dart';
import 'package:camreport/pages/therapy/index.dart';
import 'package:camreport/pages/visit/index.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/pages/ocr/ocr_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  bool isSidebarVisible = true;

  final List<_MenuEntry> _mainMenu = const [
    _MenuEntry('Dashboard', Icons.grid_view_rounded, 0),
    _MenuEntry('Kunjungan', Icons.local_hospital_rounded, 0, isChild: true),
    _MenuEntry('Berobat', Icons.healing_rounded, 1, isChild: true),
    _MenuEntry('Karyawan', Icons.group_add_rounded, 2),
    _MenuEntry('Obat', Icons.medication_rounded, 3),
    _MenuEntry('Laporan Obat', Icons.bar_chart_rounded, 6),
  ];

  final List<_MenuEntry> _otherMenu = const [
    _MenuEntry('Invoice', Icons.receipt_long_rounded, 4),
    _MenuEntry('Handwriting OCR', Icons.document_scanner_rounded, 5),
    _MenuEntry('Admin Panel', Icons.admin_panel_settings_rounded, 2),
  ];

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return const VisitPage();
      case 1:
        return const TherapyPage();
      case 2:
        return const EmployeePage();
      case 3:
        return const MedicinePage();
      case 4:
        return const InvoicePage();
      case 5:
        return const OCRPage();
      case 6:
        return const MedicineReportPage();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 980;

    if (isCompact) {
      return Scaffold(
        body: _buildContent(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.local_hospital_rounded),
              label: 'Kunjungan',
            ),
            NavigationDestination(
              icon: Icon(Icons.healing_rounded),
              label: 'Berobat',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_rounded),
              label: 'Karyawan',
            ),
            NavigationDestination(
              icon: Icon(Icons.medication_rounded),
              label: 'Obat',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Laporan Obat',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Invoice',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_rounded),
              label: 'OCR',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (isSidebarVisible) ...[
                Container(
                  width: 340,
                  color: GlobalColors.surface,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Camreport',
                                        style: Theme.of(context).textTheme.headlineMedium,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.menu_open),
                                        onPressed: () => setState(() => isSidebarVisible = false),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Reporting obat dan kunjungan',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 28),
                                  _menuSection(
                                    context,
                                    'Menu',
                                    _mainMenu,
                                    expanded: true,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Divider(height: 1),
                                  ),
                                  _menuSection(context, 'Other Menu', _otherMenu),
                                  const Spacer(),
                                  const SizedBox(height: 16),
                                  _footerAction(context),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(width: 1, color: GlobalColors.border),
              ],
              Expanded(
                child: Container(
                  color: GlobalColors.neutral,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          if (!isSidebarVisible)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: FloatingActionButton.small(
                  onPressed: () => setState(() => isSidebarVisible = true),
                  child: const Icon(Icons.menu),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuSection(
    BuildContext context,
    String title,
    List<_MenuEntry> entries, {
    bool expanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(title, style: Theme.of(context).textTheme.bodySmall),
        ),
        ...entries.map((entry) {
          final isActive = entry.index == selectedIndex;
          final showChild = expanded && entry.isChild;
          final parentActive =
              expanded &&
              entry.label == 'Dashboard' &&
              (selectedIndex == 0 || selectedIndex == 1);

          if (showChild) {
            return Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => selectedIndex = entry.index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? GlobalColors.primary
                              : GlobalColors.border,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? GlobalColors.primary
                              : GlobalColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final selectedParent = entry.label == 'Dashboard'
              ? parentActive
              : isActive;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selectedParent
                  ? const Color(0xFFF2F7FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => selectedIndex = entry.index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selectedParent
                          ? const Color(0xFFBED3FF)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selectedParent
                              ? GlobalColors.primary.withValues(alpha: 0.12)
                              : GlobalColors.neutral,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          entry.icon,
                          color: selectedParent
                              ? GlobalColors.primary
                              : GlobalColors.textPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          entry.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: selectedParent
                                    ? GlobalColors.primary
                                    : GlobalColors.textPrimary,
                              ),
                        ),
                      ),
                      if (entry.label == 'Dashboard' ||
                          entry.label == 'Invoice')
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: selectedParent
                              ? GlobalColors.primary
                              : GlobalColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _footerAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: GlobalColors.neutral,
      ),
      child: Row(
        children: [
          const Icon(Icons.login_rounded, color: GlobalColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log In',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: GlobalColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  final String label;
  final IconData icon;
  final int index;
  final bool isChild;

  const _MenuEntry(this.label, this.icon, this.index, {this.isChild = false});
}
