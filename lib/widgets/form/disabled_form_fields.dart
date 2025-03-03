import 'package:flutter/material.dart';

class DisabledFormFields {
  static Widget buildDisabledAddressField(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Container(
              height: 35,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildDisabledFormRow(List<String> labels) {
    return Row(
      children: labels.map((label) => buildDisabledAddressField(label)).toList(),
    );
  }
}
