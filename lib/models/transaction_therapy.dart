import 'package:camreport/common/employee_item.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/models/medicine.dart';

class TransactionTherapy implements ListDisplayable {
  final String? id;
  @override
  final String start;
  @override
  final String end;
  final String diagnose, note, spenTm, result, symptoms;
  final EmployeeModel employee;
  final List<MedicineModel> medicines;
  @override
  final int grandTotal;
  final int perclient;

  TransactionTherapy({
    this.id,
    required this.start,
    required this.end,
    required this.employee,
    required this.medicines,
    required this.grandTotal,
    required this.spenTm,
    required this.diagnose,
    required this.note,
    required this.result,
    required this.symptoms,
    required this.perclient,
  });

  factory TransactionTherapy.fromJson(Map<String, dynamic> json, {String? id}) {
    List<MedicineModel> medicines = (json['medicine'] as List)
        .map((e) => MedicineModel.fromJson(e))
        .toList();
    return TransactionTherapy(
      id: id ?? json['id'],
      start: json['startDt'],
      end: json['endDt'],
      employee: EmployeeModel.fromJson(json['employee']),
      medicines: medicines,
      grandTotal: json['grandTotal'],
      spenTm: json['spentTm'],
      diagnose: json['diagnose'],
      note: json['note'],
      result: json['result'],
      symptoms: json['symptoms'],
      perclient: json['perclient'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDt': start,
      'endDt': end,
      'employee': employee.toJson(),
      'medicine': medicines.map((e) => e.toJson()).toList(),
      'grandTotal': grandTotal,
      'spentTm': spenTm,
      'diagnose': diagnose,
      'note': note,
      'result': result,
      'symptoms': symptoms,
      'perclient': perclient,
    };
  }

  TransactionTherapy copyWith({
    String? id,
    String? start,
    String? end,
    EmployeeModel? employee,
    List<MedicineModel>? medicines,
    int? grandTotal,
    String? spenTm,
    String? diagnose,
    String? note,
    String? result,
    String? symptoms,
    int? perclient,
  }) {
    return TransactionTherapy(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      employee: employee ?? this.employee,
      medicines: medicines ?? this.medicines,
      grandTotal: grandTotal ?? this.grandTotal,
      spenTm: spenTm ?? this.spenTm,
      diagnose: diagnose ?? this.diagnose,
      note: note ?? this.note,
      result: result ?? this.result,
      symptoms: symptoms ?? this.symptoms,
      perclient: perclient ?? this.perclient,
    );
  }

  @override
  String get deptnm => employee.deptnm ?? '';

  @override
  String get name => employee.name ?? '';

  @override
  String get nip => employee.nip ?? '';

  @override
  String? get status => employee.status;
}
