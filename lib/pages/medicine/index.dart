import 'package:camreport/common/clearable_text_field.dart';
import 'package:camreport/common/container_shadow.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MedicinePage extends StatefulWidget {
  const MedicinePage({super.key});

  @override
  State<MedicinePage> createState() => _MedicinePageState();
}

class _MedicinePageState extends State<MedicinePage> {
  final DatabaseService db = DatabaseService();
  List<MedicineModel> medicines = [];
  List<MedicineModel> allMedicines = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Obat')),
      body: Container(
        color: GlobalColors.neutral,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GlobalColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ClearableTextFormField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          medicines = searchMedicines(allMedicines, value);
                        });
                      },
                      onFieldSubmitted: (_) {
                        setState(() {
                          medicines = searchMedicines(
                            allMedicines,
                            searchController.text,
                          );
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Cari nama obat',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onCleared: () {
                        setState(() {
                          medicines = List<MedicineModel>.from(allMedicines);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, addMedicineView),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Obat'),
                  ),
                ],
              ),
            ),
            _medicineList(),
          ],
        ),
      ),
    );
  }

  Widget _medicineList() {
    return Expanded(
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

          if (searchController.text.isEmpty) {
            final List<QueryDocumentSnapshot> sortedData =
                (snapshot.data?.docs ?? []).toList()..sort((a, b) {
                  final aData = a.data() as MedicineModel;
                  final bData = b.data() as MedicineModel;
                  return aData.name?.compareTo(bData.name ?? '') ?? 0;
                });
            allMedicines = sortedData
                .map((e) => e.data() as MedicineModel)
                .toList();
            medicines = List<MedicineModel>.from(allMedicines);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) => _medicineItem(medicines[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _medicineItem(MedicineModel medicine) {
    final inStock = (medicine.lastStock ?? 0) > 0;
    final isMobile = MediaQuery.of(context).size.width < 720;

    return InkWell(
      borderRadius: BorderRadius.circular(isMobile ? 28 : 999),
      onTap: () =>
          Navigator.pushNamed(context, addMedicineView, arguments: medicine),
      child: ContainerShadow(
        paddingHorizontal: 18,
        paddingVertical: 16,
        margin: const EdgeInsets.only(bottom: 12),
        radius: isMobile ? 28 : 999,
        color: const Color(0xFFF7FAFF),
        useShadow: false,
        border: Border.all(color: GlobalColors.border),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.name ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${Utils.formatNumber(medicine.price ?? 0)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      _circleButton(
                        icon: Icons.delete_outline_rounded,
                        compact: true,
                        onTap: () => _confirmDeleteMedicine(medicine),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chipLabel(medicine.measure ?? '-'),
                      _chipLabel(
                        inStock
                            ? '${medicine.lastStock} ${medicine.measure}'
                            : 'Stok Habis',
                        color: inStock
                            ? GlobalColors.success
                            : GlobalColors.danger,
                      ),
                    ],
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
                      Icons.medication_liquid_outlined,
                      color: GlobalColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                    flex: 3,
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
                  Expanded(
                    child: Text(
                      medicine.measure ?? '-',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                          Flexible(
                            child: Text(
                              inStock
                                  ? '${medicine.lastStock} ${medicine.measure}'
                                  : 'Stok Habis',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: inStock
                                        ? GlobalColors.success
                                        : GlobalColors.danger,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _circleButton(
                    icon: Icons.delete_outline_rounded,
                    onTap: () => _confirmDeleteMedicine(medicine),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDeleteMedicine(MedicineModel medicine) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: const Text('Anda yakin ingin menghapus obat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              await db.deleteMedicine(medicine);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  Widget _chipLabel(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? GlobalColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool compact = false,
  }) {
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
          size: compact ? 18 : 24,
        ),
      ),
    );
  }

  List<MedicineModel> searchMedicines(
    List<MedicineModel> medicines,
    String query,
  ) {
    if (query.isEmpty) return medicines;

    return medicines.where((v) {
      final name = (v.name ?? '').toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
  }
}
