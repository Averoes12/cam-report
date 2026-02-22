import 'package:camreport/models/medicine.dart';
import 'package:camreport/services/database_service.dart';
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
  DatabaseService db = DatabaseService();
  List<MedicineModel> medicines = [];
  TextEditingController searchController = TextEditingController();
  List<MedicineModel> selectedMedicine = [];

  @override
  void initState() {
    super.initState();
    selectedMedicine = widget.medicines;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (value) {
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
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          medicines = searchMedicines(
                            medicines,
                            searchController.text,
                          );
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 8.0),
                GestureDetector(
                  onTap: () => Navigator.pop(context, selectedMedicine),
                  child: Text(
                    "Selesai",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.0),
          Expanded(child: _meidicineList()),
        ],
      ),
    );
  }

  Widget _meidicineList() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * .8,
      width: MediaQuery.of(context).size.width,
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
    bool s = selectedMedicine.any((e) => e.name == medicine?.name);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (s) {
            selectedMedicine.removeWhere((e) => e.name == medicine?.name);
          } else {
            selectedMedicine.add(medicine!);
          }
        });
      },
      child: Card(
        color: (medicine?.lastStock ?? 0) > 0 ? Colors.white : Colors.white54,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  Text("Rp ${Utils.formatNumber(medicine?.price ?? 0)}"),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.check_box,
                    color: s ? Colors.blue : Colors.grey,
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
