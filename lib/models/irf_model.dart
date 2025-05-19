import 'package:cloud_firestore/cloud_firestore.dart';

class IRFModel {
  String? id;
  String? documentId;

  // General Information
  String? typeOfIncident;
  String? copyFor;
  DateTime? dateTimeReported;
  DateTime? dateTimeIncident;
  String? placeOfIncident;

  // Reporting Person (Item A)
  String? surnameA;
  String? firstNameA;
  String? middleNameA;
  String? qualifierA;
  String? nicknameA;
  String? citizenshipA;
  String? sexGenderA;
  String? civilStatusA;
  String? dateOfBirthA;
  int? ageA;
  String? placeOfBirthA;
  String? homePhoneA;
  String? mobilePhoneA;
  String? currentAddressA;
  String? villageA;
  String? regionA;
  String? provinceA;
  String? townCityA;
  String? barangayA;
  String? otherAddressA;
  String? otherVillageA;
  String? otherRegionA;
  String? otherProvinceA;
  String? otherTownCityA;
  String? otherBarangayA;
  String? highestEducationAttainmentA;
  String? occupationA;
  String? idCardPresentedA;
  String? emailAddressA;

  // Missing Person (Item B)
  String? surnameB;
  String? firstNameB;
  String? middleNameB;
  String? qualifierB;
  String? nicknameB;
  String? citizenshipB;
  String? sexGenderB;
  String? civilStatusB;
  String? dateOfBirthB;
  int? ageB;
  String? placeOfBirthB;
  String? homePhoneB;
  String? mobilePhoneB;
  String? currentAddressB;
  String? villageB;
  String? regionB;
  String? provinceB;
  String? townCityB;
  String? barangayB;
  String? otherAddressB;
  String? otherVillageB;
  String? otherRegionB;
  String? otherProvinceB;
  String? otherTownCityB;
  String? otherBarangayB;
  String? highestEducationAttainmentB;
  String? occupationB;
  String? workAddressB;
  String? emailAddressB;

  // Narrative of Incident
  String? narrative;
  String? typeOfIncidentD;
  DateTime? dateTimeIncidentD;
  String? placeOfIncidentD;

