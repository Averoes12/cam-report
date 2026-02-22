import 'package:camreport/constant/route.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:camreport/pages/visit/modals/pick_employee.dart';
import 'package:camreport/pages/visit/modals/pick_medicine.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class AddVisitPage extends StatefulWidget {
  const AddVisitPage({super.key});

  @override
  State<AddVisitPage> createState() => _AddVisitPageState();
}

class _AddVisitPageState extends State<AddVisitPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _startDtController = TextEditingController();
  final TextEditingController _startTmController = TextEditingController();
  final TextEditingController _endDtController = TextEditingController();
  final TextEditingController _endTmController = TextEditingController();
  final TextEditingController _diagnosaController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _waktuController = TextEditingController();

  // Data Employee
  String? selectedEmployeeId;
  String? selectedEmployeeName;

  // Data Obat
  List<MedicineModel> selectedMedicines = [];
  EmployeeModel employees = EmployeeModel();
  List<MedicineModel> medicines = [];
  DateTime _startDt = DateTime.now();
  int grandTotal = 0;

  bool _loading = false;
  bool get isLoading => _loading;
  set loading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  @override
  void initState() {
    super.initState();
    // _getData();
  }

  // void _getData() {}

  // void _getEmployee() async {
  //   DatabaseService db = DatabaseService();
  //   Stream<QuerySnapshot> stream = db.getEmployees();
  //   if(stream != null) {
  //     stream.listen((event) {
  //       setState(() {
  //         employees = event.docs.map((e) => EmployeeModel.fromJson(e)).toList();
  //       });
  //     });
  //   }
  // }

  Future<void> _pickStartDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      if (!mounted) return;
      TimeOfDay? time = await showTimePicker(
        initialEntryMode: TimePickerEntryMode.inputOnly,
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        _startDtController.text = DateFormat('dd-MMM-yy').format(dt);
        _startTmController.text = DateFormat('HH:mm').format(dt);

        setState(() {
          _startDt = dt;
        });
      }
    }
  }

  Future<void> _pickEndDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      if (!mounted) return;
      TimeOfDay? time = await showTimePicker(
        initialEntryMode: TimePickerEntryMode.inputOnly,
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (_startDtController.text.isEmpty) {
          if (!mounted) return;
          SnackBarUtil.showSnack(
            context,
            'Pilih tanggal mulai dulu',
          );
          return;
        }
        if (!dt.isAfter(_startDt)) {
          if (!mounted) return;
          SnackBarUtil.showSnack(
            context,
            'Tanggal selesai harus setelah tanggal mulai',
          );
          return;
        }

        _endDtController.text = DateFormat('dd-MMM-yy').format(dt);
        _endTmController.text = DateFormat('HH:mm').format(dt);

        Duration diff = dt.difference(_startDt);
        int minutes = diff.inMinutes % 60;

        _waktuController.text = minutes.toString();
      }
    }
  }

  Future<void> _pickEmployee() async {
    if (!mounted) return;
    final result = await showModalBottomSheet(
      context: context,
      builder: (ctx) => PickEmployee(employee: employees),
    );
    if (result != null) {
      setState(() {
        employees = result;
      });
    }
  }

  void _pickMedicines() async {
    List<MedicineModel>? selected = await showModalBottomSheet(
      context: context,
      builder: (ctx) => PickMedicine(medicines: selectedMedicines),
    );

    for (MedicineModel element in selected ?? []) {
      setState(() {
        grandTotal += element.price ?? 0;
        element.total = 1;
        element.subTotal = element.price;
      });
    }

    if (selected?.isNotEmpty ?? false) {
      setState(() {
        selectedMedicines = selected ?? [];
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (employees.name == null) {
        SnackBarUtil.showSnack(context, 'Pilih karyawan dulu');
        return;
      }
      if (selectedMedicines.isEmpty) {
        SnackBarUtil.showSnack(context, 'Pilih minimal 1 obat');
        return;
      }

      TransactionVisit visit = TransactionVisit(
        start: "${_startDtController.text} ${_startTmController.text}",
        end: "${_endDtController.text} ${_endTmController.text}",
        employee: employees,
        medicines: selectedMedicines,
        grandTotal: grandTotal,
        spenTm: _waktuController.text,
        diagnose: _diagnosaController.text,
        note: "Ambil Obat",
        remark: _remarkController.text,
      );      

      DatabaseService db = DatabaseService();
      showDialog(
        context: context,
        barrierDismissible: false, // biar nggak bisa ditutup klik luar
        builder: (ctx) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 148),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: 100,
              child: const Center(
                child: SpinKitChasingDots(color: Colors.blue),
              ),
            ),
          );
        },
      );

      try {
        await Future.delayed(Duration(seconds: 1));
        await db.insertVisit(visit);
        if (!mounted) return;
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false, // biar nggak bisa ditutup klik luar
          builder: (ctx) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/icon-success.svg', width: 150),
                    Text("Berhasil menambahkan data kunjungan"),
                    SizedBox(height: 24.0),
                    Row(
                      children: [
                        SizedBox(width: 24.0),
                        GestureDetector(
                          child: Text(
                            "Input lagi",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              employees = EmployeeModel();
                              selectedMedicines = [];
                              grandTotal = 0;
                              _startDtController.text = '';
                              _startTmController.text = '';
                              _endDtController.text = '';
                              _endTmController.text = '';
                              _waktuController.text = '';
                              _diagnosaController.text = '';
                              _remarkController.text = '';
                            });
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
                              "Lihat Kunjungan",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName(homeView),
                            );
                            Navigator.pushNamed(context, visitView);
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
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        SnackBarUtil.showSnack(
          context,
          'Gagal menambahkan data kunjungan. ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Input Laporan Kunjungan")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _startDtController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Tanggal mulai"),
                onTap: _pickStartDateTime,
                validator: (v) =>
                    v!.isEmpty ? "Tanggal mulai wajib diisi" : null,
              ),
              TextFormField(
                controller: _startTmController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Jam mulai"),
                onTap: _pickStartDateTime,
                validator: (v) => v!.isEmpty ? "Jam mulai wajib diisi" : null,
              ),
              TextFormField(
                controller: _endDtController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Tanggal selesai"),
                onTap: _pickEndDateTime,
                validator: (v) =>
                    v!.isEmpty ? "Tanggal selesai wajib diisi" : null,
              ),
              TextFormField(
                controller: _endTmController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Jam selesai"),
                onTap: _pickEndDateTime,
                validator: (v) => v!.isEmpty ? "Jam selesai wajib diisi" : null,
              ),
              ListTile(
                title: Text(employees.name ?? "Pilih Karyawan"),
                subtitle: Text(employees.nip ?? ""),
                trailing: Icon(Icons.people),
                onTap: _pickEmployee,
              ),
              Visibility(
                visible: selectedMedicines.isNotEmpty,
                replacement: ListTile(
                  title: Text("Pilih Obat"),
                  trailing: Icon(Icons.medical_services),
                  onTap: _pickMedicines,
                ),
                child: SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectedMedicines.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == selectedMedicines.length) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(height: 16.0),
                            Divider(thickness: 2),
                            Text(
                              "Total Harga Obat: Rp ${Utils.formatNumber(grandTotal)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _pickMedicines(),
                                child: Text("Tambah Obat"),
                              ),
                            ),
                          ],
                        );
                      }
                      MedicineModel e = selectedMedicines[index];
                      return GestureDetector(
                        child: ListTile(
                          title: Text(e.name ?? ""),
                          subtitle: Text(
                            "Grand Total: Rp ${Utils.formatNumber(e.subTotal ?? e.price ?? 0)}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                child: Icon(Icons.remove),
                                onTap: () {
                                  if ((e.total ?? 1) > 1) {
                                    setState(() {
                                      e.total = (e.total ?? 1) - 1;
                                      e.subTotal =
                                          (e.price ?? 0) * (e.total ?? 1);
                                      _recalculateGrandTotal();
                                    });
                                  } else {
                                    setState(() {
                                      selectedMedicines.removeWhere((element) {
                                        return element.name == e.name;
                                      });
                                      _recalculateGrandTotal();
                                    });
                                  }
                                },
                              ),
                              SizedBox(width: 8.0),
                              SizedBox(
                                width: 50,
                                child: TextFormField(
                                  textAlign: TextAlign.center,
                                  initialValue: "${e.total ?? 1}",
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    int qty = int.tryParse(value) ?? 1;
                                    setState(() {
                                      if (qty <= 0 ||
                                          qty > (e.lastStock ?? 0)) {
                                        qty = 1;
                                        e.total = 1;
                                        e.subTotal = (e.price ?? 0) * 1;
                                      } else {
                                        e.total = qty;
                                        e.subTotal = (e.price ?? 0) * qty;
                                      }
                                      _recalculateGrandTotal();
                                    });
                                  },
                                ),
                              ),

                              SizedBox(width: 8.0),
                              GestureDetector(
                                child: Icon(Icons.add),
                                onTap: () {
                                  if ((e.total ?? 1) < (e.lastStock ?? 0)) {
                                    setState(() {
                                      e.total = (e.total ?? 1) + 1;
                                      e.subTotal =
                                          (e.price ?? 0) * (e.total ?? 1);
                                      _recalculateGrandTotal();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              TextFormField(
                controller: _diagnosaController,
                decoration: InputDecoration(labelText: "Diagnosa"),
              ),
              TextFormField(
                controller: _remarkController,
                decoration: InputDecoration(labelText: "Keterangan"),
              ),
              TextFormField(
                controller: _waktuController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(labelText: "Waktu (menit)"),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: Text("Simpan")),
            ],
          ),
        ),
      ),
    );
  }

  void _recalculateGrandTotal() {
    grandTotal = selectedMedicines.fold(
      0,
      (sum, item) =>
          sum + (item.subTotal ?? (item.price ?? 0) * (item.total ?? 1)),
    );
  }
}
