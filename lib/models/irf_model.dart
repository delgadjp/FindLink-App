import 'package:cloud_firestore/cloud_firestore.dart';

class IRFModel {
  String? id;
  String? documentId; // Added formal document ID field
  
  // General Information
  String? typeOfIncident;
  String? copyFor;
  DateTime? dateTimeReported;
  DateTime? dateTimeIncident;
  String? placeOfIncident;
  
  // ITEM A - Reporting Person Information
  Map<String, dynamic>? itemA;
  
  // ITEM C - Victim Information
  Map<String, dynamic>? itemC;
  
  // ITEM D - Narrative
  String? narrative;
  String? typeOfIncidentD; // Sometimes repeated in item D
  DateTime? dateTimeIncidentD; // Sometimes repeated in item D
  String? placeOfIncidentD; // Sometimes repeated in item D
  
  // Status and metadata
  String? status; // draft, submitted, approved, rejected
  String? userId;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  IRFModel({
    this.id,
    this.documentId,
    this.typeOfIncident,
    this.copyFor,
    this.dateTimeReported,
    this.dateTimeIncident,
    this.placeOfIncident,
    this.itemA,
    this.itemC,
    this.narrative,
    this.typeOfIncidentD,
    this.dateTimeIncidentD,
    this.placeOfIncidentD,
    this.status,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory IRFModel.fromJson(Map<String, dynamic> json) {
    return IRFModel(
      id: json['id'],
      documentId: json['documentId'], // Added to parse from JSON
      typeOfIncident: json['typeOfIncident'],
      copyFor: json['copyFor'],
      dateTimeReported: (json['dateTimeReported'] as Timestamp?)?.toDate(),
      dateTimeIncident: (json['dateTimeIncident'] as Timestamp?)?.toDate(),
      placeOfIncident: json['placeOfIncident'],
      itemA: json['itemA'],
      itemC: json['itemC'],
      narrative: json['narrative'],
      typeOfIncidentD: json['typeOfIncidentD'],
      dateTimeIncidentD: (json['dateTimeIncidentD'] as Timestamp?)?.toDate(),
      placeOfIncidentD: json['placeOfIncidentD'],
      status: json['status'],
      userId: json['userId'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory IRFModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IRFModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'documentId': documentId, // Include the formal document ID
      'typeOfIncident': typeOfIncident,
      'copyFor': copyFor,
      'dateTimeReported': dateTimeReported,
      'dateTimeIncident': dateTimeIncident,
      'placeOfIncident': placeOfIncident,
      'itemA': itemA,
      'itemC': itemC,
      'narrative': narrative,
      'typeOfIncidentD': typeOfIncidentD,
      'dateTimeIncidentD': dateTimeIncidentD,
      'placeOfIncidentD': placeOfIncidentD,
      'status': status,
    };
    
    // Remove null values
    data.removeWhere((key, value) => value == null);
    
    return data;
  }
  
  // Helper method to create person details map with the required fields
  static Map<String, dynamic> createPersonDetails({
    String? surname = '',
    String? firstName = '',
    String? middleName = '',
    String? qualifier = '',
    String? nickname = '',
    String? citizenship = '',
    String? sexGender = '',
    String? civilStatus = '',
    DateTime? dateOfBirth,
    int? age,
    String? placeOfBirth = '',
    String? homePhone = '',
    String? mobilePhone = '',
    String? currentAddress = '',
    String? villageSitio = '',
    String? region = '',
    String? province = '',
    String? townCity = '',
    String? barangay = '',
    String? otherAddress = '',
    String? otherVillageSitio = '',
    String? otherRegion = '',
    String? otherProvince = '',
    String? otherTownCity = '',
    String? otherBarangay = '',
    String? highestEducationAttainment = '',
    String? occupation = '',
    String? workAddress = '',
    String? idCardPresented = '',
    String? emailAddress = '',
  }) {
    final Map<String, dynamic> person = {
      'surname': surname,
      'firstName': firstName,
      'middleName': middleName,
      'qualifier': qualifier,
      'nickname': nickname,
      'citizenship': citizenship,
      'sexGender': sexGender,
      'civilStatus': civilStatus,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'placeOfBirth': placeOfBirth,
      'homePhone': homePhone,
      'mobilePhone': mobilePhone,
      'currentAddress': currentAddress,
      'villageSitio': villageSitio,
      'region': region,
      'province': province,
      'townCity': townCity,
      'barangay': barangay,
      'education': highestEducationAttainment,
      'occupation': occupation,
      'emailAddress': emailAddress,
    };
    
    // Add conditional fields
    if (otherAddress != null && otherAddress.isNotEmpty) {
      person['otherAddress'] = otherAddress;
      person['otherVillageSitio'] = otherVillageSitio;
      person['otherRegion'] = otherRegion;
      person['otherProvince'] = otherProvince;
      person['otherTownCity'] = otherTownCity;
      person['otherBarangay'] = otherBarangay;
    }
    
    if (workAddress != null && workAddress.isNotEmpty) {
      person['workAddress'] = workAddress;
    }
    
    if (idCardPresented != null && idCardPresented.isNotEmpty) {
      person['idCardPresented'] = idCardPresented;
    }
    
    // Remove null or empty values
    person.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    
    return person;
  }
}
