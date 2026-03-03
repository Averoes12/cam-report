import 'dart:developer';

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
      log("❌ ERROR $e");
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

  static Future<void> exportInvoice({
    required List<TransactionVisit> allData,
    required DateTime startPeriod,
    required DateTime endPeriod,
  }) async {
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];

      // =====================================================
      // FILTER PERIODE
      // =====================================================
      final filtered = allData.where((visit) {
        final date = DateFormat("dd-MMM-yy HH:mm").parse(visit.end);

        return !date.isBefore(startPeriod) && !date.isAfter(endPeriod);
      }).toList();

      // =====================================================
      // GROUPING SESUAI RULE
      // =====================================================
      final Map<String, List<TransactionVisit>> grouped = {};

      for (final visit in filtered) {
        final status = (visit.employee.status ?? "").toUpperCase();

        if (status == "KONTRAK") {
          String type = "AMBIL OBAT";

          if ((visit.note).toLowerCase().contains("berobat")) {
            type = "PENGOBATAN";
          }

          grouped.putIfAbsent("KONTRAK $type", () => []);
          grouped["KONTRAK $type"]!.add(visit);
        } else {
          grouped.putIfAbsent(status, () => []);
          grouped[status]!.add(visit);
        }
      }

      // =====================================================
      // JUDUL
      // =====================================================
      final title = sheet.getRangeByIndex(1, 1, 1, 10);
      title.merge();
      title.setText(
        "Rekapitulasi Pelayanan Inhouse Clinic PT. Mitsubishi Electric Automotive Indonesia",
      );
      title.cellStyle.bold = true;
      title.cellStyle.hAlign = xlsio.HAlignType.center;

      final periode = sheet.getRangeByIndex(2, 1, 2, 10);
      periode.merge();
      periode.setText(
        "Periode ${DateFormat('dd MMMM yyyy').format(startPeriod).toUpperCase()} - ${DateFormat('dd MMMM yyyy').format(endPeriod).toUpperCase()}",
      );
      periode.cellStyle.hAlign = xlsio.HAlignType.center;

      int rowIndex = 4;

      // =====================================================
      // HEADER
      // =====================================================
      final headers = [
        "No",
        "Tanggal",
        "NIK",
        "Permanent/Contract",
        "Code",
        "Nama",
        "Departement",
        "Total",
        "Keterangan",
        "Diagnosa",
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(rowIndex, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle.bold = true;
        cell.cellStyle.backColor = "#C4D79B";
        cell.cellStyle.hAlign = xlsio.HAlignType.center;
        cell.cellStyle.vAlign = xlsio.VAlignType.center;
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      }

      rowIndex++;

      double grandTotal = 0;

      // =====================================================
      // DATA + SUBTOTAL
      // =====================================================
      for (final entry in grouped.entries) {
        final sectionTitle = entry.key;
        final data = entry.value;

        final section = sheet.getRangeByIndex(rowIndex, 1, rowIndex, 10);
        section.merge();
        section.setText(sectionTitle);
        section.cellStyle.bold = true;
        section.cellStyle.backColor = "#B8CCE4";
        section.cellStyle.hAlign = xlsio.HAlignType.center;

        rowIndex++;

        double sectionTotal = 0;

        for (int i = 0; i < data.length; i++) {
          final visit = data[i];
          final parsedDate = DateFormat("dd-MMM-yy HH:mm").parse(visit.end);

          final noCell = sheet.getRangeByIndex(rowIndex, 1);

          if (i == 0) {
            noCell.setNumber(1);
          } else {
            noCell.formula = "=A${rowIndex - 1}+1";
          }

          final dateCell = sheet.getRangeByIndex(rowIndex, 2);
          dateCell.dateTime = parsedDate;
          dateCell.numberFormat = 'dd-mmm-yy';

          sheet.getRangeByIndex(rowIndex, 3).setText(visit.employee.nip ?? "");

          sheet
              .getRangeByIndex(rowIndex, 4)
              .setText(visit.employee.status ?? "");

          sheet
              .getRangeByIndex(rowIndex, 5)
              .setText(visit.employee.deptcode ?? "");

          sheet.getRangeByIndex(rowIndex, 6).setText(visit.employee.name ?? "");

          sheet
              .getRangeByIndex(rowIndex, 7)
              .setText(visit.employee.deptnm ?? "");

          final totalCell = sheet.getRangeByIndex(rowIndex, 8);
          totalCell.setNumber((visit.grandTotal).toDouble());
          totalCell.numberFormat = '#,##0';

          sheet.getRangeByIndex(rowIndex, 9).setText(visit.note);

          sheet.getRangeByIndex(rowIndex, 10).setText(visit.diagnose);

          sectionTotal += (visit.grandTotal).toDouble();
          grandTotal += (visit.grandTotal).toDouble();

          // CENTER + BORDER FULL
          for (int col = 1; col <= 10; col++) {
            final cell = sheet.getRangeByIndex(rowIndex, col);
            cell.cellStyle.hAlign = xlsio.HAlignType.center;
            cell.cellStyle.vAlign = xlsio.VAlignType.center;
            cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
          }

          rowIndex++;
        }

        // =============================
        // SUBTOTAL
        // =============================
        final subtotalRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, 7);
        subtotalRange.merge();
        subtotalRange.setText("Total Tagihan $sectionTitle (Sub Total)");
        subtotalRange.cellStyle.bold = true;
        subtotalRange.cellStyle.backColor = "#E6B8AF";
        subtotalRange.cellStyle.hAlign = xlsio.HAlignType.center;

        final subtotalCell = sheet.getRangeByIndex(rowIndex, 8);
        subtotalCell.setNumber(sectionTotal);
        subtotalCell.numberFormat = '"Rp" #,##0';
        subtotalCell.cellStyle.bold = true;
        subtotalCell.cellStyle.backColor = "#E6B8AF";
        subtotalCell.cellStyle.hAlign = xlsio.HAlignType.center;

        for (int col = 1; col <= 10; col++) {
          final cell = sheet.getRangeByIndex(rowIndex, col);
          cell.cellStyle.hAlign = xlsio.HAlignType.center;
          cell.cellStyle.vAlign = xlsio.VAlignType.center;
          cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        }

        rowIndex += 2;
      }

      // =====================================================
      // GRAND TOTAL
      // =====================================================
      final grandRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, 7);
      grandRange.merge();
      grandRange.setText("GRAND TOTAL");
      grandRange.cellStyle.bold = true;
      grandRange.cellStyle.backColor = "#FCD5B4";
      grandRange.cellStyle.hAlign = xlsio.HAlignType.center;

      final grandCell = sheet.getRangeByIndex(rowIndex, 8);
      grandCell.setNumber(grandTotal);
      grandCell.numberFormat = '"Rp" #,##0';
      grandCell.cellStyle.bold = true;
      grandCell.cellStyle.backColor = "#FCD5B4";
      grandCell.cellStyle.hAlign = xlsio.HAlignType.center;

      for (int col = 1; col <= 10; col++) {
        final cell = sheet.getRangeByIndex(rowIndex, col);
        cell.cellStyle.hAlign = xlsio.HAlignType.center;
        cell.cellStyle.vAlign = xlsio.VAlignType.center;
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      await FileSaver.instance.saveFile(
        name: "CAM_INVOICE",
        bytes: Uint8List.fromList(bytes),
        fileExtension: "xlsx",
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      print("ERROR EXPORT INVOICE: $e");
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
