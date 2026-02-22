import 'package:camreport/common/container_shadow.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/services/database_service.dart';
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
  DatabaseService db = DatabaseService();
  List<MedicineModel> medicines = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Obat")),
      body: Column(
        children: [
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    onFieldSubmitted: (e) {
                      setState(() {
                        medicines = searchMedicines(
                          medicines,
                          searchController.text,
                        );
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            medicines = searchMedicines(
                              medicines,
                              searchController.text,
                            );
                          });
                        },
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, addMedicineView),
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.0),
          _meidicineList(),
        ],
      ),
    );
  }

  Widget _meidicineList() {
    return Expanded(
      child: StreamBuilder(
        stream: db.getMedicines(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data?.docs.isEmpty ?? false) {
              medicines = [];
              return const Center(child: Text("No Data"));
            }

            if (searchController.text.isEmpty) {
              List<QueryDocumentSnapshot> sortedData =
                  (snapshot.data?.docs ?? []).toList()..sort((a, b) {
                    MedicineModel employeeA = a.data() as MedicineModel;
                    MedicineModel employeeB = b.data() as MedicineModel;

                    return employeeA.name?.compareTo(employeeB.name ?? '') ?? 0;
                  });
              medicines = sortedData
                  .map((e) => e.data() as MedicineModel)
                  .toList();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  MedicineModel item = medicines[index];
                  return _medicineItem(item);
                },
              ),
            );
          } else {
            return const Center(child: SpinKitChasingDots(color: Colors.blue));
          }
        },
      ),
    );
  }

  Widget _medicineItem(MedicineModel? medicine) {
    return Material(
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, addMedicineView, arguments: medicine),
        child: ContainerShadow(
          paddingHorizontal: 16.0,
          paddingVertical: 16.0,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          color: (medicine?.lastStock ?? 0) > 0 ? Colors.white : Colors.white54,
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medicine?.color ?? Colors.grey,
                ),
                alignment: Alignment.center,
                child: Text(
                  Utils().getInitials(medicine?.name),
                  style: const TextStyle(color: Colors.white, fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine?.name ?? '',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if ((medicine?.lastStock ?? 0) > 0) ...[
                    Text("${medicine?.lastStock} ${medicine?.measure}"),
                  ] else ...[
                    Text(
                      "Stok Habis",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  Text("Rp ${Utils.formatNumber(medicine?.price ?? 0)}"),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Hapus Obat"),
                        content: const Text(
                          "Anda yakin ingin menghapus obat ini?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Tidak"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await db.deleteMedicine(medicine!);
                              if (!mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text("Ya"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.delete, color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
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
      final name = (v.name)?.toLowerCase();
      final search = query.toLowerCase();
      return name?.contains(search) ?? false;
    }).toList();
  }
}
