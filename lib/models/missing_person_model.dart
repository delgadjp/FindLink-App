import 'package:cloud_firestore/cloud_firestore.dart';

class MissingPerson {
  final String name;
  final String caseId;
  final String imageUrl;
  final String descriptions;
  final String address;
  final String placeLastSeen;
  final String datetimeLastSeen;
  final String datetimeReported;
  final String complainant;
  final String relationship;
  final String contactNo;
  final String additionalInfo;
  final String status;

  MissingPerson.fromMap(Map<String, dynamic> data)
      : name = data['name'] ?? '',
        caseId = data['case_id'] ?? '',
        imageUrl = data['imageUrl'] ?? data['image_url'] ?? data['image'] ?? '',
        descriptions = data['descriptions'] ?? '',
        address = data['address'] ?? '',
        placeLastSeen = data['place_last_seen'] ?? '',
        datetimeLastSeen = data['datetime_last_seen'] ?? '',
        datetimeReported = data['datetime_reported'] ?? '',
        complainant = data['complainant'] ?? '',
        relationship = data['relationship'] ?? '',
        contactNo = data['contact_no'] ?? '',
        additionalInfo = data['additional_info'] ?? '',
        status = data['status'] ?? 'ACTIVE';

  static MissingPerson fromSnapshot(DocumentSnapshot snap) {
    return MissingPerson.fromMap(snap.data() as Map<String, dynamic>);
  }

  void debugPrint() {
    print('MissingPerson Data:');
    print('Name: $name');
    print('Case ID: $caseId');
    print('Image URL: $imageUrl');
    print('Description: $descriptions');
  }
}
