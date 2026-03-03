import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_visit.dart';
import '../services/database_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  DateTime _startPeriod = DateTime.now();
  DateTime _endPeriod = DateTime.now();

  DateTime get startPeriod => _startPeriod;
  DateTime get endPeriod => _endPeriod;

  List<TransactionVisit> _allData = [];
  Map<String, List<TransactionVisit>> _grouped = {};

  Map<String, List<TransactionVisit>> get groupedData => _grouped;

  InvoiceProvider() {
    _generatePeriod();
    _listenInvoices();
  }

  void changeMonth(DateTime date) {
    _selectedMonth = DateTime(date.year, date.month);
    _generatePeriod();
    _filterData();
    notifyListeners();
  }

  void _generatePeriod() {
    _startPeriod = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 26);
    _endPeriod = DateTime(_selectedMonth.year, _selectedMonth.month, 25);
  }

  void _listenInvoices() {    
    _db.getInvoices().listen((data) {
      _allData = data;      
      _filterData();
    });
  }

  void _filterData() {
    final filtered = _allData.where((visit) {
      final date = DateFormat("dd-MMM-yy HH:mm").parse(visit.end);

      return !date.isBefore(_startPeriod) && !date.isAfter(_endPeriod);
    }).toList();

    _grouped.clear();

    for (final visit in filtered) {
      final status = (visit.employee.status ?? "UNKNOWN").toUpperCase();

      _grouped.putIfAbsent(status, () => []);
      _grouped[status]!.add(visit);
    }

    notifyListeners();
  }

  int calculateTotal(List<TransactionVisit> visits) {
    return visits.fold(0, (sum, item) => sum + (item.grandTotal));
  }

  String get periodLabel =>
      "${DateFormat('dd MMM yyyy').format(_startPeriod)} - ${DateFormat('dd MMM yyyy').format(_endPeriod)}";
}
