import 'dart:async';

import 'package:camreport/models/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:flutter/foundation.dart';

class EmployeeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  DatabaseService db = DatabaseService();

  List<EmployeeModel> _employees = [];
  List<EmployeeModel> _allEmployees = [];
  StreamSubscription? _employeeSubscription;

  List<EmployeeModel> get employees => _employees;

  bool _loading = false;
  bool get loading => _loading;
  EmployeeProvider? prov;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('loading', loading));
    properties.add(
      DiagnosticsProperty<List<EmployeeModel>>('employees', employees),
    );
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

  Future<void> deleteEmployee(EmployeeModel employee) async {
    await db.deleteEmployee(employee);
    notifyListeners();
  }

  Future<void> getEmployees() async {
    try {
      await _employeeSubscription?.cancel();
      _employeeSubscription = db.getEmployees().listen((snapshot) {
        final docs = snapshot.docs;
        List<EmployeeModel> data =
            docs.map((e) => e.data() as EmployeeModel).toList()
              ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        _allEmployees = data;
        employees = List<EmployeeModel>.from(data);
      });
    } catch (e) {
      throw Exception('Error fetching employees: $e');
    }
    notifyListeners();
  }

  void searchEmployees(List<EmployeeModel> data, String query) {
    if (query.isEmpty) {
      employees = List<EmployeeModel>.from(_allEmployees);
      return;
    }

    data = _allEmployees.where((employee) {
      final name = (employee.name ?? '').toLowerCase();
      final nip = (employee.nip ?? '').toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search) || nip.contains(search);
    }).toList();

    employees = data;

    notifyListeners();
  }

  @override
  void dispose() {
    _employeeSubscription?.cancel();
    super.dispose();
  }
}
