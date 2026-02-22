import 'package:camreport/constant/route.dart';
import 'package:camreport/pages/employee/index.dart';
import 'package:camreport/pages/medicine/index.dart';
import 'package:camreport/pages/therapy/index.dart';
import 'package:camreport/pages/visit/index.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: LayoutBuilder(
      //   builder: (context, constraints) {
      //     final maxCrossAxisExtent = constraints.maxWidth / 2;
      //     final childAspectRatio =
      //         constraints.maxWidth / (constraints.maxHeight * 0.7);
      //     return GridView(
      //       gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      //         maxCrossAxisExtent: maxCrossAxisExtent,
      //         childAspectRatio: childAspectRatio,
      //       ),
      //       children: [
      //         InkWell(
      //           onTap: () {
      //             Navigator.pushNamed(context, employeeView);
      //           },
      //           child: Card(
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 Icon(Icons.person, size: 48.0),
      //                 Text('Employee'),
      //               ],
      //             ),
      //           ),
      //         ),
      //         InkWell(
      //           onTap: () {
      //             Navigator.pushNamed(context, medicineView);
      //           },
      //           child: Card(
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 Icon(Icons.medical_services, size: 48.0),
      //                 Text('Medicine'),
      //               ],
      //             ),
      //           ),
      //         ),
      //         InkWell(
      //           onTap: () {
      //             Navigator.pushNamed(context, visitView);
      //           },
      //           child: Card(
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 Icon(Icons.local_hospital, size: 48.0),
      //                 Text('Visit'),
      //               ],
      //             ),
      //           ),
      //         ),
      //         InkWell(
      //           onTap: () {
      //             Navigator.pushNamed(context, therapyView);
      //           },
      //           child: Card(
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 Icon(Icons.healing, size: 48.0),
      //                 Text('Therapy'),
      //               ],
      //             ),
      //           ),
      //         ),
      //         InkWell(
      //           onTap: () {
      //             Navigator.pushNamed(context, invoiceView);
      //           },
      //           child: Card(
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 Icon(Icons.receipt, size: 48.0),
      //                 Text('Invoice'),
      //               ],
      //             ),
      //           ),
      //         ),
      //       ],
      //     );
      //   },
      // ),
      body: appDrawer(context),
    );
  }

  Widget appDrawer(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.all,
          minWidth: 80,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Kunjungan'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: Text('Berobat'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Karyawan'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Obat'),
            ),
          ],
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return VisitPage();
      case 1:
        return TherapyPage();
      case 2:
        return EmployeePage();
      case 3:
        return MedicinePage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMenu({required bool isRail}) {
    return ListView(
      children: [
        const DrawerHeader(
          child: Text('ADMIN PANEL', style: TextStyle(fontSize: 20)),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () {
            setState(() => selectedIndex = 0);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Users'),
          onTap: () {
            setState(() => selectedIndex = 1);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            setState(() => selectedIndex = 2);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
