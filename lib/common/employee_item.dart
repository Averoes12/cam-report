import 'package:flutter/material.dart';

class ListItem<T extends ListDisplayable> extends StatelessWidget {
  final T v;
  final void Function() onDelete;
  const ListItem({super.key, required this.v, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.name, style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(v.nip),
                  Text(v.deptnm),
                ],
              ),
            ),
            Column(children: [Text(v.start), Text(v.end)]),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class ListDisplayable {
  String get name;
  String get nip;
  String get deptnm;
  String get start;
  String get end;
}
