import '/core/app_export.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';

class FormRowInputs extends StatelessWidget {
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> formState;
  final Function(String, dynamic) onFieldChange;

  const FormRowInputs({
    Key? key,
    required this.fields,
    required this.formState,
    required this.onFieldChange,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: fields.map((field) {
        final fieldKey = field['key'] as Key?; // Extract the key

        // Handle specialized address fields
        if (field['section'] != null && field['label'] == 'REGION') {
          return _buildRegionField(field, fieldKey);
        } else if (field['section'] != null && field['label'] == 'PROVINCE') {
          return _buildProvinceField(field, fieldKey);
        } else if (field['section'] != null && field['label'] == 'TOWN/CITY') {
          return _buildMunicipalityField(field, fieldKey);
        } else if (field['section'] != null && field['label'] == 'BARANGAY') {
          return _buildBarangayField(field, fieldKey);
        }
        
        // Handle specialized education and occupation fields
        else if (field['label'] == 'HIGHEST EDUCATION ATTAINMENT') {
          return _buildEducationField(field, fieldKey);
        } else if (field['label'] == 'OCCUPATION') {
          return _buildOccupationField(field, fieldKey);
        } else if (field['label'] == 'CITIZENSHIP') {
          return _buildCitizenshipField(field, fieldKey);
        } else if (field['label'] == 'CIVIL STATUS') {
          return _buildCivilStatusField(field, fieldKey);
        }        // Handle standard fields
        return CustomInputField(
          key: fieldKey, // Pass the extracted key to the CustomInputField
          label: field['label'] ?? '',
          isRequired: field['required'] ?? false,
          keyboardType: field['keyboardType'],
          inputFormatters: field['inputFormatters'],
          validator: field['validator'],
          dropdownItems: field['dropdownItems'],
          controller: field['controller'],
          readOnly: field['readOnly'] ?? false,
          onTap: field['onTap'],
          onChanged: field['onChanged'],
          value: field['value'],
          hintText: field['hintText'],
        );
      }).toList(),
    );
  }  Widget _buildRegionField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final regionKey = section == 'reportingOther' ? 'reportingOtherRegion' : section == 'victimOther' ? 'victimOtherRegion' : '${section}Region';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineRegionDropdown(
              key: key, // Pass key to the dropdown
              value: formState[regionKey],
              onChanged: (Region? value) => onFieldChange(regionKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final provinceKey = section == 'reportingOther' ? 'reportingOtherProvince' : section == 'victimOther' ? 'victimOtherProvince' : '${section}Province';
    final regionKey = section == 'reportingOther' ? 'reportingOtherRegion' : section == 'victimOther' ? 'victimOtherRegion' : '${section}Region';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineProvinceDropdown(
              value: formState[provinceKey],
              provinces: (formState[regionKey] as Region?)?.provinces ?? [],
              onChanged: (Province? value) => onFieldChange(provinceKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMunicipalityField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final municipalityKey = section == 'reportingOther' ? 'reportingOtherMunicipality' : section == 'victimOther' ? 'victimOtherMunicipality' : '${section}Municipality';
    final provinceKey = section == 'reportingOther' ? 'reportingOtherProvince' : section == 'victimOther' ? 'victimOtherProvince' : '${section}Province';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineMunicipalityDropdown(
              value: formState[municipalityKey],
              municipalities: (formState[provinceKey] as Province?)?.municipalities ?? [],
              onChanged: (Municipality? value) => onFieldChange(municipalityKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarangayField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final barangayKey = section == 'reportingOther' ? 'reportingOtherBarangay' : section == 'victimOther' ? 'victimOtherBarangay' : '${section}Barangay';
    final municipalityKey = section == 'reportingOther' ? 'reportingOtherMunicipality' : section == 'victimOther' ? 'victimOtherMunicipality' : '${section}Municipality';
    return Expanded(
      key: key, // Apply the key here
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '* ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  field['label'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            CustomPhilippineBarangayDropdown(
              value: formState[barangayKey],
              barangays: (formState[municipalityKey] as Municipality?)?.barangays ?? [],
              onChanged: (String? value) => onFieldChange(barangayKey, value),
            ),
          ],
        ),
      ),
    );
  }Widget _buildEducationField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final educationKey = '${section}Education';
    final educationOptions = field['dropdownItems'] ?? [];
    
    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: educationOptions,
      controller: field['controller'],
      value: formState[educationKey],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select education level';
        }
        return null;
      },
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        onFieldChange(educationKey, value);
      },
    );
  }  Widget _buildOccupationField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final occupationKey = '${section}Occupation';
    final occupationOptions = field['dropdownItems'] ?? [];
    
    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: occupationOptions,
      controller: field['controller'],
      value: formState[occupationKey],
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        onFieldChange(occupationKey, value);
      },
    );
  }  Widget _buildCitizenshipField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String;
    final citizenshipKey = '${section}Citizenship';
    final citizenshipOptions = field['dropdownItems'] ?? [];

    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: citizenshipOptions,
      controller: field['controller'],
      value: formState[citizenshipKey],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select citizenship';
        }
        return null;
      },
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        onFieldChange(citizenshipKey, value);
      },
    );
  }  Widget _buildCivilStatusField(Map<String, dynamic> field, Key? key) {
    final section = field['section'] as String?;
    String? civilStatusKey;
    if (section == 'reporting') {
      civilStatusKey = 'reportingPersonCivilStatus';
    } else if (section == 'victim') {
      civilStatusKey = 'victimCivilStatus';
    }
    final civilStatusOptions = field['dropdownItems'] ?? [];
    return CustomInputField(
      key: key, // Pass the key
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: civilStatusOptions,
      controller: field['controller'],
      value: civilStatusKey != null ? formState[civilStatusKey] : null,
      validator: (value) {
        if ((field['required'] ?? false) && (value == null || value.isEmpty)) {
          return 'Please select civil status';
        }
        return null;
      },
      onChanged: (value) {
        if (field['controller'] != null) {
          field['controller'].text = value ?? '';
        }
        if (civilStatusKey != null) {
          onFieldChange(civilStatusKey == 'reportingPersonCivilStatus' ? 'civilStatusReporting' : 'civilStatusVictim', value);
        }
      },
    );
  }
}
