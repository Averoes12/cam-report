import 'package:camreport/models/transaction_therapy.dart';
import 'package:flutter/foundation.dart';

class TherapyProvider with ChangeNotifier {
  TherapyProvider();

  List<TransactionTherapy> _trxTherapyList = [];

  List<TransactionTherapy> get trxTherapyList => _trxTherapyList;

  void addTrxTherapy(TransactionTherapy trxTherapy) {
    _trxTherapyList.add(trxTherapy);
    notifyListeners();
  }

  // void deleteTrxTherapy(TransactionTherapy trxTherapy) async {
  //   final querySnapshot = await trxTherapyCollection
  //       .where('startDt', isEqualTo: trxTherapy.start)
  //       .where('endDt', isEqualTo: trxTherapy.end)
  //       .get();

  //   if (querySnapshot.docs.isNotEmpty) {
  //     final docId = querySnapshot.docs.first.id;
  //     final docRef = trxTherapyCollection.doc(docId);

  //     await docRef.delete();
  //     _trxTherapyList.remove(trxTherapy);
  //     notifyListeners();
  //   }
  // }
}
