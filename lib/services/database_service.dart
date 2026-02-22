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

  late final CollectionReference employeeCollection;
  late final CollectionReference medicineCollection;
  late final CollectionReference trxvisitCollection;
  late final CollectionReference trxTherapyCollection;

  DatabaseService() {
    employeeCollection = _firestore
        .collection(employees)
        .withConverter<EmployeeModel>(
          fromFirestore: (snapshot, _) =>
              EmployeeModel.fromJson(snapshot.data()!),
          toFirestore: (employee, _) => employee.toJson(),
        );

    medicineCollection = _firestore
        .collection(medicines)
        .withConverter<MedicineModel>(
          fromFirestore: (snapshot, _) =>
              MedicineModel.fromJson(snapshot.data()!),
          toFirestore: (medicine, _) => medicine.toJson(),
        );

    trxTherapyCollection = _firestore
        .collection(trxtherapy)
        .withConverter<TransactionTherapy>(
          fromFirestore: (snapshot, _) =>
              TransactionTherapy.fromJson(snapshot.data()!),
          toFirestore: (visit, _) => visit.toJson(),
        );

    trxvisitCollection = _firestore
        .collection(trxvisit)
        .withConverter<TransactionVisit>(
          fromFirestore: (snapshot, _) =>
              TransactionVisit.fromJson(snapshot.data()!),
          toFirestore: (visit, _) => visit.toJson(),
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
    final querySnapshot = await employeeCollection
        .where('nip', isEqualTo: employee.nip)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      final docRef = employeeCollection.doc(docId);

      await docRef.update(employee.toJson());
    }
  }

  Stream<QuerySnapshot> getMedicines() {
    return medicineCollection.snapshots();
  }

  Future<void> editMedicine(MedicineModel medicine) async {
    final querySnapshot = await medicineCollection
        .where('name', isEqualTo: medicine.name)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      final docRef = medicineCollection.doc(docId);

      await docRef.update(medicine.toJson());
    }
  }

  Future<void> deleteMedicine(MedicineModel medicine) async {
    final querySnapshot = await medicineCollection
        .where('name', isEqualTo: medicine.name)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      final docRef = medicineCollection.doc(docId);

      await docRef.delete();
    }
  }

  Stream<QuerySnapshot> getVisits() {
    return trxvisitCollection.snapshots();
  }

  Future<void> insertVisit(TransactionVisit data) async {
    final trxvisitRef = trxvisitCollection.doc();
    await trxvisitRef.set(data);
  }

  Future<void> deleteVisit(TransactionVisit visit) async {
    final querySnapshot = await trxvisitCollection
        .where('startDt', isEqualTo: visit.start)
        .where('endDt', isEqualTo: visit.end)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      final docRef = trxvisitCollection.doc(docId);

      await docRef.delete();
    }
  }

  Stream<QuerySnapshot> getTherapy() {
    return trxTherapyCollection.snapshots();
  }

  Future<void> insertTherapy(TransactionTherapy data) async {
    TransactionVisit trxVisitData = TransactionVisit(
      start: data.start,
      end: data.end,
      employee: data.employee,
      medicines: data.medicines,
      grandTotal: data.grandTotal,
      spenTm: data.spenTm,
      diagnose: data.diagnose,
      note: data.note,
      remark: '',
    );

    final trxvisitRef = trxvisitCollection.doc();
    await trxvisitRef.set(trxVisitData);
    final trxTherapyRef = trxTherapyCollection.doc();
    await trxTherapyRef.set(data);
  }

  Future<void> deleteTherapy(TransactionTherapy therapy) async {
    final querySnapshot = await trxTherapyCollection
        .where('startDt', isEqualTo: therapy.start)
        .where('endDt', isEqualTo: therapy.end)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docId = querySnapshot.docs.first.id;
      final docRef = trxTherapyCollection.doc(docId);

      await docRef.delete();
    }
  }

  Future<void> deleteAllVisitData() async {
    final querySnapshot = await trxvisitCollection.get();

    if (querySnapshot.docs.isNotEmpty) {
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> deleteAllTherapyData() async {
    final querySnapshot = await trxTherapyCollection.get();

    if (querySnapshot.docs.isNotEmpty) {
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
}
