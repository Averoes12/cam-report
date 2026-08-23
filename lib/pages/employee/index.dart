import 'package:camreport/common/clearable_text_field.dart';
import 'package:camreport/constant/route.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/provider/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/theme/global_colors.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final DatabaseService db = DatabaseService();
  List<EmployeeModel> employees = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getEmployee();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Karyawan')),
      body: Consumer<EmployeeProvider>(
        builder: (context, prov, _) {
          return Container(
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
                            prov.searchEmployees(employees, value);
                            setState(() {});
                          },
                          onFieldSubmitted: (_) {
                            prov.searchEmployees(
                              employees,
                              searchController.text,
                            );
                          },
                          decoration: const InputDecoration(
                            hintText: 'Cari nama atau NIP karyawan',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onCleared: () {
                            prov.searchEmployees(employees, '');
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, addEmployeeView),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Karyawan'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _employeeList(prov)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _employeeList(EmployeeProvider prov) {
    employees = prov.employees;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Visibility(
        visible: !prov.loading,
        replacement: const Center(
          child: SpinKitChasingDots(color: GlobalColors.primary),
        ),
        child: Visibility(
          visible: employees.isNotEmpty,
          replacement: const Center(child: Text('No Data')),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final item = employees[index];
                return _employeeItem(item);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _employeeItem(EmployeeModel employee) {
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(isMobile ? 28 : 999),
        border: Border.all(color: GlobalColors.border),
      ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.nip ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: GlobalColors.primary),
                          ),
                        ],
                      ),
                    ),
                    _circleButton(
                      icon: Icons.edit_rounded,
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        editEmployeeView,
                        arguments: employee,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _circleButton(
                      icon: Icons.delete_outline_rounded,
                      compact: true,
                      onTap: () => _confirmDeleteEmployee(employee),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  employee.deptnm ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${employee.gender == 'F' ? 'Female' : 'Male'}, ${employee.status ?? '-'}',
                  style: Theme.of(context).textTheme.bodySmall,
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
                    Icons.badge_outlined,
                    color: GlobalColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 120,
                  child: Text(
                    employee.nip ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GlobalColors.primary,
                    ),
                  ),
                ),
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
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${employee.gender == 'F' ? 'Female' : 'Male'}, ${employee.status ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    employee.deptnm ?? '-',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                _circleButton(
                  icon: Icons.edit_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    editEmployeeView,
                    arguments: employee,
                  ),
                ),
                const SizedBox(width: 10),
                _circleButton(
                  icon: Icons.delete_outline_rounded,
                  onTap: () => _confirmDeleteEmployee(employee),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDeleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text(
          'Yakin ingin menghapus ${employee.name ?? 'karyawan ini'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<EmployeeProvider>().deleteEmployee(employee);
      if (!mounted) return;
      SnackBarUtil.showSuccess(context, 'Data karyawan berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showSnack(context, 'Gagal menghapus data karyawan. $e');
    }
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
}
