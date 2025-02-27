import 'package:flutter/material.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';

class CustomPhilippineRegionDropdown extends StatelessWidget {
  final Region? value;
  final Function(Region?) onChanged;
  static const String dropdownPlaceholder = 'SELECT';

  const CustomPhilippineRegionDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color.fromARGB(255, 188, 188, 188),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: TextTheme(
            titleMedium: TextStyle(color: Colors.black, fontSize: 13),
            bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
            bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (value == null)
                Text(
                  dropdownPlaceholder,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: Colors.black,
                  ),
                  textTheme: TextTheme(
                    titleMedium: TextStyle(color: Colors.black, fontSize: 13),
                    bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
                    bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PhilippineRegionDropdownView(
                        value: value,
                        onChanged: onChanged,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomPhilippineProvinceDropdown extends StatelessWidget {
  final Province? value;
  final List<Province> provinces;
  final Function(Province?) onChanged;
  static const String dropdownPlaceholder = 'SELECT';

  const CustomPhilippineProvinceDropdown({
    Key? key,
    required this.value,
    required this.provinces,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color.fromARGB(255, 188, 188, 188),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: TextTheme(
            titleMedium: TextStyle(color: Colors.black, fontSize: 13),
            bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
            bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (value == null)
                Text(
                  dropdownPlaceholder,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: Colors.black,
                  ),
                  textTheme: TextTheme(
                    titleMedium: TextStyle(color: Colors.black, fontSize: 13),
                    bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
                    bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PhilippineProvinceDropdownView(
                        value: value,
                        provinces: provinces,
                        onChanged: onChanged,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomPhilippineMunicipalityDropdown extends StatelessWidget {
  final Municipality? value;
  final List<Municipality> municipalities;
  final Function(Municipality?) onChanged;
  static const String dropdownPlaceholder = 'SELECT';

  const CustomPhilippineMunicipalityDropdown({
    Key? key,
    required this.value,
    required this.municipalities,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color.fromARGB(255, 188, 188, 188),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: TextTheme(
            titleMedium: TextStyle(color: Colors.black, fontSize: 13),
            bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
            bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (value == null)
                Text(
                  dropdownPlaceholder,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: Colors.black,
                  ),
                  textTheme: TextTheme(
                    titleMedium: TextStyle(color: Colors.black, fontSize: 13),
                    bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
                    bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PhilippineMunicipalityDropdownView(
                        value: value,
                        municipalities: municipalities,
                        onChanged: onChanged,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomPhilippineBarangayDropdown extends StatelessWidget {
  final String? value;
  final List<String> barangays;
  final Function(String?) onChanged;
  static const String dropdownPlaceholder = 'SELECT';

  const CustomPhilippineBarangayDropdown({
    Key? key,
    required this.value,
    required this.barangays,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color.fromARGB(255, 188, 188, 188),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: TextTheme(
            titleMedium: TextStyle(color: Colors.black, fontSize: 13),
            bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
            bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (value == null)
                Text(
                  dropdownPlaceholder,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: Colors.black,
                  ),
                  textTheme: TextTheme(
                    titleMedium: TextStyle(color: Colors.black, fontSize: 13),
                    bodyLarge: TextStyle(color: Colors.black, fontSize: 13),
                    bodyMedium: TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PhilippineBarangayDropdownView(
                        value: value,
                        barangays: barangays,
                        onChanged: onChanged,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
