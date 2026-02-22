import 'package:camreport/models/medicine.dart';
import 'package:camreport/models/transaction_therapy.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:camreport/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:file_saver/file_saver.dart';

import 'platform_stub.dart'
    if (dart.library.io) 'platform_io.dart'
    if (dart.library.html) 'platform_web.dart';

import 'dart:io' show Directory, File; // hanya akan kepakai kalau bukan web

class Utils {
  static String formatNumber(int number) {
    print("Formatting number: $number");
    final formatter = NumberFormat.decimalPattern('id'); // locale Indonesia
    return formatter.format(number);
  }

  static Future<void> exportVisits(List<TransactionVisit> visits) async {
    try {
      // Buat workbook & ambil sheet pertama
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'LAPORAN KUNJUNGAN';

      // Header
      final headers = [
        "NO",
        "TANGGAL",
        "JAM KUNJUNGAN",
        "ID",
        "KUALIFIKASI",
        "CODE",
        "NAMA",
        "DEPARTEMEN",
        "JENIS OBAT",
        "JUMLAH",
        "HARGA",
        "TOTAL HARGA",
        "GRAND TOTAL",
        "KETERANGAN",
        "DIAGNOSA",
        "KETERANGAN",
        "WAKTU",
      ];

      // Tulis header di baris pertama
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle.bold = true;
        cell.cellStyle.fontName = 'Times New Roman';
        cell.cellStyle.hAlign = xlsio.HAlignType.center;
        cell.cellStyle.borders.all.color = '#000000';
      }

      // Isi data mulai dari baris ke-2
      visits = visits.reversed.toList();
      int rowIndex = 2;
      for (int i = 0; i < visits.length; i++) {
        final startRow = rowIndex;
        final visit = visits[i];
        for (int j = 0; j < visit.medicines.length; j++) {
          final obat = visit.medicines[j];
          final sDt = visit.start.split(" ");
          final eDt = visit.end.split(" ");

          final row = [
            j == 0 ? "${i + 1}" : "", // NO
            j == 0 ? eDt[0].trim() : "", // TANGGAL
            j == 0 ? "${sDt[1]}-${eDt[1]}" : "", // JAM KUNJUNGAN
            j == 0 ? (visit.employee.nip ?? "") : "", // ID
            j == 0 ? (visit.employee.status ?? "") : "", // KUALIFIKASI
            j == 0 ? (visit.employee.deptcode ?? "") : "", // CODE
            j == 0 ? (visit.employee.name ?? "") : "", // NAMA
            j == 0 ? (visit.employee.deptnm ?? "") : "", // DEPARTEMEN
            obat.name ?? "-", // JENIS OBAT
            obat.total ?? 0, // JUMLAH
            obat.price ?? 0, // HARGA
            obat.subTotal ?? 0, // TOTAL HARGA
            j == 0 ? visit.grandTotal : "", // GRAND TOTAL
            j == 0 ? visit.note : "", // KETERANGAN
            j == 0 ? visit.diagnose : "", // DIAGNOSA
            j == 0 ? visit.remark : "", // KETERANGAN (2)
            j == 0 ? visit.spenTm : "", // WAKTU
          ];

          for (int col = 0; col < row.length; col++) {
            final cell = sheet.getRangeByIndex(rowIndex, col + 1);

            if (col == 0 || col == 9 || col == 16) {
              if (row[col] is String) {
                cell.setNumber(double.tryParse((row[col] as String)));
              }
              if (row[col] is int) {
                cell.setNumber((row[col] as num).toDouble());
              }
            } else if (col == 1) {
              if (row[col] != "") {
                cell.dateTime = DateFormat(
                  'dd-MMM-yy',
                  'en_US',
                ).parse(row[col].toString().trim());
                cell.numberFormat = 'dd-MMM-yy';
              }
            } else if (col == 10 || col == 11 || col == 12) {
              // kalau nilainya numeric
              if (row[col] is int || row[col] is double) {
                cell.setNumber((row[col] as num).toDouble());
                cell.numberFormat = '#,##0'; // Format ribuan tanpa desimal
                if (col == 11 || col == 12) {
                  cell.cellStyle.backColor = j == 0 ? '#D99594' : '#FFFFFF';
                }
              } else {
                cell.setText(row[col].toString());
              }
            } else {
              cell.setText(row[col].toString());
            }

            final jumlahCell = sheet.getRangeByIndex(rowIndex, 10); // kolom J
            final hargaCell = sheet.getRangeByIndex(rowIndex, 11); // kolom K
            final totalPriceCell = sheet.getRangeByIndex(rowIndex, 12);
            totalPriceCell.formula =
                'SUM(${jumlahCell.addressLocal}*${hargaCell.addressLocal})';
            // Style isi
            cell.cellStyle.fontName = 'Times New Roman';
            cell.cellStyle.fontSize = 12;
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
            cell.cellStyle.vAlign = xlsio.VAlignType.center;
            cell.cellStyle.borders.all.color = "#000000";
            cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          }
          rowIndex++;
        }
        final endRow = rowIndex - 1;

        final grandTotalCell = sheet.getRangeByIndex(
          startRow,
          13,
        ); // kolom M (13)
        grandTotalCell.formula = 'SUM(L$startRow:L$endRow)';
        if (i < visits.length - 1) {
          sheet.insertRow(rowIndex, 1);
          final emptyRowRange = sheet.getRangeByIndex(
            rowIndex,
            1,
            rowIndex,
            headers.length,
          );
          emptyRowRange.cellStyle.borders.all.color = "#000000";
          emptyRowRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          rowIndex++; // pindah ke baris berikutnya
        }
      }

      // AutoFit kolom
      // sheet.autoFitColumn(1, headers.length);

      final dailySheet = workbook.worksheets.addWithName("UPDATE OBAT");
      final Map<String, Map<String, int>> dailyMedicine = {};
      final DatabaseService db = DatabaseService();
      final snapshotMedicine = await db.getMedicines().first;
      List<MedicineModel> obats =
          snapshotMedicine.docs.map((v) => v.data() as MedicineModel).toList()
            ..sort((a, b) => a.name?.compareTo(b.name ?? '') ?? 0);
      for (final item in obats) {
        dailyMedicine.putIfAbsent(item.name ?? "-", () => {});
        for (final visit in visits) {
          final date = visit.end.split(" ")[0]; // ambil tanggal saja
          for (final obat in visit.medicines) {
            final obatName = obat.name ?? "-";
            final qty = obat.total ?? 0;

            if (item.name == obatName) {
              dailyMedicine[obatName]?[date] =
                  (dailyMedicine[obatName]?[date] ?? 0) + qty;
            }
          }
        }
      }

      final allDates =
          dailyMedicine.values.expand((map) => map.keys).toSet().toList()
            ..sort((a, b) => b.compareTo(a));

      // Tulis header
      dailySheet.getRangeByIndex(1, 1).setText("NAMA OBAT");
      for (int i = 0; i < allDates.length; i++) {
        dailySheet.getRangeByIndex(1, i + 2).setText(allDates[i]);
      }

      // Tulis isi
      int medicRow = 2;
      for (final entry in dailyMedicine.entries) {
        final obatName = entry.key;
        final dateMap = entry.value;

        dailySheet.getRangeByIndex(medicRow, 1).setText(obatName);

        for (int i = 0; i < allDates.length; i++) {
          final date = allDates[i];
          final qty = dateMap[date] ?? 0;
          if (qty > 0) {
            dailySheet
                .getRangeByIndex(medicRow, i + 2)
                .setNumber(qty.toDouble());
          }
        }

        medicRow++;
      }

      // Simpan workbook ke bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (isWeb) {
        // WEB → pakai FileSaver
        final Uint8List uint8list = Uint8List.fromList(bytes);
        await FileSaver.instance.saveFile(
          name: "laporan_kunjungan",
          bytes: uint8list,
          fileExtension: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        // ANDROID/IOS/DESKTOP → pakai dart:io
        Directory? dir = await getExternalStorageDirectory();
        String newPath = "";
        List<String> folders = dir!.path.split("/");
        for (int i = 1; i < folders.length; i++) {
          if (folders[i] == "Android") break;
          newPath += "/${folders[i]}";
        }
        String downloadPath = "$newPath/Download";
        await Directory(downloadPath).create(recursive: true);

        String filePath = "$downloadPath/laporan_kunjungan.xlsx";
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        print("✅ File berhasil disimpan di: $filePath");
      }
    } catch (e) {
      print("❌ ERROR $e");
    }
  }

  static Future<void> exportTherapy(List<TransactionTherapy> therapy) async {
    try {
      // Buat workbook & ambil sheet pertama
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // Header
      final headers = [
        "NO",
        "TANGGAL",
        "NAMA KARYAWAN",
        "JENIS KELAMIN",
        "ID",
        "KUALIFIKASI",
        "CODE",
        "DEPARTEMEN",
        "WAKTU BEROBAT",
        "LAMA BEROBAT",
        "KELUHAN",
        "HASIL PEMERIKSAAN",
        "KETERANGAN",
        "DIANGOSA",
        "THERAPY",
        "JUMLAH",
        "BIAYA",
        "TOTAL",
        "BIAYA PERKLIEN",
      ];

      // Tulis header di baris pertama
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle.bold = true;
        cell.cellStyle.fontName = 'Times New Roman';
        cell.cellStyle.hAlign = xlsio.HAlignType.center;
        cell.cellStyle.borders.all.color = '#000000';
      }

      // Isi data mulai dari baris ke-2
      therapy = therapy.reversed.toList();
      int rowIndex = 2;
      for (int i = 0; i < therapy.length; i++) {
        final startRow = rowIndex;
        final visit = therapy[i];
        for (int j = 0; j < visit.medicines.length; j++) {
          final obat = visit.medicines[j];
          final sDt = visit.start.split(" ");
          final eDt = visit.end.split(" ");

          final row = [
            j == 0 ? "${i + 1}" : "", // NO
            j == 0 ? eDt[0].trim() : "", // TANGGAL
            j == 0 ? (visit.employee.name ?? "") : "", // ID
            j == 0 ? (visit.employee.gender ?? "") : "", // KUALIFIKASI
            j == 0 ? (visit.employee.nip ?? "") : "", // CODE
            j == 0 ? (visit.employee.status ?? "") : "", // NAMA
            j == 0 ? (visit.employee.deptcode ?? "") : "", // DEPARTEMEN
            j == 0 ? (visit.employee.deptnm ?? "") : "", // DEPARTEMEN
            j == 0 ? "${sDt[1]}-${eDt[1]}" : "", // JAM KUNJUNGAN
            j == 0 ? visit.spenTm : "", // WAKTU
            j == 0 ? visit.symptoms : "",
            j == 0 ? visit.result : "",
            j == 0 ? visit.note : "", // KETERANGAN
            j == 0 ? visit.diagnose : "", // DIAGNOSA
            obat.name ?? "-", // JENIS OBAT
            obat.total ?? 0, // JUMLAH
            obat.price ?? 0, // HARGA
            obat.subTotal ?? 0, // TOTAL HARGA
            j == 0 ? visit.perclient : "", // GRAND TOTAL
          ];

          for (int col = 0; col < row.length; col++) {
            final cell = sheet.getRangeByIndex(rowIndex, col + 1);

            if (col == 0 || col == 9 || col == 15) {
              if (row[col] is String) {
                cell.setNumber(double.tryParse((row[col] as String)));
              }
              if (row[col] is int) {
                cell.setNumber((row[col] as num).toDouble());
              }
            } else if (col == 1) {
              if (row[col] != "") {
                cell.dateTime = DateFormat(
                  'dd-MMM-yy',
                  'en_US',
                ).parse(row[col].toString().trim());
                cell.numberFormat = 'dd-MMM-yy';
              }
            } else if (col == 16 || col == 17 || col == 18) {
              // kalau nilainya numeric
              if (row[col] is int || row[col] is double) {
                cell.setNumber((row[col] as num).toDouble());
                cell.numberFormat = '#,##0'; // Format ribuan tanpa desimal
                if (col == 17 || col == 18) {
                  cell.cellStyle.backColor = j == 0 ? '#D99594' : '#FFFFFF';
                }
              } else {
                cell.setText(row[col].toString());
              }
            } else {
              cell.setText(row[col].toString());
            }

            final jumlahCell = sheet.getRangeByIndex(rowIndex, 16); // kolom J
            final hargaCell = sheet.getRangeByIndex(rowIndex, 17); // kolom K
            final totalPriceCell = sheet.getRangeByIndex(rowIndex, 18);
            totalPriceCell.formula =
                'SUM(${jumlahCell.addressLocal}*${hargaCell.addressLocal})';

            // Style isi
            cell.cellStyle.fontName = 'Times New Roman';
            cell.cellStyle.fontSize = 12;
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
            cell.cellStyle.vAlign = xlsio.VAlignType.center;
            cell.cellStyle.borders.all.color = "#000000";
            cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          }
          rowIndex++;
        }
        final endRow = rowIndex - 1;
        final grandTotalCell = sheet.getRangeByIndex(
          startRow,
          19,
        ); // kolom M (13)
        grandTotalCell.formula = 'SUM(R$startRow:R$endRow)';
        if (i < therapy.length - 1) {
          sheet.insertRow(rowIndex, 1);
          final emptyRowRange = sheet.getRangeByIndex(
            rowIndex,
            1,
            rowIndex,
            headers.length,
          );
          emptyRowRange.cellStyle.borders.all.color = "#000000";
          emptyRowRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          rowIndex++; // pindah ke baris berikutnya
        }
      }

      // AutoFit kolom
      // sheet.autoFitColumn(1, headers.length);

      // Simpan workbook ke bytes
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      if (isWeb) {
        // WEB → pakai FileSaver
        final Uint8List uint8list = Uint8List.fromList(bytes);
        await FileSaver.instance.saveFile(
          name: "laporan_pengobatan",
          bytes: uint8list,
          fileExtension: "xlsx",
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        // ANDROID/IOS/DESKTOP → pakai dart:io
        Directory? dir = await getExternalStorageDirectory();
        String newPath = "";
        List<String> folders = dir!.path.split("/");
        for (int i = 1; i < folders.length; i++) {
          if (folders[i] == "Android") break;
          newPath += "/${folders[i]}";
        }
        String downloadPath = "$newPath/Download";
        await Directory(downloadPath).create(recursive: true);

        String filePath = "$downloadPath/laporan_pengobatan.xlsx";
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        print("✅ File berhasil disimpan di: $filePath");
      }
    } catch (e) {
      print("❌ ERROR $e");
    }
  }

   String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '';

    final words = name.trim().split(RegExp(r'\s+'));

    // Fungsi untuk cek apakah kata diawali huruf
    bool startsWithLetter(String word) {
      return RegExp(r'^[a-zA-Z]').hasMatch(word);
    }

    String firstInitial = '';

    // Ambil kata pertama yang valid (diawali huruf)
    for (var word in words) {
      if (startsWithLetter(word)) {
        firstInitial = word[0].toUpperCase();
        break;
      }
    }

    if (firstInitial.isEmpty) return '';

    // Cari kata kedua yang valid (setelah kata pertama)
    bool foundFirst = false;
    for (var word in words) {
      if (!startsWithLetter(word)) continue;

      if (!foundFirst) {
        foundFirst = true;
        continue;
      }

      // Ini kata kedua valid
      return firstInitial + word[0].toUpperCase();
    }

    return firstInitial;
  }
}
