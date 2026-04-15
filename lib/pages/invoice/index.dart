import 'package:camreport/constant/assets.dart';
import 'package:camreport/provider/invoice.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final allData = provider.groupedData.values.expand((v) => v).toList();
    final totalNominal = provider.calculateTotal(allData);
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            onPressed: () {
              Utils.exportInvoice(
                allData: allData,
                startPeriod: provider.startPeriod,
                endPeriod: provider.endPeriod,
              );
            },
            icon: Image.asset(iconExport, width: 20, height: 20),
          ),
        ],
      ),
      body: Container(
        color: GlobalColors.neutral,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E66F1), Color(0xFF7694BC)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Invoice',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              provider.periodLabel,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: GlobalColors.primary,
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: provider.selectedMonth,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  provider.changeMonth(picked);
                                }
                              },
                              child: Text(
                                DateFormat(
                                  'MMMM yyyy',
                                ).format(provider.selectedMonth),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ringkasan Invoice',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    provider.periodLabel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: GlobalColors.primary,
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: provider.selectedMonth,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  provider.changeMonth(picked);
                                }
                              },
                              child: Text(
                                DateFormat(
                                  'MMMM yyyy',
                                ).format(provider.selectedMonth),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 18),
                  isMobile
                      ? Column(
                          children: [
                            _summaryCard(
                              'Total Transaksi',
                              '${allData.length}',
                              Icons.receipt_long_rounded,
                            ),
                            const SizedBox(height: 12),
                            _summaryCard(
                              'Kelompok Status',
                              '${provider.groupedData.length}',
                              Icons.pie_chart_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            _summaryCard(
                              'Total Nominal',
                              'Rp ${NumberFormat('#,##0').format(totalNominal)}',
                              Icons.payments_outlined,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                'Total Transaksi',
                                '${allData.length}',
                                Icons.receipt_long_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'Kelompok Status',
                                '${provider.groupedData.length}',
                                Icons.pie_chart_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                'Total Nominal',
                                'Rp ${NumberFormat('#,##0').format(totalNominal)}',
                                Icons.payments_outlined,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            Expanded(
              child: allData.isEmpty
                  ? const Center(child: Text('Tidak ada data'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: provider.groupedData.entries.map((entry) {
                        final status = entry.key;
                        final data = entry.value;
                        final total = provider.calculateTotal(data);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            title: isMobile
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlobalColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                            color: GlobalColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '${data.length} transaksi',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp ${NumberFormat('#,##0').format(total)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GlobalColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                            color: GlobalColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${data.length} transaksi',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        'Rp ${NumberFormat('#,##0').format(total)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                            children: data.asMap().entries.map((item) {
                              final index = item.key;
                              final visit = item.value;
                              final date = DateFormat(
                                'dd-MMM-yy HH:mm',
                              ).parse(visit.end);
                              return _invoiceItem(
                                context,
                                index: index + 1,
                                nik: visit.employee.nip ?? '',
                                name: visit.employee.name ?? '',
                                dept: visit.employee.deptnm ?? '',
                                date: DateFormat('dd MMM yyyy').format(date),
                                type: visit.note,
                                total: NumberFormat(
                                  '#,##0',
                                ).format(visit.grandTotal),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceItem(
    BuildContext context, {
    required int index,
    required String nik,
    required String name,
    required String dept,
    required String date,
    required String type,
    required String total,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: GlobalColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nik,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: GlobalColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [_metaChip(date), _metaChip(type), _metaChip(dept)],
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
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: GlobalColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 130,
                  child: Text(
                    nik,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GlobalColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(dept, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    date,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  'Rp $total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: GlobalColors.textPrimary,
        ),
      ),
    );
  }
}
