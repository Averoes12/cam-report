import 'package:camreport/models/employee.dart';
import 'package:camreport/provider/employee.dart';
import 'package:camreport/services/database_service.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController nipController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dcController = TextEditingController();
  TextEditingController dnController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  String gender = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Scaffold(
        appBar: AppBar(title: const Text("Tambah Karyawan")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<EmployeeProvider>(
            builder: (_, prov, _) {
              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFormField(
                      controller: nipController,
                      decoration: InputDecoration(labelText: 'NIP'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'NIP tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Nama'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: dcController,
                      decoration: InputDecoration(labelText: 'Departemen Code'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Departemen Code tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: dnController,
                      decoration: InputDecoration(labelText: 'Departemen'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Departemen tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: statusController,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        hint: Text('Permanent / Kontrak'),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Status tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Jenis Kelamin'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jenis kelamin tidak boleh kosong';
                        }
                        return null;
                      },
                      items: <String>['Laki-laki', 'Perempuan']
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          if ('Perempuan' == value) {
                            gender = 'F';
                          } else {
                            gender = 'L';
                          }
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: !prov.loading
                          ? () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  prov.loading = true;
                                  EmployeeModel employee = EmployeeModel(
                                    nip: nipController.text,
                                    name: nameController.text,
                                    status: statusController.text,
                                    deptcode: dcController.text,
                                    deptnm: dnController.text,
                                    gender: gender,
                                  );
                                  await context
                                      .read<EmployeeProvider>()
                                      .addEmployee(employee);
                                  prov.loading = false;
                                  if (!context.mounted) return;
                                  SnackBarUtil.showSuccess(
                                    context,
                                    'Berhasil menambahkan data karyawan',
                                  );
                                  Navigator.pop(context);
                                } catch (e) {
                                  prov.loading = false;                                  
                                  if (!context.mounted) return;
                                  SnackBarUtil.showSnack(
                                    context,
                                    'Gagal menambahkan data karyawan. ${e.toString()}',
                                  );
                                }
                              }
                            }
                          : null,
                      child: Visibility(
                        visible: !prov.loading,
                        replacement: SpinKitChasingDots(
                          color: Colors.blue,
                          size: 12.0,
                        ),
                        child: Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
