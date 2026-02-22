import 'package:camreport/models/medicine.dart';
import 'package:camreport/services/database_service.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class AddMedicinePage extends StatefulWidget {
  final MedicineModel? medicine;
  const AddMedicinePage({super.key, this.medicine});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController measureController = TextEditingController();
  TextEditingController fsController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController asController = TextEditingController();
  TextEditingController rsController = TextEditingController();
  TextEditingController lsController = TextEditingController();
  TextEditingController expDtController = TextEditingController();
  String gender = '';

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value) {
    setState(() {
      _loading = value;
    });
  }

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  set selectedDate(DateTime value) {
    setState(() {
      _selectedDate = value;
    });
  }

  @override
  void initState() {
    if (widget.medicine != null) {
      initData();
    }
    super.initState();
  }

  void initData() {
    nameController.text = widget.medicine?.name ?? '';
    measureController.text = widget.medicine?.measure ?? '';
    fsController.text = widget.medicine?.firstStock.toString() ?? '';
    priceController.text = widget.medicine?.price.toString() ?? '';
    asController.text = widget.medicine?.arrivedStock.toString() ?? '';
    rsController.text = widget.medicine?.returnedStock.toString() ?? '';
    lsController.text = widget.medicine?.lastStock.toString() ?? '';
    expDtController.text = widget.medicine?.expDt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('Data belum disimpan, yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("Ya"),
                ),
              ],
            );
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text((widget.medicine == null) ? "Tambah Obat" : "Ubah Obat"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nama Obat'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: measureController,
                  decoration: InputDecoration(labelText: 'Satuan'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Satuan Code tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Harga'),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: fsController,
                  decoration: InputDecoration(labelText: 'Stok Awal'),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok Awal tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: asController,
                  decoration: InputDecoration(labelText: 'Obat Datang'),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextFormField(
                  controller: rsController,
                  decoration: InputDecoration(labelText: 'Pengembalian Obat'),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextFormField(
                  controller: lsController,
                  decoration: InputDecoration(labelText: 'Stok Akhir'),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok Akhir tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: expDtController,
                  decoration: InputDecoration(labelText: 'Tanggal Expired'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDatePickerMode: DatePickerMode.day,
                    );
                    if (date != null) {
                      final dt = DateFormat('MMM-dd').format(date);
                      selectedDate = date;
                      expDtController.text = dt;
                    }
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: !loading
                      ? () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              loading = true;
                              DatabaseService db = DatabaseService();
                              MedicineModel medicine = MedicineModel(
                                name: nameController.text,
                                measure: measureController.text,
                                price: int.parse(priceController.text),
                                firstStock: int.parse(fsController.text),
                                arrivedStock: int.parse(asController.text),
                                returnedStock: int.parse(rsController.text),
                                lastStock: int.parse(lsController.text),
                                expDt: expDtController.text,
                              );
                              if (widget.medicine != null) {
                                medicine.id = widget.medicine!.id;
                                await db.editMedicine(medicine);
                                if (!context.mounted) return;
                                SnackBarUtil.showSuccess(
                                  context,
                                  'Berhasil mengubah Obat',
                                );
                              } else {
                                await db.addMedicine(medicine);
                                _loading = false;
                                if (!context.mounted) return;
                                SnackBarUtil.showSuccess(
                                  context,
                                  'Berhasil menambahkan Obat',
                                );
                              }

                              Navigator.pop(context);
                            } catch (e) {
                              _loading = false;
                              debugPrint("ERROR: $e");
                              if (!context.mounted) return;
                              SnackBarUtil.showSnack(context, 'Gagal menambahkan obat');
                            }
                          }
                        }
                      : null,
                  child: Visibility(
                    visible: !loading,
                    replacement: SpinKitChasingDots(
                      color: Colors.blue,
                      size: 12.0,
                    ),
                    child: Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
