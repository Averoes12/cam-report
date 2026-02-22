import 'dart:async';

import 'package:camreport/models/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:flutter/foundation.dart';

class EmployeeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  DatabaseService db = DatabaseService();

  List<EmployeeModel> _employees = [];

  List<EmployeeModel> get employees => _employees;

  bool _loading = false;
  bool get loading => _loading;
  EmployeeProvider? prov;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('loading', loading));
    properties.add(DiagnosticsProperty<List<EmployeeModel>>('employees', employees));
  }

  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  set employees(List<EmployeeModel> employees) {
    _employees = employees;
    notifyListeners();
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    await db.addEmployee(employee);
    notifyListeners();
  }

  Future<void> editEmployee(EmployeeModel employee) async {
    await db.editEmployee(employee);
    notifyListeners();
  }

  Future<void> getEmployees() async {
    try {
      db.getEmployees().listen((snapshot) {
        print('Fetched ${snapshot.docs.length} employees from Firestore');
        List<EmployeeModel> data = snapshot.docs
            .map((e) => e.data() as EmployeeModel)
            .toList();
        employees = data;
        Future.delayed(Duration(milliseconds: 300), () {
          _employees.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

          notifyListeners();
        });
      });
    } catch (e) {
      throw Exception('Error fetching employees: $e');
    }
    notifyListeners();
  }

  void searchEmployees(List<EmployeeModel> data, String query) {
    if (query.isEmpty) {
      getEmployees();
      return;
    }

    data = data.where((employee) {
      final name = (employee.name ?? '').toLowerCase();
      final nip = (employee.nip ?? '').toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search) || nip.contains(search);
    }).toList();

    employees = data;    

    notifyListeners();
  }
}
