import '/core/app_export.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final List<String>? dropdownItems;
  final TextEditingController? controller;
  final bool? readOnly;
  final VoidCallback? onTap;
  final Function(String?)? onChanged;
  final String? value;
  final String dropdownPlaceholder;

  const CustomInputField({
    Key? key,
    required this.label,
    this.isRequired = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.dropdownItems,
    this.controller,
    this.readOnly,
    this.onTap,
    this.onChanged,
    this.value,
    this.dropdownPlaceholder = 'SELECT',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 35,
              child: Row(
                children: [
                  if (isRequired)
                    Text(
                      '* ',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Expanded(
                    child: Tooltip(
                      message: label,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 35,
              child: dropdownItems != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return DropdownButtonFormField<String>(
                          value: value ?? dropdownPlaceholder,
                          items: dropdownItems!.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              enabled: value != dropdownPlaceholder,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: constraints.maxWidth < 200 ? 12 : 14,
                                  color: value == dropdownPlaceholder
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != dropdownPlaceholder) {
                              onChanged?.call(newValue);
                            }
                          },
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 200 ? 12 : 14,
                            color: Colors.black,
                          ),
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 188, 188, 188)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 205, 205, 205)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            isDense: true,
                          ),
                          isExpanded: true,
                        );
                      },
                    )
                  : GestureDetector(
                      onTap: onTap,
                      child: AbsorbPointer(
                        absorbing: onTap != null,
                        child: TextFormField(
                          controller: controller,
                          readOnly: readOnly ?? false,
                          keyboardType: keyboardType,
                          inputFormatters: inputFormatters,
                          validator: validator,
                          style: TextStyle(fontSize: 13, color: Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 188, 188, 188)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 205, 205, 205)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            isDense: true,
                            errorStyle: TextStyle(height: 0),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
