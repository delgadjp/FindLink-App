import 'package:flutter/material.dart';
import 'custom_checkbox.dart';

class UnderInfluenceCheckboxes extends StatefulWidget {
  @override
  _UnderInfluenceCheckboxesState createState() => _UnderInfluenceCheckboxesState();
}

class _UnderInfluenceCheckboxesState extends State<UnderInfluenceCheckboxes> {
  bool no = false;
  bool drugs = false;
  bool liquor = false;
  bool others = false;
  TextEditingController othersController = TextEditingController();

  @override
  void dispose() {
    othersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UNDER THE INFLUENCE?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            CustomCheckbox(
              label: "NO",
              value: no,
              onChanged: (value) {
                setState(() {
                  no = value!;
                  if (no) {
                    drugs = false;
                    liquor = false;
                    others = false;
                    othersController.clear();
                  }
                });
              },
            ),
            CustomCheckbox(
              label: "DRUGS",
              value: drugs,
              onChanged: (value) {
                setState(() {
                  drugs = value!;
                  if (drugs) no = false;
                });
              },
            ),
            CustomCheckbox(
              label: "LIQUOR",
              value: liquor,
              onChanged: (value) {
                setState(() {
                  liquor = value!;
                  if (liquor) no = false;
                });
              },
            ),
            CustomCheckbox(
              label: "OTHERS",
              value: others,
              onChanged: (value) {
                setState(() {
                  others = value!;
                  if (others) {
                    no = false;
                  } else {
                    othersController.clear();
                  }
                });
              },
            ),
          ],
        ),
        if (others)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: TextField(
              controller: othersController,
              decoration: InputDecoration(
                labelText: "Specify Other Influences",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }
}
