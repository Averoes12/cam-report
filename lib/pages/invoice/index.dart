import 'package:camreport/common/employee_item.dart';
import 'package:camreport/constant/assets.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
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
          IconButton(
            onPressed: () {
              Utils.exportVisits(visits);
            },
            icon: Image.asset(iconExport, width: 20, height: 20),
          ),
          IconButton(
            icon: const Icon(Icons.filter),
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
