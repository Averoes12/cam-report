import 'package:camreport/common/clearable_text_field.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PickEmployee extends StatefulWidget {
  final EmployeeModel employee;
  const PickEmployee({super.key, required this.employee});

  @override
  State<PickEmployee> createState() => _PickEmployeeState();
}

class _PickEmployeeState extends State<PickEmployee> {
  final DatabaseService db = DatabaseService();
  List<EmployeeModel> employees = [];
  List<EmployeeModel> allEmployees = [];
  final TextEditingController searchController = TextEditingController();

  String _employeeKey(EmployeeModel employee) =>
      employee.id ?? employee.nip ?? '';

  Future<void> _openEmployeeForm([EmployeeModel? employee]) async {
    await Navigator.pushNamed(
      context,
      employee == null ? addEmployeeView : editEmployeeView,
      arguments: employee,
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pilih Karyawan',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openEmployeeForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClearableTextFormField(
              controller: searchController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                setState(() {
                  employees = searchEmployees(
                    allEmployees,
                    searchController.text,
                  );
                });
              },
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIP karyawan',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) {
                setState(() {
                  employees = searchEmployees(allEmployees, value);
                });
              },
              onCleared: () {
                setState(() {
                  employees = List<EmployeeModel>.from(allEmployees);
                });
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder(
                stream: db.getEmployees(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SpinKitChasingDots(color: GlobalColors.primary),
                    );
                  }

                  if (snapshot.data?.docs.isEmpty ?? false) {
                    employees = [];
                    return const Center(child: Text('No Data'));
                  }

                  final List<QueryDocumentSnapshot> sortedData =
                      (snapshot.data?.docs ?? []).toList()..sort((a, b) {
                        final aData = a.data() as EmployeeModel;
                        final bData = b.data() as EmployeeModel;
                        return aData.name?.compareTo(bData.name ?? '') ?? 0;
                      });
                  allEmployees = sortedData
                      .map((e) => e.data() as EmployeeModel)
                      .toList();
                  employees = searchEmployees(
                    allEmployees,
                    searchController.text,
                  );

                  return ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) =>
                        _employeeItem(employees[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _employeeItem(EmployeeModel employee) {
    final selected = _employeeKey(employee) == _employeeKey(widget.employee);

    return InkWell(
      onTap: () => Navigator.pop(context, employee),
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
                gradient: LinearGradient(
                  colors: [
                    employee.color ?? GlobalColors.secondary,
                    GlobalColors.primary,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                Utils().getInitials(employee.name),
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
                    employee.name ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${employee.nip ?? ''} • ${employee.deptnm ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _openEmployeeForm(employee),
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
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? GlobalColors.primary
                  : GlobalColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  List<EmployeeModel> searchEmployees(
    List<EmployeeModel> employees,
    String query,
  ) {
    if (query.isEmpty) return List<EmployeeModel>.from(employees);

    final search = query.toLowerCase();
    return employees.where((employee) {
      final name = (employee.name ?? '').toLowerCase();
      final nip = (employee.nip ?? '').toLowerCase();
      return name.contains(search) || nip.contains(search);
    }).toList();
  }
}
