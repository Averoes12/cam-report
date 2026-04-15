import 'package:camreport/common/employee_item.dart';
import 'package:camreport/constant/assets.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/transaction_therapy.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class TherapyPage extends StatefulWidget {
  const TherapyPage({super.key});

  @override
  State<TherapyPage> createState() => _TherapyPageState();
}

class _TherapyPageState extends State<TherapyPage> {
  final DatabaseService db = DatabaseService();
  final TextEditingController searchController = TextEditingController();
  DateTimeRange? selectedRange;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      initialDateRange: selectedRange,
    );
    if (picked != null) {
      setState(() => selectedRange = picked);
    }
  }

  List<TransactionTherapy> _filterTherapies(
    List<TransactionTherapy> therapies,
  ) {
    final query = searchController.text.toLowerCase();
    final formatter = DateFormat('dd-MMM-yy HH:mm');

    final filtered = therapies.where((therapy) {
      if (selectedRange == null) return true;
      final therapyDate = formatter.parse(therapy.end);
      final start = DateTime(
        selectedRange!.start.year,
        selectedRange!.start.month,
        selectedRange!.start.day,
      );
      final end = DateTime(
        selectedRange!.end.year,
        selectedRange!.end.month,
        selectedRange!.end.day,
        23,
        59,
        59,
      );
      return !therapyDate.isBefore(start) && !therapyDate.isAfter(end);
    }).toList();

    if (query.isEmpty) return filtered;

    return filtered.where((therapy) {
      return (therapy.employee.name ?? '').toLowerCase().contains(query) ||
          (therapy.employee.nip ?? '').toLowerCase().contains(query) ||
          (therapy.employee.deptnm ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteAllTherapies() async {
    try {
      await db.deleteAllTherapyData();
      if (!mounted) return;
      SnackBarUtil.showSuccess(context, 'Semua data berobat berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showSnack(context, 'Gagal menghapus data berobat. $e');
    }
  }

  String get _rangeLabel {
    if (selectedRange == null) return 'Semua tanggal';
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(selectedRange!.start)} - ${formatter.format(selectedRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berobat'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, addTherapyView),
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus Semua Data Berobat'),
                  content: const Text(
                    'Semua data berobat akan dihapus dan stok obat dikembalikan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await _deleteAllTherapies();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NIP, atau departemen',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                  label: const Text('Filter Tanggal'),
                ),
                if (selectedRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => selectedRange = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: db.getTherapy(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SpinKitChasingDots(color: GlobalColors.primary),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final allTherapies =
                    docs.map((e) => e.data() as TransactionTherapy).toList()
                      ..sort((a, b) {
                        final formatter = DateFormat('dd-MMM-yy HH:mm');
                        return formatter
                            .parse(b.end)
                            .compareTo(formatter.parse(a.end));
                      });
                final therapies = _filterTherapies(allTherapies);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Laporan Berobat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${therapies.length} data siap ditinjau',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _rangeLabel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Utils.exportTherapy(therapies),
                              child: Image.asset(
                                iconExport,
                                width: 22,
                                height: 22,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: therapies.isEmpty
                          ? const Center(child: Text('Tidak ada data berobat'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: therapies.length,
                              itemBuilder: (context, index) {
                                final item = therapies[index];
                                return ListItem<TransactionTherapy>(
                                  v: item,
                                  onEdit: () => Navigator.pushNamed(
                                    context,
                                    editTherapyView,
                                    arguments: item,
                                  ),
                                  onDelete: () => db.deleteTherapy(item),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
