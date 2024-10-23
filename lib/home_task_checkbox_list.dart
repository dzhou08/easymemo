import 'package:flutter/material.dart';


class TaskCheckList extends StatefulWidget {
  const TaskCheckList({super.key});

  @override
  State<TaskCheckList> createState() =>
      _TaskCheckListState();
}

class _TaskCheckListState extends State<TaskCheckList> {
  bool checkboxValue1 = true;
  bool checkboxValue2 = true;
  bool checkboxValue3 = true;

  @override
  Widget build(BuildContext context) {
    return Column(
        children: <Widget>[
          CheckboxListTile(
            value: checkboxValue1,
            onChanged: (bool? value) {
              setState(() {
                checkboxValue1 = value!;
              });
            },
            secondary: const Icon(Icons.dining_outlined),
            title: const Text('Breakfast'),
            subtitle: const Text('Oatmeal, banana, and coffee.'),
          ),
          const Divider(height: 0),
          CheckboxListTile(
            value: checkboxValue2,
            onChanged: (bool? value) {
              setState(() {
                checkboxValue2 = value!;
              });
            },
            secondary: const Icon(Icons.medication_outlined),
            title: const Text('Take Medication'),
            subtitle: const Text(
                'Remember to take the medication after breakfast.'),
          ),
          const Divider(height: 0),
          CheckboxListTile(
            value: checkboxValue3,
            onChanged: (bool? value) {
              setState(() {
                checkboxValue3 = value!;
              });
            },
            secondary: const Icon(Icons.video_call_outlined),
            title: const Text('Video Call'),
            subtitle: const Text(
                "Doctor appointment. Don't forget to ask about the new medication."),
            isThreeLine: true,
          ),
          const Divider(height: 0),
        ],
      );
  }
}