  // Status and metadata
  String? status;
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
    // Item A
    this.surnameA,
    this.firstNameA,
    this.middleNameA,
    this.qualifierA,
    this.nicknameA,
    this.citizenshipA,
    this.sexGenderA,
    this.civilStatusA,
    this.dateOfBirthA,
    this.ageA,
    this.placeOfBirthA,
    this.homePhoneA,
    this.mobilePhoneA,
    this.currentAddressA,
    this.villageA,
    this.regionA,
    this.provinceA,
    this.townCityA,
    this.barangayA,
    this.otherAddressA,
    this.otherVillageA,
    this.otherRegionA,
    this.otherProvinceA,
    this.otherTownCityA,
    this.otherBarangayA,
    this.highestEducationAttainmentA,
    this.occupationA,
    this.idCardPresentedA,
    this.emailAddressA,
    // Item B
    this.surnameB,
    this.firstNameB,
    this.middleNameB,
    this.qualifierB,
    this.nicknameB,
    this.citizenshipB,
    this.sexGenderB,
    this.civilStatusB,
    this.dateOfBirthB,
    this.ageB,
    this.placeOfBirthB,
    this.homePhoneB,
    this.mobilePhoneB,
    this.currentAddressB,
    this.villageB,
    this.regionB,
    this.provinceB,
    this.townCityB,
    this.barangayB,
    this.otherAddressB,
    this.otherVillageB,
    this.otherRegionB,
    this.otherProvinceB,
    this.otherTownCityB,
    this.otherBarangayB,
    this.highestEducationAttainmentB,
    this.occupationB,
    this.workAddressB,
    this.emailAddressB,
    // Narrative
    this.narrative,
    this.typeOfIncidentD,
    this.dateTimeIncidentD,
    this.placeOfIncidentD,
    // Metadata
    this.status,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory IRFModel.fromJson(Map<String, dynamic> json) {
    return IRFModel(
      id: json['id'],
      documentId: json['documentId'],
      typeOfIncident: json['typeOfIncident'],
      copyFor: json['copyFor'],
      dateTimeReported: _parseDate(json['dateTimeReported']),
      dateTimeIncident: _parseDate(json['dateTimeIncident']),
      placeOfIncident: json['placeOfIncident'],
      // Item A
      surnameA: json['surnameA'],
      firstNameA: json['firstNameA'],
      middleNameA: json['middleNameA'],
      qualifierA: json['qualifierA'],
      nicknameA: json['nicknameA'],
      citizenshipA: json['citizenshipA'],
      sexGenderA: json['sexGenderA'],
      civilStatusA: json['civilStatusA'],
      dateOfBirthA: json['dateOfBirthA'],
      ageA: json['ageA'] is int ? json['ageA'] : int.tryParse(json['ageA']?.toString() ?? ''),
      placeOfBirthA: json['placeOfBirthA'],
      homePhoneA: json['homePhoneA'],
      mobilePhoneA: json['mobilePhoneA'],
      currentAddressA: json['currentAddressA'],
      villageA: json['villageA'],
      regionA: json['regionA'],
      provinceA: json['provinceA'],
      townCityA: json['townCityA'],
      barangayA: json['barangayA'],
      otherAddressA: json['otherAddressA'],
      otherVillageA: json['otherVillageA'],
      otherRegionA: json['otherRegionA'],
      otherProvinceA: json['otherProvinceA'],
      otherTownCityA: json['otherTownCityA'],
      otherBarangayA: json['otherBarangayA'],
      highestEducationAttainmentA: json['highestEducationAttainmentA'],
      occupationA: json['occupationA'],
      idCardPresentedA: json['idCardPresentedA'],
      emailAddressA: json['emailAddressA'],
      // Item B
      surnameB: json['surnameB'],
      firstNameB: json['firstNameB'],
      middleNameB: json['middleNameB'],
      qualifierB: json['qualifierB'],
      nicknameB: json['nicknameB'],
      citizenshipB: json['citizenshipB'],
      sexGenderB: json['sexGenderB'],
      civilStatusB: json['civilStatusB'],
      dateOfBirthB: json['dateOfBirthB'],
      ageB: json['ageB'] is int ? json['ageB'] : int.tryParse(json['ageB']?.toString() ?? ''),
      placeOfBirthB: json['placeOfBirthB'],
      homePhoneB: json['homePhoneB'],
      mobilePhoneB: json['mobilePhoneB'],
      currentAddressB: json['currentAddressB'],
      villageB: json['villageB'],
      regionB: json['regionB'],
      provinceB: json['provinceB'],
      townCityB: json['townCityB'],
      barangayB: json['barangayB'],
      otherAddressB: json['otherAddressB'],
      otherVillageB: json['otherVillageB'],
      otherRegionB: json['otherRegionB'],
      otherProvinceB: json['otherProvinceB'],
      otherTownCityB: json['otherTownCityB'],
      otherBarangayB: json['otherBarangayB'],
      highestEducationAttainmentB: json['highestEducationAttainmentB'],
      occupationB: json['occupationB'],
      workAddressB: json['workAddressB'],
      emailAddressB: json['emailAddressB'],
      // Narrative
      narrative: json['narrative'],
      typeOfIncidentD: json['typeOfIncidentD'],
      dateTimeIncidentD: _parseDate(json['dateTimeIncidentD']),
      placeOfIncidentD: json['placeOfIncidentD'],
      // Metadata
      status: json['status'],
      userId: json['userId'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
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
      'documentId': documentId,
      'typeOfIncident': typeOfIncident,
      'copyFor': copyFor,
      'dateTimeReported': dateTimeReported != null ? Timestamp.fromDate(dateTimeReported!) : null,
      'dateTimeIncident': dateTimeIncident != null ? Timestamp.fromDate(dateTimeIncident!) : null,
      'placeOfIncident': placeOfIncident,
      // Item A
      'surnameA': surnameA,
      'firstNameA': firstNameA,
      'middleNameA': middleNameA,
      'qualifierA': qualifierA,
      'nicknameA': nicknameA,
      'citizenshipA': citizenshipA,
      'sexGenderA': sexGenderA,
      'civilStatusA': civilStatusA,
      'dateOfBirthA': dateOfBirthA,
      'ageA': ageA,
      'placeOfBirthA': placeOfBirthA,
      'homePhoneA': homePhoneA,
      'mobilePhoneA': mobilePhoneA,
      'currentAddressA': currentAddressA,
      'villageA': villageA,
      'regionA': regionA,
      'provinceA': provinceA,
      'townCityA': townCityA,
      'barangayA': barangayA,
      'otherAddressA': otherAddressA,
      'otherVillageA': otherVillageA,
      'otherRegionA': otherRegionA,
      'otherProvinceA': otherProvinceA,
      'otherTownCityA': otherTownCityA,
      'otherBarangayA': otherBarangayA,
      'highestEducationAttainmentA': highestEducationAttainmentA,
      'occupationA': occupationA,
      'idCardPresentedA': idCardPresentedA,
      'emailAddressA': emailAddressA,
      // Item B
      'surnameB': surnameB,
      'firstNameB': firstNameB,
      'middleNameB': middleNameB,
      'qualifierB': qualifierB,
      'nicknameB': nicknameB,
      'citizenshipB': citizenshipB,
      'sexGenderB': sexGenderB,
      'civilStatusB': civilStatusB,
      'dateOfBirthB': dateOfBirthB,
      'ageB': ageB,
      'placeOfBirthB': placeOfBirthB,
      'homePhoneB': homePhoneB,
      'mobilePhoneB': mobilePhoneB,
      'currentAddressB': currentAddressB,
      'villageB': villageB,
      'regionB': regionB,
      'provinceB': provinceB,
      'townCityB': townCityB,
      'barangayB': barangayB,
      'otherAddressB': otherAddressB,
      'otherVillageB': otherVillageB,
      'otherRegionB': otherRegionB,
      'otherProvinceB': otherProvinceB,
      'otherTownCityB': otherTownCityB,
      'otherBarangayB': otherBarangayB,
      'highestEducationAttainmentB': highestEducationAttainmentB,
      'occupationB': occupationB,
      'workAddressB': workAddressB,
      'emailAddressB': emailAddressB,
      // Narrative
      'narrative': narrative,
      'typeOfIncidentD': typeOfIncidentD,
      'dateTimeIncidentD': dateTimeIncidentD != null ? Timestamp.fromDate(dateTimeIncidentD!) : null,
      'placeOfIncidentD': placeOfIncidentD,
      // Metadata
      'status': status,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
