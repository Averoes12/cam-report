import 'package:camreport/models/transaction_visit.dart';
import 'package:flutter/foundation.dart';

class VisitProvider with ChangeNotifier {
  List<TransactionVisit> _trxs = [];

  List<TransactionVisit> get trxs => _trxs;

  set trxs(List<TransactionVisit> value) {
    _trxs = value;
    notifyListeners();
  }

  // Future<void> addTrx(TransactionVisit trx) async {
  //   await DatabaseService.addTrx(trx);
  //   _trxs = await DatabaseService.getTrxs();
  //   notifyListeners();
  // }
}
