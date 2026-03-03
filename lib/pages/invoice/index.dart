import 'package:camreport/constant/assets.dart';
import 'package:camreport/provider/invoice.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice"),
        actions: [
          GestureDetector(
            onTap: () {
              Utils.exportInvoice(
                allData: provider.groupedData.values.expand((v) => v).toList(),
                startPeriod: provider.startPeriod,
                endPeriod: provider.endPeriod,
              );
            },
            child: Image.asset(iconExport, width: 20, height: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // ===== SELECT BULAN =====
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Periode: "),
              const SizedBox(width: 12),
              ElevatedButton(
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
                  DateFormat('MMMM yyyy').format(provider.selectedMonth),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                provider.periodLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: provider.groupedData.isEmpty
                ? const Center(child: Text("Tidak ada data"))
                : ListView(
                    children: provider.groupedData.entries.map((entry) {
                      final status = entry.key;
                      final data = entry.value;
                      final total = provider.calculateTotal(data);

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: ExpansionTile(
                          title: Text(
                            "$status (Total: ${NumberFormat('#,##0').format(total)})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("No")),
                                  DataColumn(label: Text("Tanggal")),
                                  DataColumn(label: Text("NIK")),
                                  DataColumn(label: Text("Nama")),
                                  DataColumn(label: Text("Dept")),
                                  DataColumn(label: Text("Total")),
                                ],
                                rows: List.generate(data.length, (index) {
                                  final visit = data[index];

                                  final date = DateFormat(
                                    "dd-MMM-yy HH:mm",
                                  ).parse(visit.end);

                                  return DataRow(
                                    cells: [
                                      DataCell(Text("${index + 1}")),
                                      DataCell(
                                        Text(
                                          DateFormat("dd-MMM-yy").format(date),
                                        ),
                                      ),
                                      DataCell(Text(visit.employee.nip ?? "")),
                                      DataCell(Text(visit.employee.name ?? "")),
                                      DataCell(
                                        Text(visit.employee.deptnm ?? ""),
                                      ),
                                      DataCell(
                                        Text(
                                          NumberFormat(
                                            '#,##0',
                                          ).format(visit.grandTotal),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
