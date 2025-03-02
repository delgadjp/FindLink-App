import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import '../custom_address_dropdowns.dart';
import 'custom_input_field.dart';

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
        // Handle specialized address fields
        if (field['section'] != null && field['label'] == 'REGION') {
          return _buildRegionField(field);
        } else if (field['section'] != null && field['label'] == 'PROVINCE') {
          return _buildProvinceField(field);
        } else if (field['section'] != null && field['label'] == 'TOWN/CITY') {
          return _buildMunicipalityField(field);
        } else if (field['section'] != null && field['label'] == 'BARANGAY') {
          return _buildBarangayField(field);
        }
        
        // Handle specialized education and occupation fields
        else if (field['label'] == 'HIGHEST EDUCATION ATTAINMENT') {
          return _buildEducationField(field);
        } else if (field['label'] == 'OCCUPATION') {
          return _buildOccupationField(field);
        }

        // Handle standard fields
        return CustomInputField(
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
        );
      }).toList(),
    );
  }

  Widget _buildRegionField(Map<String, dynamic> field) {
    final section = field['section'] as String;
    final regionKey = '${section}Region';
    
    return Expanded(
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
              value: formState[regionKey],
              onChanged: (Region? value) => onFieldChange(regionKey, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceField(Map<String, dynamic> field) {
    final section = field['section'] as String;
    final provinceKey = '${section}Province';
    final regionKey = '${section}Region';
    
    return Expanded(
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

  Widget _buildMunicipalityField(Map<String, dynamic> field) {
    final section = field['section'] as String;
    final municipalityKey = '${section}Municipality';
    final provinceKey = '${section}Province';
    
    return Expanded(
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

  Widget _buildBarangayField(Map<String, dynamic> field) {
    final section = field['section'] as String;
    final barangayKey = '${section}Barangay';
    final municipalityKey = '${section}Municipality';
    
    return Expanded(
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
  }

  Widget _buildEducationField(Map<String, dynamic> field) {
    final section = field['section'] as String;
    final educationKey = '${section}Education';
    final educationOptions = field['dropdownItems'] ?? [];
    
    return CustomInputField(
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: educationOptions,
      value: formState[educationKey],
      onChanged: (value) => onFieldChange(educationKey, value),
    );
  }

  Widget _buildOccupationField(Map<String, dynamic> field) {
    final section = field['section'] as String;
    final occupationKey = '${section}Occupation';
    final occupationOptions = field['dropdownItems'] ?? [];
    
    return CustomInputField(
      label: field['label'],
      isRequired: field['required'] ?? false,
      dropdownItems: occupationOptions,
      value: formState[occupationKey],
      onChanged: (value) => onFieldChange(occupationKey, value),
    );
  }
}
