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

  static DateTime? tryParseDate(String? dateStr) {
    if (dateStr == null) return null;
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return null;

    final patterns = [
      'dd-MMM-yy HH:mm',
      'dd-MMM-yy',
      'dd-MMM-yyyy HH:mm',
      'dd-MMM-yyyy',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy',
      'dd-MM-yyyy HH:mm',
      'dd-MM-yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd',
    ];

    for (final pattern in patterns) {
      try {
        return DateFormat(pattern, 'en_US').parse(trimmed);
      } catch (_) {}
      try {
        return DateFormat(pattern).parse(trimmed);
      } catch (_) {}
    }

    return DateTime.tryParse(trimmed);
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
      visits = [...visits]
        ..sort((a, b) {
          final dateA = Utils.tryParseDate(a.end) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = Utils.tryParseDate(b.end) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateA.compareTo(dateB);
        });
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
                final parsed = Utils.tryParseDate(row[col].toString());
                if (parsed != null) {
                  cell.dateTime = parsed;
                  cell.numberFormat = 'dd-MMM-yy';
                }
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
                final parsed = Utils.tryParseDate(row[col].toString());
                if (parsed != null) {
                  cell.dateTime = parsed;
                  cell.numberFormat = 'dd-MMM-yy';
                }
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
        final date = Utils.tryParseDate(visit.end);
        if (date == null) return false;

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
          final parsedDate = Utils.tryParseDate(visit.end);

          final noCell = sheet.getRangeByIndex(rowIndex, 1);

          if (i == 0) {
            noCell.setNumber(1);
          } else {
            noCell.formula = "=A${rowIndex - 1}+1";
          }

          final dateCell = sheet.getRangeByIndex(rowIndex, 2);
          if (parsedDate != null) {
            dateCell.dateTime = parsedDate;
            dateCell.numberFormat = 'dd-mmm-yy';
          }

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

  static String getExcelColumnName(int colIndex) {
    int temp = colIndex;
    String letter = '';
    while (temp > 0) {
      int mod = (temp - 1) % 26;
      letter = String.fromCharCode(65 + mod) + letter;
      temp = (temp - 1) ~/ 26;
    }
    return letter;
  }

  static String formatIndonesianMonthRange(DateTime start, DateTime end) {
    const months = [
      '',
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER',
    ];
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${start.day} - ${end.day} ${months[start.month]} ${start.year}';
      } else {
        return '${start.day} ${months[start.month]} - ${end.day} ${months[end.month]} ${start.year}';
      }
    } else {
      return '${start.day} ${months[start.month]} ${start.year} - ${end.day} ${months[end.month]} ${end.year}';
    }
  }

  static Future<void> exportMedicineReport({
    required List<MedicineModel> medicines,
    required Map<String, Map<String, int>> dailyMedicine,
    required List<String> allDates,
    required Map<String, String> dateLabels,
    String periodLabel = '',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final workbook = xlsio.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Sheet1';

      final int dateCount = allDates.length;
      final int firstDateCol = 9;
      final int lastDateCol =
          dateCount > 0 ? (firstDateCol + dateCount - 1) : firstDateCol;
      final int totalUsedCol = dateCount > 0 ? (lastDateCol + 1) : 9;
      final int totalCostCol = totalUsedCol + 1;
      final int lastStockCol = totalCostCol + 1;
      final int edCol = lastStockCol + 1;
      final int totalColumns = edCol;

      // Row 1 Title (B1)
      String titleText = 'STOK OBAT IHC MEAINA';
      if (periodLabel.isNotEmpty) {
        titleText = 'STOK OBAT IHC MEAINA ${periodLabel.toUpperCase()}';
      } else if (startDate != null && endDate != null) {
        titleText =
            'STOK OBAT IHC MEAINA ${formatIndonesianMonthRange(startDate, endDate)}';
      }

      final titleCell = sheet.getRangeByIndex(1, 2);
      titleCell.setText(titleText);
      titleCell.cellStyle.fontName = 'Calibri';
      titleCell.cellStyle.fontSize = 11;
      titleCell.cellStyle.bold = true;
      titleCell.cellStyle.hAlign = xlsio.HAlignType.center;
      titleCell.cellStyle.vAlign = xlsio.VAlignType.center;

      // Header Row 2 & 3
      const headerColor = '#E8346C';

      void styleHeaderCell(
        xlsio.Range cell, {
        String? fontName,
        double fontSize = 11,
      }) {
        cell.cellStyle.backColor = headerColor;
        cell.cellStyle.bold = true;
        cell.cellStyle.fontSize = fontSize;
        if (fontName != null) cell.cellStyle.fontName = fontName;
        cell.cellStyle.hAlign = xlsio.HAlignType.center;
        cell.cellStyle.vAlign = xlsio.VAlignType.center;
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      }

      // Static headers (Cols A-H)
      final staticHeaderTitles = [
        "NO",
        "NAMA OBAT",
        "SATUAN",
        "HARGA JUAL",
        "STOK AWAL",
        "OBAT DATANG",
        "RETURN KE CAM",
        "TOTAL OBAT",
      ];

      for (int i = 0; i < staticHeaderTitles.length; i++) {
        final range = sheet.getRangeByIndex(2, i + 1, 3, i + 1);
        range.merge();
        range.setText(staticHeaderTitles[i]);
        styleHeaderCell(
          range,
          fontName: i < 4 ? 'Times New Roman' : 'Calibri',
        );
      }

      // Date columns header
      if (dateCount > 0) {
        final dateHeaderRange = sheet.getRangeByIndex(
          2,
          firstDateCol,
          2,
          lastDateCol,
        );
        if (firstDateCol != lastDateCol) {
          dateHeaderRange.merge();
        }
        dateHeaderRange.setText("TANGGAL KELUAR OBAT HARIAN");
        styleHeaderCell(dateHeaderRange, fontName: 'Calibri');

        // Sub-headers for dates in Row 3
        for (int d = 0; d < dateCount; d++) {
          final dateKey = allDates[d];
          final parsed =
              DateTime.tryParse(dateKey) ?? Utils.tryParseDate(dateKey);
          final dayLabel =
              parsed != null
                  ? parsed.day.toString()
                  : (dateLabels[dateKey] ?? dateKey);

          final cell = sheet.getRangeByIndex(3, firstDateCol + d);
          cell.setText(dayLabel);
          styleHeaderCell(cell, fontName: 'Calibri');
        }
      }

      // Trailing headers
      final trailingHeaders = [
        "TOTAL OBAT KELUAR",
        "TOTAL HARGA RESEP",
        "STOK AKHIR",
        "ED OBAT",
      ];

      for (int i = 0; i < trailingHeaders.length; i++) {
        final col = totalUsedCol + i;
        final range = sheet.getRangeByIndex(2, col, 3, col);
        range.merge();
        range.setText(trailingHeaders[i]);
        styleHeaderCell(range, fontName: 'Calibri');
      }

      // Separate into Non-BPJS and BPJS
      final nonBpjsMedicines =
          medicines
              .where((m) => !(m.name ?? '').toUpperCase().contains('BPJS'))
              .toList();
      final bpjsMedicines =
          medicines
              .where((m) => (m.name ?? '').toUpperCase().contains('BPJS'))
              .toList();

      final firstDateLetter = getExcelColumnName(firstDateCol);
      final lastDateLetter = getExcelColumnName(lastDateCol);
      final totalUsedLetter = getExcelColumnName(totalUsedCol);
      final totalCostLetter = getExcelColumnName(totalCostCol);

      int currentRow = 4;
      final int firstDataRow = currentRow;

      void writeMedicineRows(List<MedicineModel> list) {
        for (int i = 0; i < list.length; i++) {
          final med = list[i];
          final medName = med.name ?? '';
          final dateMap = dailyMedicine[medName] ?? {};

          // Col 1: NO (#FFC1C1)
          final noCell = sheet.getRangeByIndex(currentRow, 1);
          noCell.setNumber((i + 1).toDouble());
          noCell.cellStyle.backColor = '#FFC1C1';
          noCell.cellStyle.hAlign = xlsio.HAlignType.center;
          noCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 2: NAMA OBAT (#FFC1C1)
          final nameCell = sheet.getRangeByIndex(currentRow, 2);
          nameCell.setText(medName);
          nameCell.cellStyle.fontName = 'Times New Roman';
          nameCell.cellStyle.backColor = '#FFC1C1';
          nameCell.cellStyle.hAlign = xlsio.HAlignType.left;
          nameCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 3: SATUAN (#FFC1C1)
          final unitCell = sheet.getRangeByIndex(currentRow, 3);
          unitCell.setText(med.measure?.toString() ?? '');
          unitCell.cellStyle.fontName = 'Times New Roman';
          unitCell.cellStyle.backColor = '#FFC1C1';
          unitCell.cellStyle.hAlign = xlsio.HAlignType.center;
          unitCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 4: HARGA JUAL (#FFC1C1)
          final priceCell = sheet.getRangeByIndex(currentRow, 4);
          final price = (med.price ?? 0).toDouble();
          priceCell.setNumber(price);
          priceCell.numberFormat = '#,##0';
          priceCell.cellStyle.fontName = 'Times New Roman';
          priceCell.cellStyle.backColor = '#FFC1C1';
          priceCell.cellStyle.hAlign = xlsio.HAlignType.center;
          priceCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 5: STOK AWAL (#EB3D73)
          final firstStockCell = sheet.getRangeByIndex(currentRow, 5);
          final firstStock = (med.firstStock ?? 0).toDouble();
          firstStockCell.setNumber(firstStock);
          firstStockCell.cellStyle.backColor = '#EB3D73';
          firstStockCell.cellStyle.hAlign = xlsio.HAlignType.center;
          firstStockCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 6: OBAT DATANG (White / No fill)
          final arrivedCell = sheet.getRangeByIndex(currentRow, 6);
          if (med.arrivedStock != null && med.arrivedStock! > 0) {
            arrivedCell.setNumber(med.arrivedStock!.toDouble());
          }
          arrivedCell.cellStyle.hAlign = xlsio.HAlignType.center;
          arrivedCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 7: RETURN KE CAM (#E8346C)
          final returnCell = sheet.getRangeByIndex(currentRow, 7);
          if (med.returnedStock != null && med.returnedStock! > 0) {
            returnCell.setNumber(med.returnedStock!.toDouble());
          }
          returnCell.cellStyle.backColor = '#E8346C';
          returnCell.cellStyle.hAlign = xlsio.HAlignType.center;
          returnCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col 8: TOTAL OBAT (#E8346C)
          final totalObatCell = sheet.getRangeByIndex(currentRow, 8);
          totalObatCell.setFormula(
            '=SUM(E$currentRow+F$currentRow-G$currentRow)',
          );
          totalObatCell.cellStyle.backColor = '#E8346C';
          totalObatCell.cellStyle.hAlign = xlsio.HAlignType.center;
          totalObatCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Daily date columns
          int totalUsed = 0;
          for (int d = 0; d < dateCount; d++) {
            final dateKey = allDates[d];
            final qty = dateMap[dateKey] ?? 0;
            totalUsed += qty;

            final parsed =
                DateTime.tryParse(dateKey) ?? Utils.tryParseDate(dateKey);
            final isWeekend =
                parsed != null &&
                (parsed.weekday == DateTime.saturday ||
                    parsed.weekday == DateTime.sunday);

            final dateCell = sheet.getRangeByIndex(currentRow, firstDateCol + d);
            if (qty > 0) {
              dateCell.setNumber(qty.toDouble());
            }
            dateCell.cellStyle.backColor = isWeekend ? '#C00000' : '#F7E3AB';
            dateCell.cellStyle.hAlign = xlsio.HAlignType.center;
            dateCell.cellStyle.vAlign = xlsio.VAlignType.center;
          }

          // Col TOTAL OBAT KELUAR (#E8346C)
          final usedCell = sheet.getRangeByIndex(currentRow, totalUsedCol);
          if (dateCount > 0) {
            usedCell.setFormula(
              '=SUM($firstDateLetter$currentRow:$lastDateLetter$currentRow)',
            );
          } else {
            usedCell.setNumber(totalUsed.toDouble());
          }
          usedCell.cellStyle.backColor = '#E8346C';
          usedCell.cellStyle.hAlign = xlsio.HAlignType.center;
          usedCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col TOTAL HARGA RESEP (#F6A0BB)
          final costCell = sheet.getRangeByIndex(currentRow, totalCostCol);
          costCell.setFormula('=SUM(D$currentRow*$totalUsedLetter$currentRow)');
          costCell.numberFormat = '#,##0';
          costCell.cellStyle.backColor = '#F6A0BB';
          costCell.cellStyle.hAlign = xlsio.HAlignType.right;
          costCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col STOK AKHIR (#FFC1C1)
          final stockAkhirCell = sheet.getRangeByIndex(currentRow, lastStockCol);
          stockAkhirCell.setFormula(
            '=SUM(H$currentRow-$totalUsedLetter$currentRow)',
          );
          stockAkhirCell.numberFormat = '#,##0';
          stockAkhirCell.cellStyle.backColor = '#FFC1C1';
          stockAkhirCell.cellStyle.hAlign = xlsio.HAlignType.center;
          stockAkhirCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Col ED OBAT (No fill)
          final edCell = sheet.getRangeByIndex(currentRow, edCol);
          edCell.setText(med.expDt?.toString() ?? '');
          edCell.cellStyle.hAlign = xlsio.HAlignType.center;
          edCell.cellStyle.vAlign = xlsio.VAlignType.center;

          // Thin border on all columns for this row
          for (int c = 1; c <= totalColumns; c++) {
            sheet.getRangeByIndex(currentRow, c).cellStyle.borders.all.lineStyle =
                xlsio.LineStyle.thin;
          }

          currentRow++;
        }
      }

      // Write Non-BPJS
      writeMedicineRows(nonBpjsMedicines);

      // Write BPJS Section if any
      if (bpjsMedicines.isNotEmpty) {
        // Section Header Row
        final bpjsHeaderRange = sheet.getRangeByIndex(
          currentRow,
          1,
          currentRow,
          4,
        );
        bpjsHeaderRange.merge();
        bpjsHeaderRange.setText('DAFTAR DAN HARGA OBAT BPJS SESUAI SISTEM');
        bpjsHeaderRange.cellStyle.bold = true;
        bpjsHeaderRange.cellStyle.fontSize = 14;
        bpjsHeaderRange.cellStyle.fontName = 'Tahoma';
        bpjsHeaderRange.cellStyle.hAlign = xlsio.HAlignType.center;
        bpjsHeaderRange.cellStyle.vAlign = xlsio.VAlignType.center;

        for (int c = 1; c <= totalColumns; c++) {
          sheet.getRangeByIndex(currentRow, c).cellStyle.borders.all.lineStyle =
              xlsio.LineStyle.thin;
        }

        currentRow++;

        // Write BPJS Rows
        writeMedicineRows(bpjsMedicines);
      }

      final lastDataRow = currentRow - 1;

      // Bottom Summary Rows
      if (lastDataRow >= firstDataRow) {
        // Row 1: GRAND TOTAL
        final grandTotalRow = currentRow;
        final mergeStartCol = (totalUsedCol - 8).clamp(1, totalUsedCol);
        final grandTotalLabelRange = sheet.getRangeByIndex(
          grandTotalRow,
          mergeStartCol,
          grandTotalRow,
          totalUsedCol,
        );
        if (mergeStartCol != totalUsedCol) {
          grandTotalLabelRange.merge();
        }
        grandTotalLabelRange.setText('GRAND TOTAL');
        grandTotalLabelRange.cellStyle.backColor = '#E8346C';
        grandTotalLabelRange.cellStyle.bold = true;
        grandTotalLabelRange.cellStyle.fontName = 'Cambria';
        grandTotalLabelRange.cellStyle.fontSize = 12;
        grandTotalLabelRange.cellStyle.hAlign = xlsio.HAlignType.center;
        grandTotalLabelRange.cellStyle.vAlign = xlsio.VAlignType.center;

        final grandTotalCostCell = sheet.getRangeByIndex(
          grandTotalRow,
          totalCostCol,
        );
        grandTotalCostCell.setFormula(
          '=SUM($totalCostLetter$firstDataRow:$totalCostLetter$lastDataRow)',
        );
        grandTotalCostCell.numberFormat = '#,##0';
        grandTotalCostCell.cellStyle.backColor = '#F7E3AB';
        grandTotalCostCell.cellStyle.hAlign = xlsio.HAlignType.right;
        grandTotalCostCell.cellStyle.vAlign = xlsio.VAlignType.center;

        for (int c = 1; c <= totalColumns; c++) {
          sheet.getRangeByIndex(grandTotalRow, c).cellStyle.borders.all.lineStyle =
              xlsio.LineStyle.thin;
        }

        currentRow++;

        // Row 2: PO ALKES
        final poAlkesRow = currentRow;
        final poAlkesCell = sheet.getRangeByIndex(poAlkesRow, totalUsedCol);
        poAlkesCell.setText('PO ALKES');
        poAlkesCell.cellStyle.hAlign = xlsio.HAlignType.center;
        poAlkesCell.cellStyle.vAlign = xlsio.VAlignType.center;
        final poAlkesCostCell = sheet.getRangeByIndex(poAlkesRow, totalCostCol);
        poAlkesCostCell.setNumber(0);
        poAlkesCostCell.numberFormat = '#,##0';
        poAlkesCostCell.cellStyle.hAlign = xlsio.HAlignType.right;

        currentRow++;

        // Row 3: BPJS
        final bpjsRow = currentRow;
        final bpjsCell = sheet.getRangeByIndex(bpjsRow, totalUsedCol);
        bpjsCell.setText('BPJS');
        bpjsCell.cellStyle.hAlign = xlsio.HAlignType.center;
        bpjsCell.cellStyle.vAlign = xlsio.VAlignType.center;
        final bpjsCostCell = sheet.getRangeByIndex(bpjsRow, totalCostCol);
        bpjsCostCell.setNumber(0);
        bpjsCostCell.numberFormat = '#,##0';
        bpjsCostCell.cellStyle.hAlign = xlsio.HAlignType.right;

        currentRow++;

        // Row 4: TOTAL SESUAI INVOICE
        final invoiceRow = currentRow;
        final invoiceCell = sheet.getRangeByIndex(invoiceRow, totalUsedCol);
        invoiceCell.setText('TOTAL SESUAI INVOICE');
        invoiceCell.cellStyle.bold = true;
        invoiceCell.cellStyle.hAlign = xlsio.HAlignType.center;
        invoiceCell.cellStyle.vAlign = xlsio.VAlignType.center;

        final invoiceCostCell = sheet.getRangeByIndex(invoiceRow, totalCostCol);
        invoiceCostCell.setFormula(
          '=SUM($totalCostLetter$grandTotalRow+$totalCostLetter$poAlkesRow-$totalCostLetter$bpjsRow)',
        );
        invoiceCostCell.numberFormat = '#,##0';
        invoiceCostCell.cellStyle.bold = true;
        invoiceCostCell.cellStyle.hAlign = xlsio.HAlignType.right;
        invoiceCostCell.cellStyle.vAlign = xlsio.VAlignType.center;
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      await FileSaver.instance.saveFile(
        name: "Laporan_Obat",
        bytes: Uint8List.fromList(bytes),
        fileExtension: "xlsx",
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      log("❌ ERROR EXPORT MEDICINE REPORT: $e");
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
