import 'package:camreport/constant/route.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/provider/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  DatabaseService db = DatabaseService();
  List<EmployeeModel> employees = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    // searchController.dispose();
    super.dispose();
  }

  void _init() {
    getEmployee();
  }

  Future<void> getEmployee([bool refresh = false]) async {
    final prov = Provider.of<EmployeeProvider>(context, listen: false);
    prov.loading = true;
    try {
      if (prov.employees.isEmpty || refresh) {
        await prov.getEmployees();
      }
      prov.loading = false;
    } catch (e) {
      prov.loading = false;
      throw Exception('Error fetching employees: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Karyawan")),
      body: Consumer<EmployeeProvider>(
        builder: (context, prov, _) {
          return Column(
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
                          prov.searchEmployees(
                            employees,
                            searchController.text,
                          );
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Search',
                          suffixIcon: IconButton(
                            onPressed: () {
                              prov.searchEmployees(
                                employees,
                                searchController.text,
                              );
                            },
                            icon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, addEmployeeView),
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.0),
              Expanded(child: _employeeList(prov)),
            ],
          );
        },
      ),
    );
  }

  Widget _employeeList(EmployeeProvider prov) {
    employees = prov.employees;
    return SizedBox(
      height: MediaQuery.of(context).size.height * .8,
      width: MediaQuery.of(context).size.width,
      child: Visibility(
        visible: !prov.loading,
        replacement: const Center(
          child: SpinKitChasingDots(color: Colors.blue),
        ),
        child: Visibility(
          visible: employees.isNotEmpty,
          replacement: const Center(child: Text("No Data")),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                EmployeeModel item = employees[index];
                return _employeeItem(item);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _employeeItem(EmployeeModel? employee) {
    return Card(
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
          ],
        ),
      ),
    );
  }
}
