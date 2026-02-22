import 'package:camreport/common/employee_item.dart';
import 'package:camreport/constant/assets.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class VisitPage extends StatefulWidget {
  const VisitPage({super.key});

  @override
  State<VisitPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> {
  DatabaseService db = DatabaseService();
  List<TransactionVisit> visits = [];
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Kunjungan"),
        actions: [
          GestureDetector(
            onTap: () {
              Utils.exportVisits(visits);
            },
            child: Image.asset(iconExport, width: 20, height: 20),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                isScrollControlled: true,
                isDismissible: false,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                enableDrag: false,
                context: context,
                builder: (ctx) {
                  return Column(
                    children: [
                      SizedBox(height: 24.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text(
                              "Pilih Kategori",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      ListTile(
                        title: Text('Kunjungan'),
                        onTap: () {
                          Navigator.pushNamed(context, addVisitView);
                        },
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Berobat'),
                        onTap: () {
                          Navigator.pushNamed(context, addTherapyView);
                        },
                      ),
                      Divider(),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false, // biar nggak bisa ditutup klik luar
                builder: (ctx) {
                  return Dialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      height: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(iconWarning, width: 150, height: 150),
                          Text("Hapus semua data kunjungan?"),
                          SizedBox(height: 24.0),
                          Row(
                            children: [
                              SizedBox(width: 24.0),
                              GestureDetector(
                                child: Text(
                                  "Tidak",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                              Spacer(),
                              GestureDetector(
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    "Ya, Hapus",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  try {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) {
                                        return Dialog(
                                          insetPadding: EdgeInsets.symmetric(
                                            horizontal: 148,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: SizedBox(
                                            height: 100,
                                            child: const Center(
                                              child: SpinKitChasingDots(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                    await db.deleteAllVisitData();
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    SnackBarUtil.showSnack(
                                      context,
                                      'Gagal menghapus data kunjungan ${e.toString()}',
                                    );
                                  }
                                },
                              ),
                              SizedBox(width: 24.0),
                            ],
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Search',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            visits = searchVisit(visits, searchController.text);
                          });
                        },
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.0),
          _visitList(),
        ],
      ),
    );
  }

  Widget _visitList() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * .79,
      width: MediaQuery.of(context).size.width,
      child: StreamBuilder(
        stream: db.getVisits(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data?.docs.isEmpty ?? false) {
              visits = [];
              return const Center(child: Text("No Data"));
            }

            if (searchController.text.isEmpty) {
              final formatter = DateFormat("dd-MMM-yy HH:mm");

              List<QueryDocumentSnapshot> sortedData =
                  (snapshot.data?.docs ?? []).toList()..sort((a, b) {
                    TransactionVisit dtA = a.data() as TransactionVisit;
                    TransactionVisit dtB = b.data() as TransactionVisit;

                    DateTime endA = formatter.parse(dtA.end);
                    DateTime endB = formatter.parse(dtB.end);

                    return endB.compareTo(endA); // desc, jam terakhir di atas
                  });

              visits = sortedData
                  .map((e) => e.data() as TransactionVisit)
                  .toList();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView.builder(
                itemCount: visits.length,
                itemBuilder: (context, index) {
                  TransactionVisit item = visits[index];
                  return ListItem<TransactionVisit>(
                    v: item,
                    onDelete: () => db.deleteVisit(item),
                  );
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

  List<TransactionVisit> searchVisit(
    List<TransactionVisit> vists,
    String query,
  ) {
    if (query.isEmpty) return vists;

    return vists.where((v) {
      final name = (v.employee.name ?? '').toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search);
    }).toList();
  }
}
