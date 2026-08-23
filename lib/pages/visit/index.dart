import 'package:camreport/common/clearable_text_field.dart';
import 'package:camreport/common/employee_item.dart';
import 'package:camreport/constant/assets.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class VisitPage extends StatefulWidget {
  const VisitPage({super.key});

  @override
  State<VisitPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> {
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

  List<TransactionVisit> _filterVisits(List<TransactionVisit> visits) {
    final query = searchController.text.toLowerCase();
    final filtered = visits.where((visit) {
      if (selectedRange == null) return true;

      final visitDate = Utils.tryParseDate(visit.end);
      if (visitDate == null) return false;
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

      return !visitDate.isBefore(start) && !visitDate.isAfter(end);
    }).toList();

    if (query.isEmpty) return filtered;

    return filtered.where((visit) {
      return (visit.employee.name ?? '').toLowerCase().contains(query) ||
          (visit.employee.nip ?? '').toLowerCase().contains(query) ||
          (visit.employee.deptnm ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openVisitEditor(TransactionVisit visit) async {
    if (visit.category == 'therapy') {
      final therapyId = visit.id;
      if (therapyId == null) {
        if (!mounted) return;
        SnackBarUtil.showSnack(context, 'Data berobat tidak valid');
        return;
      }

      final therapy = await db.getTherapyById(therapyId);
      if (!mounted) return;
      if (therapy == null) {
        SnackBarUtil.showSnack(context, 'Data berobat tidak ditemukan');
        return;
      }

      Navigator.pushNamed(context, editTherapyView, arguments: therapy);
      return;
    }

    Navigator.pushNamed(context, editVisitView, arguments: visit);
  }

  Future<void> _deleteVisitEntry(TransactionVisit visit) async {
    try {
      if (visit.category == 'therapy') {
        final therapyId = visit.id;
        if (therapyId == null) {
          throw Exception('Data berobat tidak valid');
        }
        await db.deleteTherapyById(therapyId);
      } else {
        await db.deleteVisit(visit);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showSnack(context, 'Gagal menghapus data. $e');
    }
  }

  Future<void> _deleteAllVisits() async {
    try {
      await db.deleteAllVisitData();
      if (!mounted) return;
      SnackBarUtil.showSuccess(
        context,
        'Semua data kunjungan berhasil dihapus',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showSnack(context, 'Gagal menghapus data kunjungan. $e');
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
        title: const Text('Kunjungan'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tambah',
            icon: const Icon(Icons.add_circle_outline),
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            onSelected: (value) {
              if (value == 'kunjungan') {
                Navigator.pushNamed(context, addVisitView);
              } else if (value == 'berobat') {
                Navigator.pushNamed(context, addTherapyView);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                height: 36,
                child: Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const PopupMenuDivider(height: 8),
              const PopupMenuItem<String>(
                value: 'kunjungan',
                child: Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Kunjungan'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'berobat',
                child: Row(
                  children: [
                    Icon(Icons.healing_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Berobat'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus Semua Kunjungan'),
                  content: const Text(
                    'Semua data kunjungan akan dihapus dan stok obat dikembalikan.',
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
                await _deleteAllVisits();
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
                  child: ClearableTextFormField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    onCleared: () => setState(() {}),
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
              stream: db.getVisits(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SpinKitChasingDots(color: GlobalColors.primary),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final allVisits =
                    docs.map((e) => e.data() as TransactionVisit).toList()
                      ..sort((a, b) {
                        final dateA = Utils.tryParseDate(a.end) ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final dateB = Utils.tryParseDate(b.end) ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return dateB.compareTo(dateA);
                      });
                final visits = _filterVisits(allVisits);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              const Color(0xFF6F7BF7),
                            ],
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
                                    'Laporan Kunjungan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${visits.length} data siap ditinjau',
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
                              onTap: () => Utils.exportVisits(visits),
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
                      child: visits.isEmpty
                          ? const Center(
                              child: Text('Tidak ada data kunjungan'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: visits.length,
                              itemBuilder: (context, index) {
                                final item = visits[index];
                                return ListItem<TransactionVisit>(
                                  v: item,
                                  onEdit: () => _openVisitEditor(item),
                                  onDelete: () => _deleteVisitEntry(item),
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
