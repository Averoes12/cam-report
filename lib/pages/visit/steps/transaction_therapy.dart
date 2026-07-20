import 'package:camreport/models/employee.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/models/transaction_therapy.dart';
import 'package:camreport/pages/visit/modals/pick_employee.dart';
import 'package:camreport/pages/visit/modals/pick_medicine.dart';
import 'package:camreport/services/database_service.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flareline_uikit/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:camreport/pages/visit/modals/ocr_bottom_sheet.dart';

class AddTherapyPage extends StatefulWidget {
  final TransactionTherapy? therapy;
  const AddTherapyPage({super.key, this.therapy});

  @override
  State<AddTherapyPage> createState() => _AddTherapyPageState();
}

class _AddTherapyPageState extends State<AddTherapyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDtController = TextEditingController();
  final TextEditingController _startTmController = TextEditingController();
  final TextEditingController _endDtController = TextEditingController();
  final TextEditingController _endTmController = TextEditingController();
  final TextEditingController _diagnosaController = TextEditingController();
  final TextEditingController _keluhanController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  final TextEditingController _waktuController = TextEditingController();

  EmployeeModel employee = EmployeeModel();
  List<MedicineModel> selectedMedicines = [];
  TransactionTherapy? originalTherapy;
  DateTime _startDt = DateTime.now();
  bool loading = false;
  int grandTotal = 0;

  bool get isEdit => widget.therapy != null;

  @override
  void initState() {
    super.initState();
    if (widget.therapy != null) {
      _populateTherapy(widget.therapy!);
    }
  }

  @override
  void dispose() {
    _startDtController.dispose();
    _startTmController.dispose();
    _endDtController.dispose();
    _endTmController.dispose();
    _diagnosaController.dispose();
    _keluhanController.dispose();
    _resultController.dispose();
    _waktuController.dispose();
    super.dispose();
  }

  void _populateTherapy(TransactionTherapy therapy) {
    _startDt = DateFormat('dd-MMM-yy HH:mm').parse(therapy.start);
    employee = therapy.employee;
    originalTherapy = therapy.copyWith(
      medicines: _cloneMedicines(therapy.medicines),
    );
    selectedMedicines = _cloneMedicines(therapy.medicines);
    _startDtController.text = therapy.start.split(' ').first;
    _startTmController.text = therapy.start.split(' ').last;
    _endDtController.text = therapy.end.split(' ').first;
    _endTmController.text = therapy.end.split(' ').last;
    _diagnosaController.text = therapy.diagnose;
    _keluhanController.text = therapy.symptoms;
    _resultController.text = therapy.result;
    _waktuController.text = therapy.spenTm;
    _recalculateGrandTotal();
  }

  List<MedicineModel> _cloneMedicines(List<MedicineModel> medicines) {
    return medicines
        .map(
          (medicine) => medicine.copyWith(
            total: medicine.total ?? 1,
            subTotal:
                medicine.subTotal ??
                (medicine.price ?? 0) * (medicine.total ?? 1),
          ),
        )
        .toList();
  }

  String _medicineKey(MedicineModel medicine) =>
      medicine.id ?? medicine.name ?? '';

  Future<void> _pickStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _startDt,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.inputOnly,
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDt),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _startDt = dt;
      _startDtController.text = DateFormat('dd-MMM-yy').format(dt);
      _startTmController.text = DateFormat('HH:mm').format(dt);
      if (_endDtController.text.isNotEmpty &&
          _endTmController.text.isNotEmpty) {
        final end = DateFormat(
          'dd-MMM-yy HH:mm',
        ).parse('${_endDtController.text} ${_endTmController.text}');
        _waktuController.text = end.difference(dt).inMinutes.toString();
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _startDt,
    );
    if (date == null || !mounted) return;

    final initialTimeDt = _startDt.add(const Duration(minutes: 1));
    final time = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.inputOnly,
      context: context,
      initialTime: TimeOfDay(
        hour: initialTimeDt.hour,
        minute: initialTimeDt.minute,
      ),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!mounted) return;
    if (_startDtController.text.isEmpty) {
      SnackBarUtil.showSnack(context, 'Pilih tanggal mulai terlebih dulu');
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

    setState(() {
      _endDtController.text = DateFormat('dd-MMM-yy').format(dt);
      _endTmController.text = DateFormat('HH:mm').format(dt);
      _waktuController.text = dt.difference(_startDt).inMinutes.toString();
    });
  }

  Future<void> _pickEmployee() async {
    final result = await showModalBottomSheet<EmployeeModel>(
      context: context,
      builder: (ctx) => PickEmployee(employee: employee),
    );
    if (result == null) return;

    setState(() {
      employee = result;
    });
  }

  Future<void> _pickMedicines() async {
    final selected = await showModalBottomSheet<List<MedicineModel>>(
      context: context,
      builder: (ctx) => PickMedicine(medicines: selectedMedicines),
    );
    if (selected == null) return;

    final existing = {
      for (final item in selectedMedicines) _medicineKey(item): item,
    };
    setState(() {
      selectedMedicines = selected.map((medicine) {
        final previous = existing[_medicineKey(medicine)];
        final qty = previous?.total ?? 1;
        return medicine.copyWith(
          total: qty,
          subTotal: (medicine.price ?? 0) * qty,
        );
      }).toList();
      _recalculateGrandTotal();
    });
  }

  void _changeMedicineQty(MedicineModel medicine, int nextQty) {
    if (nextQty <= 0) {
      setState(() {
        selectedMedicines.removeWhere(
          (item) => _medicineKey(item) == _medicineKey(medicine),
        );
        _recalculateGrandTotal();
      });
      return;
    }

    final maxStock = medicine.lastStock ?? nextQty;
    final safeQty = nextQty > maxStock && maxStock > 0 ? maxStock : nextQty;
    setState(() {
      final index = selectedMedicines.indexWhere(
        (item) => _medicineKey(item) == _medicineKey(medicine),
      );
      if (index == -1) return;
      selectedMedicines[index] = selectedMedicines[index].copyWith(
        total: safeQty,
        subTotal: (selectedMedicines[index].price ?? 0) * safeQty,
      );
      _recalculateGrandTotal();
    });
  }

  void _recalculateGrandTotal() {
    grandTotal = selectedMedicines.fold(
      0,
      (sum, item) =>
          sum + (item.subTotal ?? (item.price ?? 0) * (item.total ?? 1)),
    );
  }

  Future<void> _scanEmployeeAndMedicine() async {
    final result = await showModalBottomSheet<OCRResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OCRBottomSheet(
        promptContext:
            "Extract handwriting text from this image. Return ONLY a valid JSON object with: 'employee_identifier' (string, can be name OR NIP/ID of person) and 'medicines' (list of strings, medicine names). No markdown, no prefixes.",
      ),
    );
    if (result != null && result.text.isNotEmpty) {
      _processOcrJson(result.text);
    }
  }

  void _processOcrJson(String jsonString) {
    try {
      String cleanJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      final employeeIdentifier = data['employee_identifier'] as String?;
      final medicinesList = (data['medicines'] as List?)?.cast<String>();

      if (employeeIdentifier != null && employeeIdentifier.isNotEmpty) {
        _searchAndSetEmployee(employeeIdentifier);
      }

      if (medicinesList != null && medicinesList.isNotEmpty) {
        _searchAndAddMedicines(medicinesList);
      }
    } catch (e) {
      SnackBarUtil.showSnack(context, 'Gagal memproses hasil AI: $e');
    }
  }

  Future<void> _searchAndSetEmployee(String identifier) async {
    final db = DatabaseService();
    final snapshot = await db.getEmployees().first;
    final allEmployees = snapshot.docs
        .map((e) => e.data() as EmployeeModel)
        .toList();

    final search = identifier.toLowerCase();
    EmployeeModel? bestMatch;

    for (var emp in allEmployees) {
      final name = (emp.name ?? '').toLowerCase();
      final nip = (emp.nip ?? '').toLowerCase();
      if (name.contains(search) || nip.contains(search)) {
        bestMatch = emp;
        break;
      }
    }

    if (bestMatch != null) {
      setState(() {
        employee = bestMatch!;
      });
      SnackBarUtil.showSuccess(
        context,
        'Karyawan ditemukan: ${bestMatch.name} (${bestMatch.nip})',
      );
    } else {
      SnackBarUtil.showSnack(
        context,
        'Karyawan tidak ditemukan untuk: $identifier',
      );
    }
  }

  Future<void> _searchAndAddMedicines(List<String> medicineNames) async {
    final db = DatabaseService();
    final snapshot = await db.getMedicines().first;
    final allMedicines = snapshot.docs
        .map((e) => e.data() as MedicineModel)
        .toList();

    List<MedicineModel> foundMedicines = [];

    for (var medName in medicineNames) {
      final search = medName.toLowerCase();
      for (var med in allMedicines) {
        if ((med.name ?? '').toLowerCase().contains(search)) {
          foundMedicines.add(med);
          break; // Stop after first match for this name
        }
      }
    }

    if (foundMedicines.isNotEmpty) {
      setState(() {
        final existing = {
          for (final item in selectedMedicines) _medicineKey(item): item,
        };

        for (var med in foundMedicines) {
          final previous = existing[_medicineKey(med)];
          final qty = (previous?.total ?? 0) + 1;
          existing[_medicineKey(med)] = med.copyWith(
            total: qty,
            subTotal: (med.price ?? 0) * qty,
          );
        }
        selectedMedicines = existing.values.toList();
        _recalculateGrandTotal();
      });
      SnackBarUtil.showSuccess(
        context,
        'Berhasil menambahkan ${foundMedicines.length} obat dari OCR',
      );
    } else {
      SnackBarUtil.showSnack(
        context,
        'Tidak ada obat yang cocok dengan hasil OCR',
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (employee.name == null) {
      SnackBarUtil.showSnack(context, 'Pilih karyawan dulu');
      return;
    }
    if (selectedMedicines.isEmpty) {
      SnackBarUtil.showSnack(context, 'Pilih minimal 1 obat');
      return;
    }

    final therapy = TransactionTherapy(
      id: widget.therapy?.id,
      start: '${_startDtController.text} ${_startTmController.text}',
      end: '${_endDtController.text} ${_endTmController.text}',
      employee: employee,
      medicines: _cloneMedicines(selectedMedicines),
      grandTotal: grandTotal,
      spenTm: _waktuController.text,
      diagnose: _diagnosaController.text,
      symptoms: _keluhanController.text,
      result: _resultController.text,
      note: 'Berobat',
      perclient: grandTotal,
    );

    setState(() {
      loading = true;
    });

    try {
      final db = DatabaseService();
      if (isEdit && originalTherapy != null) {
        await db.updateTherapy(previous: originalTherapy!, next: therapy);
      } else {
        await db.insertTherapy(therapy);
      }
      if (!mounted) return;
      SnackBarUtil.showSuccess(
        context,
        isEdit
            ? 'Berhasil mengubah data pengobatan'
            : 'Berhasil menambahkan data pengobatan',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtil.showSnack(
        context,
        '${isEdit ? 'Gagal mengubah' : 'Gagal menambahkan'} data pengobatan. $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget _section({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Ubah Laporan Pengobatan' : 'Input Laporan Pengobatan',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scan Karyawan & Obat via OCR',
            onPressed: _scanEmployeeAndMedicine,
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _section(
                child: Column(
                  spacing: 16,
                  children: [
                    TextFormField(
                      controller: _startDtController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal mulai',
                      ),
                      onTap: _pickStartDateTime,
                      validator: (v) =>
                          v!.isEmpty ? 'Tanggal mulai wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _startTmController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Jam mulai'),
                      onTap: _pickStartDateTime,
                      validator: (v) =>
                          v!.isEmpty ? 'Jam mulai wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _endDtController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal selesai',
                      ),
                      onTap: _pickEndDateTime,
                      validator: (v) =>
                          v!.isEmpty ? 'Tanggal selesai wajib diisi' : null,
                    ),
                    TextFormField(
                      controller: _endTmController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Jam selesai',
                      ),
                      onTap: _pickEndDateTime,
                      validator: (v) =>
                          v!.isEmpty ? 'Jam selesai wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              _section(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(employee.name ?? 'Pilih Karyawan'),
                  subtitle: Text(employee.nip ?? 'Belum ada karyawan dipilih'),
                  trailing: const Icon(Icons.people_alt_outlined),
                  onTap: _pickEmployee,
                ),
              ),
              _section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Obat Dipilih',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickMedicines,
                          icon: const Icon(Icons.add),
                          label: Text(
                            selectedMedicines.isEmpty
                                ? 'Pilih Obat'
                                : 'Ubah Obat',
                          ),
                        ),
                      ],
                    ),
                    if (selectedMedicines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('Belum ada obat yang dipilih'),
                      )
                    else
                      ...selectedMedicines.map(
                        (medicine) => Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(top: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            title: Text(medicine.name ?? ''),
                            subtitle: Text(
                              'Subtotal: Rp ${Utils.formatNumber(medicine.subTotal ?? 0)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _changeMedicineQty(
                                    medicine,
                                    (medicine.total ?? 1) - 1,
                                  ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    key: ValueKey(
                                      '${_medicineKey(medicine)}_${medicine.total}',
                                    ),
                                    initialValue: '${medicine.total ?? 1}',
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _changeMedicineQty(
                                        medicine,
                                        int.tryParse(value) ?? 1,
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _changeMedicineQty(
                                    medicine,
                                    (medicine.total ?? 1) + 1,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (selectedMedicines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total Harga Obat: Rp ${Utils.formatNumber(grandTotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _section(
                child: Column(
                  spacing: 16,
                  children: [
                    TextFormField(
                      controller: _keluhanController,
                      decoration: const InputDecoration(labelText: 'Keluhan'),
                    ),
                    TextFormField(
                      controller: _resultController,
                      decoration: const InputDecoration(
                        labelText: 'Hasil Pemeriksaan',
                      ),
                    ),
                    TextFormField(
                      controller: _diagnosaController,
                      decoration: const InputDecoration(labelText: 'Diagnosa'),
                    ),
                    TextFormField(
                      controller: _waktuController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu (menit)',
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: loading ? null : _submitForm,
                child: Text(
                  loading ? 'Menyimpan...' : (isEdit ? 'Update' : 'Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
