import 'package:camreport/common/employee_item.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/models/medicine.dart';

class TransactionVisit implements ListDisplayable {
  final String? id;
  @override
  final String start;
  @override
  final String end;
  final String diagnose, note, spenTm, remark;
  final String category;
  final EmployeeModel employee;
  final List<MedicineModel> medicines;
  final int grandTotal;

  TransactionVisit({
    this.id,
    required this.start,
    required this.end,
    required this.employee,
    required this.medicines,
    required this.grandTotal,
    required this.spenTm,
    required this.diagnose,
    required this.note,
    required this.remark,
    this.category = 'visit',
  });

  factory TransactionVisit.fromJson(Map<String, dynamic> json, {String? id}) {
    List<MedicineModel> medicines = (json['medicine'] as List)
        .map((e) => MedicineModel.fromJson(e))
        .toList();
    return TransactionVisit(
      id: id ?? json['id'],
      start: json['startDt'],
      end: json['endDt'],
      employee: EmployeeModel.fromJson(json['employee']),
      medicines: medicines,
      grandTotal: json['grandTotal'],
      spenTm: json['spentTm'],
      diagnose: json['diagnose'],
      note: json['note'],
      remark: json['remark'],
      category:
          json['category'] ??
          ((json['note'] == 'Berobat') ? 'therapy' : 'visit'),
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
      'remark': remark,
      'category': category,
    };
  }

  TransactionVisit copyWith({
    String? id,
    String? start,
    String? end,
    EmployeeModel? employee,
    List<MedicineModel>? medicines,
    int? grandTotal,
    String? spenTm,
    String? diagnose,
    String? note,
    String? remark,
    String? category,
  }) {
    return TransactionVisit(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      employee: employee ?? this.employee,
      medicines: medicines ?? this.medicines,
      grandTotal: grandTotal ?? this.grandTotal,
      spenTm: spenTm ?? this.spenTm,
      diagnose: diagnose ?? this.diagnose,
      note: note ?? this.note,
      remark: remark ?? this.remark,
      category: category ?? this.category,
    );
  }

  @override
  String get deptnm => employee.deptnm ?? '';

  @override
  String get name => employee.name ?? '';

  @override
  String get nip => employee.nip ?? '';
}
