

class IRFModel {
  String? id;
  String? pdfUrl;
  String? status;
  String? userId;
  // Incident Details
  DateTime? createdAt;
  DateTime? dateTimeOfIncident;
  String? imageUrl;
  String? incidentId;
  String? narrative;
  String? placeOfIncident;
  DateTime? reportedAt;
  String? typeOfIncident;
  // Item A (Reporting Person)
  int? ageA;
  String? barangayA;
  String? citizenshipA;
  String? civilStatusA;
  String? currentAddressA;
  String? dateOfBirthA;
  String? educationA;
  String? emailA;
  String? familyNameA;
  String? firstNameA;
  String? homePhoneA;
  String? idCardA;
  String? middleNameA;
  String? mobilePhoneA;
  String? nicknameA;
  String? occupationA;
  String? otherAddressA;
  String? otherVillageA;
  String? otherRegionA;
  String? otherProvinceA;
  String? otherTownCityA;
  String? otherBarangayA;
  String? placeOfBirthA;
  String? provinceA;
  String? qualifierA;
  String? sexGenderA;
  String? townA;
  String? villageSitioA;
  // Item C (Victim)
  int? ageC;
  String? barangayC;
  String? citizenshipC;
  String? civilStatusC;
  String? currentAddressC;
  String? dateOfBirthC;
  String? educationC;
  String? emailC;
  String? familyNameC;
  String? firstNameC;
  String? homePhoneC;
  String? idCardC;
  String? middleNameC;
  String? mobilePhoneC;
  String? nicknameC;
  String? occupationC;
  String? otherAddressC;
  String? otherVillageC;
  String? otherRegionC;
  String? otherProvinceC;
  String? otherTownCityC;
  String? otherBarangayC;
  String? placeOfBirthC;
  String? provinceC;
  String? qualifierC;
  String? sexGenderC;
  String? townC;
  String? villageSitioC;

  IRFModel({
    this.id,
    this.pdfUrl,
    this.status,
    this.userId,
    // Incident Details
    this.createdAt,
    this.dateTimeOfIncident,
    this.imageUrl,
    this.incidentId,
    this.narrative,
    this.placeOfIncident,
    this.reportedAt,
    this.typeOfIncident,
    // Item A
    this.ageA,
    this.barangayA,
    this.citizenshipA,
    this.civilStatusA,
    this.currentAddressA,
    this.dateOfBirthA,
    this.educationA,
    this.emailA,
    this.familyNameA,
    this.firstNameA,
    this.homePhoneA,
    this.idCardA,
    this.middleNameA,
    this.mobilePhoneA,
    this.nicknameA,
    this.occupationA,
    this.otherAddressA,
    this.otherVillageA,
    this.otherRegionA,
    this.otherProvinceA,
    this.otherTownCityA,
    this.otherBarangayA,
    this.placeOfBirthA,
    this.provinceA,
    this.qualifierA,
    this.sexGenderA,
    this.townA,
    this.villageSitioA,
    // Item C
    this.ageC,
    this.barangayC,
    this.citizenshipC,
    this.civilStatusC,
    this.currentAddressC,
    this.dateOfBirthC,
    this.educationC,
    this.emailC,
    this.familyNameC,
    this.firstNameC,
    this.homePhoneC,
    this.idCardC,
    this.middleNameC,
    this.mobilePhoneC,
    this.nicknameC,
    this.occupationC,
    this.otherAddressC,
    this.otherVillageC,
    this.otherRegionC,
    this.otherProvinceC,
    this.otherTownCityC,
    this.otherBarangayC,
    this.placeOfBirthC,
    this.provinceC,
    this.qualifierC,
    this.sexGenderC,
    this.townC,
    this.villageSitioC,
  });

  Map<String, dynamic> toMap() {
    return {
      'incidentDetails': {
        'createdAt': createdAt,
        'dateTimeOfIncident': dateTimeOfIncident,
        'imageUrl': imageUrl,
        'incidentId': incidentId,
        'narrative': narrative,
        'placeOfIncident': placeOfIncident,
        'reportedAt': reportedAt,
        'typeOfIncident': typeOfIncident,
      },
      'itemA': {
        'age': ageA,
        'barangay': barangayA,
        'citizenship': citizenshipA,
        'civilStatus': civilStatusA,
        'currentAddress': currentAddressA,
        'dateOfBirth': dateOfBirthA,
        'education': educationA,
        'email': emailA,
        'familyName': familyNameA,
        'firstName': firstNameA,
        'homePhone': homePhoneA,
        'idCard': idCardA,
        'middleName': middleNameA,
        'mobilePhone': mobilePhoneA,
        'nickname': nicknameA,
        'occupation': occupationA,
        'otherAddress': otherAddressA,
        'otherVillage': otherVillageA,
        'otherRegion': otherRegionA,
        'otherProvince': otherProvinceA,
        'otherTownCity': otherTownCityA,
        'otherBarangay': otherBarangayA,
        'placeOfBirth': placeOfBirthA,
        'province': provinceA,
        'qualifier': qualifierA,
        'sexGender': sexGenderA,
        'town': townA,
        'villageSitio': villageSitioA,
      },
      'itemC': {
        'age': ageC,
        'barangay': barangayC,
        'citizenship': citizenshipC,
        'civilStatus': civilStatusC,
        'currentAddress': currentAddressC,
        'dateOfBirth': dateOfBirthC,
        'education': educationC,
        'email': emailC,
        'familyName': familyNameC,
        'firstName': firstNameC,
        'homePhone': homePhoneC,
        'idCard': idCardC,
        'middleName': middleNameC,
        'mobilePhone': mobilePhoneC,
        'nickname': nicknameC,
        'occupation': occupationC,
        'otherAddress': otherAddressC,
        'otherVillage': otherVillageC,
        'otherRegion': otherRegionC,
        'otherProvince': otherProvinceC,
        'otherTownCity': otherTownCityC,
        'otherBarangay': otherBarangayC,
        'placeOfBirth': placeOfBirthC,
        'province': provinceC,
        'qualifier': qualifierC,
        'sexGender': sexGenderC,
        'town': townC,
        'villageSitio': villageSitioC,
      },
      'pdfUrl': pdfUrl,
      'status': status,
      'userId': userId,
    }..removeWhere((k, v) => v == null);
  }
}
