import 'dart:developer';

import 'package:camreport/models/employee.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/models/transaction_therapy.dart';
import 'package:camreport/models/transaction_visit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String employees = 'employee';
const String medicines = 'medicine';
const String trxvisit = 'trxvisit';
const String trxtherapy = 'trxtherapy';

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference<EmployeeModel> employeeCollection;
  late final CollectionReference<MedicineModel> medicineCollection;
  late final CollectionReference<TransactionVisit> trxvisitCollection;
  late final CollectionReference<TransactionTherapy> trxTherapyCollection;

  DatabaseService() {
    employeeCollection = _firestore
        .collection(employees)
        .withConverter<EmployeeModel>(
          fromFirestore: (snapshot, _) =>
              EmployeeModel.fromJson(snapshot.data()!, id: snapshot.id),
          toFirestore: (employee, _) => employee.toJson(),
        );

    medicineCollection = _firestore
        .collection(medicines)
        .withConverter<MedicineModel>(
          fromFirestore: (snapshot, _) =>
              MedicineModel.fromJson(snapshot.data()!, id: snapshot.id),
          toFirestore: (medicine, _) => medicine.toJson(),
        );

    trxTherapyCollection = _firestore
        .collection(trxtherapy)
        .withConverter<TransactionTherapy>(
          fromFirestore: (snapshot, _) =>
              TransactionTherapy.fromJson(snapshot.data()!, id: snapshot.id),
          toFirestore: (visit, _) => visit.toJson(),
        );

    trxvisitCollection = _firestore
        .collection(trxvisit)
        .withConverter<TransactionVisit>(
          fromFirestore: (snapshot, _) =>
              TransactionVisit.fromJson(snapshot.data()!, id: snapshot.id),
          toFirestore: (visit, _) => visit.toJson(),
        );
  }

  Future<DocumentReference<EmployeeModel>> _resolveEmployeeRef(
    EmployeeModel employee,
  ) async {
    if ((employee.id ?? '').isNotEmpty) {
      return employeeCollection.doc(employee.id);
    }

    final querySnapshot = await employeeCollection
        .where('nip', isEqualTo: employee.nip)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Data karyawan tidak ditemukan');
    }

    return querySnapshot.docs.first.reference;
  }

  Future<DocumentReference<MedicineModel>> _resolveMedicineRef(
    MedicineModel medicine,
  ) async {
    if ((medicine.id ?? '').isNotEmpty) {
      return medicineCollection.doc(medicine.id);
    }

    final querySnapshot = await medicineCollection
        .where('name', isEqualTo: medicine.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Data obat ${medicine.name} tidak ditemukan');
    }

    return querySnapshot.docs.first.reference;
  }

  Future<DocumentReference<TransactionVisit>> _resolveVisitRef(
    TransactionVisit visit,
  ) async {
    if ((visit.id ?? '').isNotEmpty) {
      return trxvisitCollection.doc(visit.id);
    }

    final querySnapshot = await trxvisitCollection
        .where('startDt', isEqualTo: visit.start)
        .where('endDt', isEqualTo: visit.end)
        .where('employee.nip', isEqualTo: visit.employee.nip)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Data kunjungan tidak ditemukan');
    }

    return querySnapshot.docs.first.reference;
  }

  Future<DocumentReference<TransactionTherapy>> _resolveTherapyRef(
    TransactionTherapy therapy,
  ) async {
    if ((therapy.id ?? '').isNotEmpty) {
      return trxTherapyCollection.doc(therapy.id);
    }

    final querySnapshot = await trxTherapyCollection
        .where('startDt', isEqualTo: therapy.start)
        .where('endDt', isEqualTo: therapy.end)
        .where('employee.nip', isEqualTo: therapy.employee.nip)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Data berobat tidak ditemukan');
    }

    return querySnapshot.docs.first.reference;
  }

  Map<String, int> _medicineTotals(List<MedicineModel> medicines) {
    final result = <String, int>{};
    for (final medicine in medicines) {
      final key = medicine.id ?? medicine.name ?? '';
      if (key.isEmpty) continue;
      result[key] = (result[key] ?? 0) + (medicine.total ?? 1);
    }
    return result;
  }

  MedicineModel? _findMedicineByKey(List<MedicineModel> medicines, String key) {
    for (final medicine in medicines) {
      if ((medicine.id ?? medicine.name) == key) {
        return medicine;
      }
    }
    return null;
  }

  Future<void> _applyMedicineStockChanges(
    WriteBatch batch, {
    required List<MedicineModel> before,
    required List<MedicineModel> after,
  }) async {
    final beforeTotals = _medicineTotals(before);
    final afterTotals = _medicineTotals(after);
    final keys = {...beforeTotals.keys, ...afterTotals.keys};

    for (final key in keys) {
      final prevQty = beforeTotals[key] ?? 0;
      final nextQty = afterTotals[key] ?? 0;
      final delta = nextQty - prevQty;

      if (delta == 0) continue;

      final medicine =
          _findMedicineByKey(after, key) ?? _findMedicineByKey(before, key);
      if (medicine == null) continue;

      final docRef = await _resolveMedicineRef(medicine);
      final snapshot = await docRef.get();
      final currentMedicine = snapshot.data();
      if (currentMedicine == null) {
        throw Exception('Data stok obat ${medicine.name} tidak ditemukan');
      }

      final newStock = (currentMedicine.lastStock ?? 0) - delta;
      if (newStock < 0) {
        throw Exception('Stok obat ${currentMedicine.name} tidak mencukupi');
      }

      batch.update(docRef, {'last_stock': newStock});
    }
  }

  TransactionVisit _therapyMirror(TransactionTherapy data, {String? id}) {
    return TransactionVisit(
      id: id,
      start: data.start,
      end: data.end,
      employee: data.employee,
      medicines: data.medicines,
      grandTotal: data.grandTotal,
      spenTm: data.spenTm,
      diagnose: data.diagnose,
      note: data.note,
      remark: data.result,
      category: 'therapy',
    );
  }

  Future<void> addEmployee(EmployeeModel employee) async {
    final docRef = employeeCollection.doc();
    await docRef.set(employee);
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    final docRef = medicineCollection.doc();
    await docRef.set(medicine);
  }

  Stream<QuerySnapshot> getEmployees() {
    return employeeCollection.snapshots();
  }

  Future<void> editEmployee(EmployeeModel employee) async {
    final docRef = await _resolveEmployeeRef(employee);
    await docRef.update(employee.toJson());
  }

  Future<void> deleteEmployee(EmployeeModel employee) async {
    final docRef = await _resolveEmployeeRef(employee);
    await docRef.delete();
  }

  Stream<QuerySnapshot> getMedicines() {
    return medicineCollection.snapshots();
  }

  Future<void> editMedicine(MedicineModel medicine) async {
    final docRef = await _resolveMedicineRef(medicine);
    await docRef.update(medicine.toJson());
  }

  Future<void> deleteMedicine(MedicineModel medicine) async {
    final docRef = await _resolveMedicineRef(medicine);
    await docRef.delete();
  }

  Stream<QuerySnapshot> getVisits() {
    return trxvisitCollection.snapshots();
  }

  Future<void> insertVisit(TransactionVisit data) async {
    final batch = _firestore.batch();
    final trxvisitRef = trxvisitCollection.doc();
    batch.set(
      trxvisitRef,
      data.copyWith(id: trxvisitRef.id, category: 'visit'),
    );
    await _applyMedicineStockChanges(
      batch,
      before: const [],
      after: data.medicines,
    );
    await batch.commit();
  }

  Future<void> updateVisit({
    required TransactionVisit previous,
    required TransactionVisit next,
  }) async {
    final batch = _firestore.batch();
    final trxvisitRef = await _resolveVisitRef(previous);
    batch.update(
      trxvisitRef,
      next.copyWith(id: trxvisitRef.id, category: 'visit').toJson(),
    );
    await _applyMedicineStockChanges(
      batch,
      before: previous.medicines,
      after: next.medicines,
    );
    await batch.commit();
  }

  Future<void> deleteVisit(TransactionVisit visit) async {
    final batch = _firestore.batch();
    final docRef = await _resolveVisitRef(visit);
    batch.delete(docRef);
    await _applyMedicineStockChanges(
      batch,
      before: visit.medicines,
      after: const [],
    );
    await batch.commit();
  }

  Stream<QuerySnapshot> getTherapy() {
    return trxTherapyCollection.snapshots();
  }

  Future<TransactionTherapy?> getTherapyById(String id) async {
    final snapshot = await trxTherapyCollection.doc(id).get();
    return snapshot.data();
  }

  Future<void> insertTherapy(TransactionTherapy data) async {
    final batch = _firestore.batch();
    final trxTherapyRef = trxTherapyCollection.doc();
    final trxvisitRef = trxvisitCollection.doc(trxTherapyRef.id);

    batch.set(trxTherapyRef, data.copyWith(id: trxTherapyRef.id));
    batch.set(trxvisitRef, _therapyMirror(data, id: trxTherapyRef.id));
    await _applyMedicineStockChanges(
      batch,
      before: const [],
      after: data.medicines,
    );
    await batch.commit();
  }

  Future<void> updateTherapy({
    required TransactionTherapy previous,
    required TransactionTherapy next,
  }) async {
    final batch = _firestore.batch();
    final therapyRef = await _resolveTherapyRef(previous);
    final visitRef = trxvisitCollection.doc(therapyRef.id);

    batch.update(therapyRef, next.copyWith(id: therapyRef.id).toJson());
    batch.set(visitRef, _therapyMirror(next, id: therapyRef.id));
    await _applyMedicineStockChanges(
      batch,
      before: previous.medicines,
      after: next.medicines,
    );
    await batch.commit();
  }

  Future<void> deleteTherapy(TransactionTherapy therapy) async {
    final batch = _firestore.batch();
    final docRef = await _resolveTherapyRef(therapy);
    batch.delete(docRef);
    batch.delete(trxvisitCollection.doc(docRef.id));
    await _applyMedicineStockChanges(
      batch,
      before: therapy.medicines,
      after: const [],
    );
    await batch.commit();
  }

  Future<void> deleteTherapyById(String id) async {
    final snapshot = await trxTherapyCollection.doc(id).get();
    final therapy = snapshot.data();
    if (therapy == null) {
      throw Exception('Data berobat tidak ditemukan');
    }

    await deleteTherapy(therapy);
  }

  Future<void> deleteAllVisitData() async {
    final querySnapshot = await trxvisitCollection.get();

    for (final doc in querySnapshot.docs) {
      final visit = doc.data();
      if (visit.category == 'visit') {
        await deleteVisit(visit);
      }
    }
  }

  Future<void> deleteAllTherapyData() async {
    final querySnapshot = await trxTherapyCollection.get();

    for (final doc in querySnapshot.docs) {
      await deleteTherapy(doc.data());
    }
  }

  Stream<List<TransactionVisit>> getInvoices() {
    try {
      return trxvisitCollection.orderBy('endDt').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return [];
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      log("ERROR GET INVOICE: $e");
      return const Stream.empty();
    }
  }
}
