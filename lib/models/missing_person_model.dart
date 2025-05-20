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
  final DateTime? lastSeenDateTime;  // Added actual DateTime field
  final DateTime? reportedDateTime;  // Added actual DateTime field

  MissingPerson.fromMap(Map<String, dynamic> data)
      : name = data['name'] ?? '',
        caseId = data['case_id'] ?? '',
        imageUrl = data['imageUrl'] ?? data['image_url'] ?? data['image'] ?? '',
        descriptions = data['descriptions'] ?? '',
        address = data['address'] ?? '',
        placeLastSeen = data['place_last_seen'] ?? '',
        lastSeenDateTime = _parseTimestamp(data['datetime_last_seen']),
        reportedDateTime = _parseTimestamp(data['datetime_reported']),
        datetimeLastSeen = _formatTimestamp(data['datetime_last_seen']),
        datetimeReported = _formatTimestamp(data['datetime_reported']),
        complainant = data['complainant'] ?? '',
        relationship = data['relationship'] ?? '',
        contactNo = data['contact_no'] ?? '',
        additionalInfo = data['additional_info'] ?? '',
        status = data['status'] ?? 'ACTIVE';

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    try {
      // Attempt to parse if it's a string in a common format
      return DateTime.parse(timestamp.toString());
    } catch (_) {
      return null;
    }
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (timestamp is DateTime) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    
    return timestamp.toString();
  }

  static MissingPerson fromSnapshot(DocumentSnapshot snap) {
    return MissingPerson.fromMap(snap.data() as Map<String, dynamic>);
  }

  void debugPrint() {
    print('MissingPerson Data:');
    print('Name: $name');
    print('Case ID: $caseId');
    print('Image URL: $imageUrl');
    print('Description: $descriptions');
    print('Last Seen: $datetimeLastSeen');
    print('Reported: $datetimeReported');
  }
}
