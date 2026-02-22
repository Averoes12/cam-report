import 'package:camreport/common/employee_item.dart';
import 'package:camreport/models/employee.dart';
import 'package:camreport/models/medicine.dart';

class TransactionVisit implements ListDisplayable{
  final String start, end, diagnose, note, spenTm, remark;
  final EmployeeModel employee;
  final List<MedicineModel> medicines;
  final int grandTotal;

  TransactionVisit({
    required this.start,
    required this.end,
    required this.employee,
    required this.medicines,
    required this.grandTotal,
    required this.spenTm,
    required this.diagnose,
    required this.note,
    required this.remark,
  });

  factory TransactionVisit.fromJson(Map<String, dynamic> json) {
    List<MedicineModel> medicines = (json['medicine'] as List)
        .map((e) => MedicineModel.fromJson(e))
        .toList();
    return TransactionVisit(
      start: json['startDt'],
      end: json['endDt'],
      employee: EmployeeModel.fromJson(json['employee']),
      medicines: medicines,
      grandTotal: json['grandTotal'],
      spenTm: json['spentTm'],
      diagnose: json['diagnose'],
      note: json['note'],
      remark: json['remark'],
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
    };
  }
  
  @override
  String get deptnm => employee.deptnm ?? '';
  
  @override
  String get name => employee.name ?? '';
  
  @override
  String get nip => employee.nip ?? '';
}
