import '../../core/app_export.dart';

void showFilterOptions(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = DateTime.now();
        TimeOfDay selectedTime = TimeOfDay.now();

        return SingleChildScrollView(
            child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Filter Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text('Ascending'),
                leading: Radio(
                value: 'ascending',
                groupValue: 'sort',
                onChanged: (value) {},
                ),
              ),
              ListTile(
                title: Text('Descending'),
                leading: Radio(
                value: 'descending',
                groupValue: 'sort',
                onChanged: (value) {},
                ),
              ),
              Divider(),
              Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: Text('Pending'),
                value: false,
                onChanged: (bool? value) {},
              ),
              CheckboxListTile(
                title: Text('Closed'),
                value: false,
                onChanged: (bool? value) {},
              ),
              Divider(),
              Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text('Select Date'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != selectedDate) {
                  selectedDate = picked;
                }
                },
              ),
              Divider(),
              Text('Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                title: Text('Select Time'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null && picked != selectedTime) {
                  selectedTime = picked;
                }
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                TextButton(
                  style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 235, 96, 96),
                  ),
                  onPressed: () {
                  Navigator.of(context).pop();
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  ),
                  onPressed: () {
                  Navigator.of(context).pop();
                  },
                  child: Text('Apply Filters', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}