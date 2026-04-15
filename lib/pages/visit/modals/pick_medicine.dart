import 'package:camreport/constant/route.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PickMedicine extends StatefulWidget {
  final List<MedicineModel> medicines;
  const PickMedicine({super.key, required this.medicines});

  @override
  State<PickMedicine> createState() => _PickMedicineState();
}

class _PickMedicineState extends State<PickMedicine> {
  final DatabaseService db = DatabaseService();
  List<MedicineModel> medicines = [];
  List<MedicineModel> allMedicines = [];
  final TextEditingController searchController = TextEditingController();
  List<MedicineModel> selectedMedicine = [];

  @override
  void initState() {
    super.initState();
    selectedMedicine = List<MedicineModel>.from(widget.medicines);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _medicineKey(MedicineModel medicine) =>
      medicine.id ?? medicine.name ?? '';

  Future<void> _openMedicineForm([MedicineModel? medicine]) async {
    await Navigator.pushNamed(context, addMedicineView, arguments: medicine);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pilih Obat',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openMedicineForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selectedMedicine),
                  child: const Text('Selesai'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: searchController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                setState(() {
                  medicines = searchMedicines(
                    allMedicines,
                    searchController.text,
                  );
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama obat',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      medicines = searchMedicines(
                        allMedicines,
                        searchController.text,
                      );
                    });
                  },
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  medicines = searchMedicines(allMedicines, value);
                });
              },
            ),
            const SizedBox(height: 14),
            Expanded(child: _medicineList()),
          ],
        ),
      ),
    );
  }

  Widget _medicineList() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: StreamBuilder(
        stream: db.getMedicines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: SpinKitChasingDots(color: GlobalColors.primary),
            );
          }

          if (snapshot.data?.docs.isEmpty ?? false) {
            medicines = [];
            return const Center(child: Text('No Data'));
          }

          final List<QueryDocumentSnapshot> sortedData =
              (snapshot.data?.docs ?? []).toList()..sort((a, b) {
                final aData = a.data() as MedicineModel;
                final bData = b.data() as MedicineModel;
                return aData.name?.compareTo(bData.name ?? '') ?? 0;
              });
          allMedicines = sortedData
              .map((e) => e.data() as MedicineModel)
              .toList();
          medicines = searchMedicines(allMedicines, searchController.text);

          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) => _medicineItem(medicines[index]),
          );
        },
      ),
    );
  }

  Widget _medicineItem(MedicineModel medicine) {
    final selected = selectedMedicine.any(
      (e) => _medicineKey(e) == _medicineKey(medicine),
    );
    final inStock = (medicine.lastStock ?? 0) > 0;

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            selectedMedicine.removeWhere(
              (e) => _medicineKey(e) == _medicineKey(medicine),
            );
          } else {
            selectedMedicine.add(medicine);
          }
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? GlobalColors.primary : GlobalColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medicine.color ?? GlobalColors.secondary,
              ),
              alignment: Alignment.center,
              child: Text(
                Utils().getInitials(medicine.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${Utils.formatNumber(medicine.price ?? 0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: inStock
                          ? GlobalColors.success
                          : GlobalColors.danger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inStock
                        ? '${medicine.lastStock} ${medicine.measure}'
                        : 'Stok Habis',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: inStock
                          ? GlobalColors.success
                          : GlobalColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _openMedicineForm(medicine),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: GlobalColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: selected
                  ? GlobalColors.primary
                  : GlobalColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  List<MedicineModel> searchMedicines(
    List<MedicineModel> medicines,
    String query,
  ) {
    if (query.isEmpty) return List<MedicineModel>.from(medicines);

    final search = query.toLowerCase();
    return medicines
        .where((v) => (v.name ?? '').toLowerCase().contains(search))
        .toList();
  }
}
