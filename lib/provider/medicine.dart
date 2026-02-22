import 'package:camreport/models/medicine.dart';
import 'package:flutter/foundation.dart';

class MedicineProvider with ChangeNotifier {
  List<MedicineModel> _medicines = [];
  List<MedicineModel> get medicines => _medicines;

  void setMedicines(List<MedicineModel> value) {
    _medicines = value;
    notifyListeners();
  }

  void addMedicine(MedicineModel medicine) {
    _medicines.add(medicine);
    notifyListeners();
  }

  void removeMedicine(MedicineModel medicine) {
    _medicines.remove(medicine);
    notifyListeners();
  }

  void updateMedicine(MedicineModel oldMedicine, MedicineModel newMedicine) {
    int index = _medicines.indexOf(oldMedicine);
    if (index != -1) {
      _medicines[index] = newMedicine;
      notifyListeners();
    }
  }
}
