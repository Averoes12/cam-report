import 'package:camreport/common/clearable_text_field.dart';
import 'package:camreport/constant/assets.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class MedicineReportPage extends StatefulWidget {
  const MedicineReportPage({super.key});

  @override
  State<MedicineReportPage> createState() => _MedicineReportPageState();
}

class _MedicineReportPageState extends State<MedicineReportPage> {
  final DatabaseService db = DatabaseService();
  final TextEditingController searchController = TextEditingController();

  DateTimeRange? selectedRange;
  bool isTableView = false;
  bool onlyUsed = false;
  
  bool _isLoading = true;
  List<MedicineModel> _allMedicines = [];
  List<TransactionVisit> _allVisits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final medSnap = await db.getMedicines().first;
      final visitSnap = await db.getVisits().first;

      _allMedicines = medSnap.docs
          .map((e) => e.data() as MedicineModel)
          .toList()
        ..sort((a, b) => (a.name ?? '')
            .toLowerCase()
            .compareTo((b.name ?? '').toLowerCase()));

      _allVisits = visitSnap.docs
          .map((e) => e.data() as TransactionVisit)
          .toList();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  String get _rangeLabel {
    if (selectedRange == null) return 'Semua Tanggal';
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(selectedRange!.start)} - ${formatter.format(selectedRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pemakaian Obat'),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: isTableView ? 'Tampilan Tabel' : 'Tampilan Kartu',
            icon: Icon(
              isTableView
                  ? Icons.view_agenda_outlined
                  : Icons.table_chart_outlined,
            ),
            onPressed: () {
              setState(() {
                isTableView = !isTableView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitChasingDots(color: GlobalColors.primary),
            )
          : _buildReportContent(
              context,
              medicines: _allMedicines,
              visits: _allVisits,
              isMobile: isMobile,
            ),
    );
  }

  Widget _buildReportContent(
    BuildContext context, {
    required List<MedicineModel> medicines,
    required List<TransactionVisit> visits,
    required bool isMobile,
  }) {
    // 1. Filter visits by date range
    final filteredVisits = visits.where((visit) {
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

    // 2. Aggregate medicine usage per date
    // Map: medicineName -> (dateKey -> totalQty)
    final Map<String, Map<String, int>> dailyMedicine = {};
    final Set<String> dateKeySet = {};
    final Map<String, String> dateDisplayLabels = {};

    for (final med in medicines) {
      dailyMedicine[med.name ?? '-'] = {};
    }

    int grandTotalUnits = 0;
    int grandTotalValue = 0;

    for (final visit in filteredVisits) {
      final parsedDate = Utils.tryParseDate(visit.end);
      final dateKey =
          parsedDate != null
              ? DateFormat('yyyy-MM-dd').format(parsedDate)
              : visit.end.split(' ')[0];
      final dateLabel =
          parsedDate != null
              ? DateFormat('dd MMM yy').format(parsedDate)
              : dateKey;

      dateKeySet.add(dateKey);
      dateDisplayLabels[dateKey] = dateLabel;

      for (final med in visit.medicines) {
        final medName = med.name ?? '-';
        final qty = med.total ?? 0;
        if (qty <= 0) continue;

        dailyMedicine.putIfAbsent(medName, () => {});
        dailyMedicine[medName]![dateKey] =
            (dailyMedicine[medName]![dateKey] ?? 0) + qty;
        grandTotalUnits += qty;
        grandTotalValue += qty * (med.price ?? 0);
      }
    }

    // Build all consecutive dates including weekends for the period
    final List<String> sortedDateKeys = [];
    if (selectedRange != null) {
      DateTime cur = DateTime(
        selectedRange!.start.year,
        selectedRange!.start.month,
        selectedRange!.start.day,
      );
      final end = DateTime(
        selectedRange!.end.year,
        selectedRange!.end.month,
        selectedRange!.end.day,
      );
      while (!cur.isAfter(end)) {
        final dateKey = DateFormat('yyyy-MM-dd').format(cur);
        final dateLabel = DateFormat('dd MMM yy').format(cur);
        sortedDateKeys.add(dateKey);
        dateDisplayLabels[dateKey] = dateLabel;
        cur = cur.add(const Duration(days: 1));
      }
    } else {
      DateTime? minDate;
      DateTime? maxDate;
      for (final visit in filteredVisits) {
        final parsedDate = Utils.tryParseDate(visit.end);
        if (parsedDate != null) {
          if (minDate == null || parsedDate.isBefore(minDate)) {
            minDate = parsedDate;
          }
          if (maxDate == null || parsedDate.isAfter(maxDate)) {
            maxDate = parsedDate;
          }
        }
      }

      if (minDate != null && maxDate != null) {
        DateTime cur = DateTime(minDate.year, minDate.month, minDate.day);
        final end = DateTime(maxDate.year, maxDate.month, maxDate.day);
        while (!cur.isAfter(end)) {
          final dateKey = DateFormat('yyyy-MM-dd').format(cur);
          final dateLabel = DateFormat('dd MMM yy').format(cur);
          sortedDateKeys.add(dateKey);
          dateDisplayLabels[dateKey] = dateLabel;
          cur = cur.add(const Duration(days: 1));
        }
      } else {
        final now = DateTime.now();
        DateTime cur = DateTime(now.year, now.month - 1, 26);
        final end = DateTime(now.year, now.month, 25);
        while (!cur.isAfter(end)) {
          final dateKey = DateFormat('yyyy-MM-dd').format(cur);
          final dateLabel = DateFormat('dd MMM yy').format(cur);
          sortedDateKeys.add(dateKey);
          dateDisplayLabels[dateKey] = dateLabel;
          cur = cur.add(const Duration(days: 1));
        }
      }
    }

    // 3. Search and filter medicines
    final query = searchController.text.toLowerCase().trim();
    List<MedicineModel> displayMedicines =
        medicines.where((med) {
          final name = (med.name ?? '').toLowerCase();
          final matchesQuery = query.isEmpty || name.contains(query);
          if (!matchesQuery) return false;

          if (onlyUsed) {
            final dateMap = dailyMedicine[med.name ?? '-'] ?? {};
            final totalUsed = dateMap.values.fold(0, (acc, v) => acc + v);
            if (totalUsed <= 0) return false;
          }
          return true;
        }).toList();

    // Count how many medicines had usage
    final usedMedicineCount =
        medicines.where((med) {
          final dateMap = dailyMedicine[med.name ?? '-'] ?? {};
          return dateMap.values.any((qty) => qty > 0);
        }).length;

    return Container(
      color: GlobalColors.neutral,
      child: Column(
        children: [
          // Filter & Search Header
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
                      hintText: 'Cari nama obat...',
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
                  label: Text(
                    selectedRange == null ? 'Filter Tanggal' : _rangeLabel,
                  ),
                ),
                if (selectedRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Hapus Filter Tanggal',
                    onPressed: () => setState(() => selectedRange = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
          ),

          // Secondary filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    onlyUsed
                        ? 'Hanya Obat Terpakai ($usedMedicineCount)'
                        : 'Semua Obat (${medicines.length})',
                  ),
                  selected: onlyUsed,
                  onSelected: (val) => setState(() => onlyUsed = val),
                  selectedColor: GlobalColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: GlobalColors.primary,
                  labelStyle: TextStyle(
                    color: onlyUsed
                        ? GlobalColors.primary
                        : GlobalColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: onlyUsed
                          ? GlobalColors.primary
                          : GlobalColors.border,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${displayMedicines.length} obat ditemukan',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Gradient Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E5BB8), Color(0xFF4A84E6)],
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
                          'Rekapitulasi Pemakaian Obat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Total Terpakai: $grandTotalUnits unit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Total Nilai: Rp ${Utils.formatNumber(grandTotalValue)}',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              'Periode: $_rangeLabel',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      List<String> exportDates = [];
                      if (selectedRange != null) {
                        DateTime cur = DateTime(
                          selectedRange!.start.year,
                          selectedRange!.start.month,
                          selectedRange!.start.day,
                        );
                        final endDate = DateTime(
                          selectedRange!.end.year,
                          selectedRange!.end.month,
                          selectedRange!.end.day,
                        );
                        while (!cur.isAfter(endDate)) {
                          exportDates.add(DateFormat('yyyy-MM-dd').format(cur));
                          cur = cur.add(const Duration(days: 1));
                        }
                      } else {
                        exportDates = sortedDateKeys;
                      }

                      Utils.exportMedicineReport(
                        medicines: displayMedicines,
                        dailyMedicine: dailyMedicine,
                        allDates: exportDates,
                        dateLabels: dateDisplayLabels,
                        periodLabel:
                            selectedRange != null
                                ? Utils.formatIndonesianMonthRange(
                                  selectedRange!.start,
                                  selectedRange!.end,
                                )
                                : _rangeLabel,
                        startDate: selectedRange?.start,
                        endDate: selectedRange?.end,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            iconExport,
                            width: 20,
                            height: 20,
                            color: Colors.white,
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Export Excel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main Content: Table or Card View
          Expanded(
            child: displayMedicines.isEmpty
                ? const Center(child: Text('Tidak ada data obat'))
                : isTableView
                    ? _buildTableView(
                        context,
                        medicines: displayMedicines,
                        dailyMedicine: dailyMedicine,
                        dates: sortedDateKeys,
                        dateLabels: dateDisplayLabels,
                      )
                    : _buildCardListView(
                        context,
                        medicines: displayMedicines,
                        dailyMedicine: dailyMedicine,
                        dates: sortedDateKeys,
                        dateLabels: dateDisplayLabels,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(
    BuildContext context, {
    required List<MedicineModel> medicines,
    required Map<String, Map<String, int>> dailyMedicine,
    required List<String> dates,
    required Map<String, String> dateLabels,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GlobalColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF1F5FD),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                color: GlobalColors.textPrimary,
                fontSize: 13,
              ),
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              horizontalMargin: 16,
              columnSpacing: 20,
              columns: [
                const DataColumn(label: Text('No')),
                const DataColumn(label: Text('Nama Obat')),
                const DataColumn(label: Text('Satuan')),
                const DataColumn(label: Text('Harga (Rp)')),
                ...dates.map(
                  (d) => DataColumn(
                    label: Text(
                      dateLabels[d] ?? d,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const DataColumn(label: Text('Total Terpakai')),
                const DataColumn(label: Text('Total Nominal')),
              ],
              rows:
                  medicines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final med = entry.value;
                    final medName = med.name ?? '-';
                    final dateMap = dailyMedicine[medName] ?? {};

                    int totalQty = 0;
                    for (final d in dates) {
                      totalQty += dateMap[d] ?? 0;
                    }
                    final totalCost = totalQty * (med.price ?? 0);

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (index.isEven) return const Color(0xFFFAFCFF);
                        return Colors.white;
                      }),
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(
                          Text(
                            medName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(Text(med.measure ?? '-')),
                        DataCell(
                          Text(
                            'Rp ${Utils.formatNumber(med.price ?? 0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ...dates.map((d) {
                          final qty = dateMap[d] ?? 0;
                          return DataCell(
                            Center(
                              child:
                                  qty > 0
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlobalColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: GlobalColors.primary,
                                          ),
                                        ),
                                      )
                                      : const Text(
                                        '-',
                                        style: TextStyle(
                                          color: GlobalColors.textSecondary,
                                        ),
                                      ),
                            ),
                          );
                        }),
                        DataCell(
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    totalQty > 0
                                        ? const Color(0xFFE8F5E9)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$totalQty ${med.measure ?? ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      totalQty > 0
                                          ? const Color(0xFF2E7D32)
                                          : GlobalColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'Rp ${Utils.formatNumber(totalCost)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: GlobalColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardListView(
    BuildContext context, {
    required List<MedicineModel> medicines,
    required Map<String, Map<String, int>> dailyMedicine,
    required List<String> dates,
    required Map<String, String> dateLabels,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final med = medicines[index];
        final medName = med.name ?? '-';
        final dateMap = dailyMedicine[medName] ?? {};

        int totalQty = 0;
        final List<MapEntry<String, int>> activeDateEntries = [];
        for (final d in dates) {
          final qty = dateMap[d] ?? 0;
          if (qty > 0) {
            totalQty += qty;
            activeDateEntries.add(MapEntry(d, qty));
          }
        }
        final totalCost = totalQty * (med.price ?? 0);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GlobalColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: med.color ?? GlobalColors.secondary,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      Utils().getInitials(med.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rp ${Utils.formatNumber(med.price ?? 0)} / ${med.measure ?? 'unit'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              totalQty > 0
                                  ? GlobalColors.primary.withValues(alpha: 0.12)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$totalQty ${med.measure ?? ''} dipakai',
                          style: TextStyle(
                            color:
                                totalQty > 0
                                    ? GlobalColors.primary
                                    : GlobalColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${Utils.formatNumber(totalCost)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: GlobalColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (activeDateEntries.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                const Text(
                  'Pemakaian per Tanggal:',
                  style: TextStyle(
                    fontSize: 12,
                    color: GlobalColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      activeDateEntries.map((e) {
                        final label = dateLabels[e.key] ?? e.key;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F7FE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD6E3F8),
                            ),
                          ),
                          child: Text(
                            '$label: ${e.value} ${med.measure ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: GlobalColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'Belum ada pemakaian pada periode ini',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: GlobalColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
