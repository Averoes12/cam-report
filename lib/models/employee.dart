import 'dart:math';
import 'dart:ui';

class EmployeeModel {
  final String? id;
  final String? nip;
  final String? name;
  final String? status;
  final String? deptcode;
  final String? deptnm;
  final String? gender;
  final Color? color;

  EmployeeModel({
    this.id,
    this.nip,
    this.name,
    this.status,
    this.deptcode,
    this.deptnm,
    this.gender,
    this.color,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      nip: json['nip'],
      name: json['name'],
      status: json['status'],
      deptcode: json['deptcode'],
      deptnm: json['deptnm'],
      gender: json['gender'],
      color: _randomColor(json['nip']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nip': nip,
      'name': name,
      'status': status,
      'deptcode': deptcode,
      'deptnm': deptnm,
      'gender': gender,
    };
  }

  static Color _randomColor(String? key) {
    final random = Random(key.hashCode); // generate konsisten
    return Color.fromARGB(
      0xFF,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }
}
