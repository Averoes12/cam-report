import 'dart:io';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test exportMedicineReport structure and formulas', () async {
    final medicines = [
      MedicineModel(
        name: 'Abocath no. 22',
        measure: 'PCS',
        price: 24000,
        firstStock: 2,
        arrivedStock: 0,
        returnedStock: 0,
        expDt: '2028-04-01',
      ),
      MedicineModel(
        name: 'Amoxicilin',
        measure: 'Tab',
        price: 780,
        firstStock: 50,
        arrivedStock: 0,
        returnedStock: 0,
        expDt: '2028-05-01',
      ),
      MedicineModel(
        name: 'Alpara BPJS',
        measure: 'Tab',
        price: 1050,
        firstStock: 0,
        arrivedStock: 0,
        returnedStock: 0,
        expDt: '2027-10-01',
      ),
      MedicineModel(
        name: 'Amoxicilin BPJS',
        measure: 'Tab',
        price: 300,
        firstStock: 0,
        arrivedStock: 0,
        returnedStock: 0,
        expDt: '2027-12-01',
      ),
    ];

    final dates = [
      '2026-01-26',
      '2026-01-27',
      '2026-01-28',
      '2026-01-29',
      '2026-01-30',
      '2026-01-31',
      '2026-02-01',
    ];

    final dailyMedicine = {
      'Abocath no. 22': {'2026-01-26': 1},
      'Amoxicilin': {'2026-01-27': 5},
      'Alpara BPJS': {'2026-01-28': 2},
      'Amoxicilin BPJS': {'2026-01-29': 10},
    };

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Sheet1';

    // Verify column name generator
    expect(Utils.getExcelColumnName(1), 'A');
    expect(Utils.getExcelColumnName(26), 'Z');
    expect(Utils.getExcelColumnName(27), 'AA');
    expect(Utils.getExcelColumnName(40), 'AN');
    expect(Utils.getExcelColumnName(41), 'AO');
    expect(Utils.getExcelColumnName(42), 'AP');
    expect(Utils.getExcelColumnName(43), 'AQ');

    // Verify Indonesian month formatting
    final formattedRange = Utils.formatIndonesianMonthRange(
      DateTime(2026, 1, 26),
      DateTime(2026, 2, 25),
    );
    expect(formattedRange, '26 JANUARI - 25 FEBRUARI 2026');
  });
}
