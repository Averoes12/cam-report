import 'package:camreport/constant/route.dart';
import 'package:camreport/models/medicine.dart';
import 'package:camreport/pages/employee/add.dart';
import 'package:camreport/pages/invoice/index.dart';
import 'package:camreport/pages/medicine/add.dart';
import 'package:camreport/pages/medicine/index.dart';
import 'package:camreport/pages/therapy/index.dart';
import 'package:camreport/pages/visit/index.dart';
import 'package:camreport/pages/visit/steps/transaction_therapy.dart';
import 'package:camreport/pages/visit/steps/transaction_visit.dart';
import 'package:flutter/material.dart';
import 'package:camreport/pages/employee/index.dart';
import 'package:camreport/pages/home.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeView:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case employeeView:
        return MaterialPageRoute(builder: (_) => const EmployeePage());
      case addEmployeeView:
        return MaterialPageRoute(builder: (_) => const AddEmployeePage());
      case medicineView:
        return MaterialPageRoute(builder: (_) => const MedicinePage());
      case addMedicineView:
        final argument = (settings.arguments != null)
            ? settings.arguments as MedicineModel
            : null;
        return MaterialPageRoute(
          builder: (_) => AddMedicinePage(medicine: argument),
        );
      case visitView:
        return MaterialPageRoute(builder: (_) => const VisitPage());
      case addVisitView:
        return MaterialPageRoute(builder: (_) => const AddVisitPage());
      case therapyView:
        return MaterialPageRoute(builder: (_) => const TherapyPage());
      case addTherapyView:
        return MaterialPageRoute(builder: (_) => const AddTherapyPage());
      case invoiceView:
        return MaterialPageRoute(builder: (_) => const InvoicePage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}
