import 'package:camreport/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PickEmployee extends StatefulWidget {
  final EmployeeModel employee;
  const PickEmployee({super.key, required this.employee});

  @override
  State<PickEmployee> createState() => _PickEmployeeState();
}

class _PickEmployeeState extends State<PickEmployee> {
  DatabaseService db = DatabaseService();
  List<EmployeeModel> employees = [];
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pilih Karyawan",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: searchController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) {
                    setState(() {
                      employees = searchEmployees(
                        employees,
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
                          employees = searchEmployees(
                            employees,
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
                        employees = searchEmployees(
                          employees,
                          searchController.text,
                        );
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Expanded(
            child: StreamBuilder(
              stream: db.getEmployees(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data?.docs.isEmpty ?? false) {
                    employees = [];
                    return const Center(child: Text("No Data"));
                  }

                  if (searchController.text.isEmpty) {
                    List<QueryDocumentSnapshot> sortedData =
                        (snapshot.data?.docs ?? []).toList()..sort((a, b) {
                          EmployeeModel employeeA = a.data() as EmployeeModel;
                          EmployeeModel employeeB = b.data() as EmployeeModel;

                          return employeeA.name?.compareTo(
                                employeeB.name ?? '',
                              ) ??
                              0;
                        });
                    employees = sortedData
                        .map((e) => e.data() as EmployeeModel)
                        .toList();
                  }

                  return ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      EmployeeModel item = employees[index];
                      return _employeeItem(item);
                    },
                  );
                } else {
                  return const Center(
                    child: SpinKitChasingDots(color: Colors.blue),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeItem(EmployeeModel? employee) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, employee),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: employee?.color ?? Colors.grey,
                ),
                alignment: Alignment.center,
                child: Text(
                  Utils().getInitials(employee?.name),
                  style: const TextStyle(color: Colors.white, fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee?.name ?? '',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(employee?.nip ?? ''),
                  Text(employee?.deptnm ?? ''),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    employee?.nip == widget.employee.nip
                        ? Icons.radio_button_on
                        : Icons.radio_button_off,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EmployeeModel> searchEmployees(
    List<EmployeeModel> employees,
    String query,
  ) {
    if (query.isEmpty) return employees;

    return employees.where((employee) {
      final name = (employee.name ?? '').toLowerCase();
      final nip = (employee.nip ?? '').toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search) || nip.contains(search);
    }).toList();
  }
}
