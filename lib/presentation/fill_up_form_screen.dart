import '/core/app_export.dart';

class FillUpFormScreen extends StatefulWidget {
  const FillUpFormScreen({Key? key}) : super(key: key);

  @override
  FillUpForm createState() => FillUpForm();
}

class FillUpForm extends State<FillUpFormScreen> {
  bool hasOtherAddress = false;
  bool hasPreviousCriminalRecord = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Fill Up Form",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D47A1),
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 900),
              padding: EdgeInsets.all(16),   
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      SizedBox(height: 20),
                      Text(
                        "Philippine National Police",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "INCIDENT RECORD FORM",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(
                        color: const Color.fromARGB(255, 214, 214, 214),
                        thickness: 1,
                      ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Form Section
                  Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: const Color.fromARGB(255, 243, 243, 243), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "INSTRUCTIONS: Refer to PNP SOP on ‘Recording of Incidents in the Police Blotter’ in filling up this form. This incident Record Form(IRF) may be reproduced, photocopied, and/or downloaded from the DIDM website, www.didm.pnp.gov.ph.",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildRowInputs(["IRF ENTRY NUMBER", "TYPE OF INCIDENT", "COPY FOR"]),
                        SizedBox(height: 10),
                         
                        _buildRowInputs(["DATE AND TIME REPORTED", "DATE AND TIME OF INCIDENT", "PLACE OF INCIDENT"]),
                        SizedBox(height: 10),

                        Container(
                          color: const Color.fromARGB(255, 30, 33, 90), // Background color
                          padding: EdgeInsets.all(8), // Optional padding
                          child: _buildSectionTitle(
                          'ITEM "A" - REPORTING PERSON', Colors.transparent),
                        ),

                        SizedBox(height: 10),

                        _buildRowInputs(["FAMILY NAME", "FIRST NAME", "MIDDLE NAME"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["QUALIFIER", "NICKNAME"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["CITIZENSHIP", "SEX/GENDER", "CIVIL STATUS"]),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DATE OF BIRTH",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () async {
                                        DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(1950),
                                          lastDate: DateTime.now(),
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            // Update your state with the selected date
                                          });
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "AGE",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    DropdownButtonFormField<int>(
                                      items: List.generate(100, (index) => index + 1)
                                          .map((age) => DropdownMenuItem(
                                                value: age,
                                                child: Text(
                                                  age.toString(),
                                                  style: TextStyle(fontSize: 8),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          // Update your state with the selected age
                                        });
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.black),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PLACE OF BIRTH",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.black),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        _buildRowInputs(["HOME PHONE", "MOBILE PHONE"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["CURRENT ADDRESS (HOUSE NUMBER/STREET)"]),
                        SizedBox(height: 10),
                          _buildRowInputs(["VILLAGE/SITIO"]),
                          SizedBox(height: 10),
                          _buildRowInputs(["BARANGAY", "TOWN/CITY", "PROVINCE"]),
                          SizedBox(height: 10),


 CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)), // Change text color to black
                          value: hasOtherAddress,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddress = value ?? false;
                            });
                          },
                        ),
                        if (hasOtherAddress) ...[
                          _buildRowInputs(["OTHER ADDRESS (HOUSE NUMBER/STREET)"]),
                            SizedBox(height: 10),
                          _buildRowInputs(["VILLAGE/SITIO"]),
                          SizedBox(height: 10),
                          _buildRowInputs(["BARANGAY", "TOWN/CITY", "PROVINCE"]),
                          SizedBox(height: 10),
                        ],


                          SizedBox(height: 10),
                          _buildRowInputs(["HIGHEST EDUCATION ATTAINMENT", "OCCUPATION"]),
                         SizedBox(height: 10),
                          _buildRowInputs(["ID CARD PRESENTED", "EMAIL ADDRESS (If Any)"]),
                          SizedBox(height: 10),


                        _buildSectionTitle('ITEM "B" - SUSPECT DATA', Color(0xFF1E215A)),
                        SizedBox(height: 10),

                        _buildRowInputs(["FAMILY NAME", "FIRST NAME", "MIDDLE NAME"]),
                        SizedBox(height: 10),
                         _buildRowInputs(["QUALIFIER", "NICKNAME"]),
                        SizedBox(height: 10),
                         _buildRowInputs(["CITIZENSHIP", "SEX/GENDER", "CIVIL STATUS"]),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      
                                      "DATE OF BIRTH",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(1950),
                                          lastDate: DateTime.now(),
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            // Update your state with the selected date
                                          });
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "AGE",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    DropdownButtonFormField<int>(
                                      items: List.generate(100, (index) => index + 1)
                                          .map((age) => DropdownMenuItem(
                                                value: age,
                                                child: Text(
                                                  age.toString(),
                                                  style: TextStyle(fontSize: 8),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          // Update your state with the selected age
                                        });
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.black),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PLACE OF BIRTH",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextField(
                                      style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.black),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                                                SizedBox(height: 10),

                        _buildRowInputs(["HOME PHONE", "MOBILE PHONE"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["CURRENT ADDRESS (HOUSE NUMBER/STREET)"]),
                        SizedBox(height: 10),
                          _buildRowInputs(["VILLAGE/SITIO"]),
                          SizedBox(height: 10),
                          _buildRowInputs(["BARANGAY", "TOWN/CITY", "PROVINCE"]),
                          SizedBox(height: 10),

                          CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)), // Change text color to black
                          value: hasOtherAddress,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddress = value ?? false;
                            });
                          },
                        ),
                        if (hasOtherAddress) ...[
                          _buildRowInputs(["OTHER ADDRESS (HOUSE NUMBER/STREET)"]),
                            SizedBox(height: 10),
                          _buildRowInputs(["VILLAGE/SITIO"]),
                          SizedBox(height: 10),
                          _buildRowInputs(["BARANGAY", "TOWN/CITY", "PROVINCE"]),
                          SizedBox(height: 10),
                        ],

                       

                        _buildRowInputs(["HIGHEST EDUCATION ATTAINMENT", "OCCUPATION"]),
                         SizedBox(height: 10),
                        _buildRowInputs(["WORK ADDRESS"]),
                         SizedBox(height: 10),
                        _buildRowInputs(["RELATION TO VICTIM", "EMAIL ADDRESS (If Any)"]),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          SizedBox(height: 10),
                            Text(
                              "WITH PREVIOUS CRIMINAL CASE RECORD?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: hasPreviousCriminalRecord,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      hasPreviousCriminalRecord = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  "Yes",
                                  style: TextStyle(fontSize: 8, color: Colors.black),
                                ),
                                Radio<bool>(
                                  value: false,
                                  groupValue: hasPreviousCriminalRecord,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      hasPreviousCriminalRecord = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  "No",
                                  style: TextStyle(fontSize: 8, color: Colors.black),
                                ),
                              ],
                            ),
                            if (hasPreviousCriminalRecord)
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Specify Previous Criminal Case Record",
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        _buildRowInputs(["STATUS OF PREVIOUS CASE"]),
                         SizedBox(height: 10),
                        _buildRowInputs(["HEIGHT", "WEIGHT", "BUILT"]),
                         SizedBox(height: 10),
                        _buildRowInputs(["COLOR OF EYES", "DESCRIPTION OF EYES"]),
                         SizedBox(height: 10),
                        _buildRowInputs(["COLOR OF HAIR", "DESCRIPTION OF HAIR"]),
                         SizedBox(height: 10),
                        UnderInfluenceCheckboxes(),
                         SizedBox(height: 10),


                        _buildSectionTitle('FOR CHILDREN IN CONFLICT WITH LAW', const Color.fromARGB(255, 30, 33, 90)),
                         SizedBox(height: 10),
                        _buildRowInputs(["NAME OF GUARDIAN"]),
                        SizedBox(height: 10),
                          _buildRowInputs(["GUARDIAN ADDRESS"]),
                        SizedBox(height: 10),
                          _buildRowInputs(["HOME PHONE","MOBILE PHONE"]),
                        SizedBox(height: 10),



                        _buildSectionTitle('ITEM "C" - VICTIM DATA', const Color.fromARGB(255, 30, 33, 90)),
                        SizedBox(height: 10),
                       _buildRowInputs(["FAMILY NAME", "FIRST NAME", "MIDDLE NAME"]),
                        SizedBox(height: 10),
                         _buildRowInputs(["QUALIFIER", "NICKNAME"]),
                        SizedBox(height: 10),
                         _buildRowInputs(["CITIZENSHIP", "SEX/GENDER", "CIVIL STATUS"]),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DATE OF BIRTH",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(1950),
                                          lastDate: DateTime.now(),
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            // Update your state with the selected date
                                          });
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.black),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "AGE",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    DropdownButtonFormField<int>(
                                      items: List.generate(100, (index) => index + 1)
                                          .map((age) => DropdownMenuItem(
                                                value: age,
                                                child: Text(
                                                  age.toString(),
                                                  style: TextStyle(fontSize: 8),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          // Update your state with the selected age
                                        });
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.black),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PLACE OF BIRTH",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    TextField(
                                      style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.black),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                                                SizedBox(height: 10),

                        _buildRowInputs(["HOME PHONE", "MOBILE PHONE"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["CURRENT ADDRESS (HOUSE NUMBER/STREET)"]),
                        SizedBox(height: 10),
                          _buildRowInputs(["VILLAGE/SITIO"]),
                          SizedBox(height: 10),
                          _buildRowInputs(["BARANGAY", "TOWN/CITY", "PROVINCE"]),
                          SizedBox(height: 10),

                          CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)), // Change text color to black
                          value: hasOtherAddress,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddress = value ?? false;
                            });
                          },
                        ),
                        if (hasOtherAddress) ...[
                          _buildRowInputs(["OTHER ADDRESS (HOUSE NUMBER/STREET)"]),
                            SizedBox(height: 10),
                          _buildRowInputs(["VILLAGE/SITIO"]),
                          SizedBox(height: 10),
                          _buildRowInputs(["BARANGAY", "TOWN/CITY", "PROVINCE"]),
                          SizedBox(height: 10),
                        ],

                       

                        _buildRowInputs(["HIGHEST EDUCATION ATTAINMENT", "OCCUPATION"]),
                         SizedBox(height: 10),
                        _buildRowInputs(["WORK ADDRESS", "EMAIL ADDRESS (If Any)"]),
                         SizedBox(height: 10),
            


                        _buildSectionTitle('ITEM "D" - NARRATIVE OF INCIDENT', const Color.fromARGB(255, 30, 33, 90)),
                        SizedBox(height: 10),
                        _buildRowInputs(["TYPE OF INCIDENT", "DATE/TIME OF INCIDENT", "PLACE OF INCIDENT"]),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            "ENTER IN DETAIL THE NARRATIVE OF INCIDENT OR EVENT, ANSWERING THE WHO, WHAT, WHEN, WHERE, WHY AND HOW OF REPORTING",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                              color: Colors.black,
                            ),
                            ),
                            SizedBox(height: 4),
                            TextField(
                            maxLines: 10, // Set max lines to make it a textarea
                            style: TextStyle(fontSize: 15, color: Colors.black), // Set text color to black
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.black),
                              ),
                              contentPadding: EdgeInsets.all(8),
                            ),
                            ),
                          ],
                          ),
                        ),
                        SizedBox(height: 10),

                       Container(
                          color: const Color.fromARGB(255, 160, 173, 242), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "I HEREBY CERTIFY TO THE CORRECTNESS OF THE FOREGOING TO THE BEST OF MY KNOWLEDGE AND BELIEF.",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),


                        SizedBox(height: 10),
                        _buildRowInputs(["NAME OF REPORTING PERSON", "SIGNATURE OF REPORTING PERSON"]),
                        SizedBox(height: 10),

                          Container(
                          color: const Color.fromARGB(255, 160, 173, 242), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "SUBSCRIBED AND SWORN TO BEFORE ME",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        _buildRowInputs(["NAME OF ADMINISTERING OFFICER(DUTY OFFICER)", "SIGNATURE OF ADMINISTERING OFFICER(DUTY OFFICER)"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["RANK, NAME AND DESIGNATION OF POLICE OFFICER (WHETHER HE/SHE IS THE DUTY INVESTIGATOR, INVESTIGATOR ON CASE OR THE ASSISTING POLICE OFFICER)"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["SIGNATURE OF DUTY INVESTIGATOR/ INVESTIGATOR ON CASE/ ASSISTING POLICE OFFICER"]),
                        SizedBox(height: 10),

                        
                            Container(
                          color: const Color.fromARGB(255, 160, 173, 242), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "INCIDENT RECORDED IN THE BLOTTER BY:",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        _buildRowInputs(["RANK/NAME OF DESK OFFICER:"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["SIGNATURE OF DESK OFFICER:", "BLOTTER ENTRY NR:"]),
                        SizedBox(height: 10),
                        Container(
                          color: const Color.fromARGB(255, 243, 243, 243), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "REMINDER TO REPORTING PERSON: Keep the copy of this Incident Record Form (IRF). An update of the progress of the investigation of the crime or incident that you reported will be given to you upon presentation of this IRF. For your reference, the data below is the contact details of this police station.",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                      
                        ),
                      
                    
                        SizedBox(height: 10),
                        _buildRowInputs(["Name of Police Station", "Telephone"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["Investigator-on-Case", "Mobile Phone"]),
                        SizedBox(height: 10),
                        _buildRowInputs(["Name of Chief/Head of Office", "Mobile Phone"]),
                        SizedBox(height: 20),
                        ActionButtons(), // Move ActionButtons here
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildInputField(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            TextField(
              style: TextStyle(fontSize: 15, color: Colors.black), // Set text color to black
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
               
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 188, 188, 188)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 205, 205, 205)), // Change border color when focused
                ),
                contentPadding: EdgeInsets.all(4), // Adjust content padding to match font size
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            TextField(
              style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 0, 0, 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 4), // Adjust content padding to decrease height
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowInputs(List<String> labels) {
    return Row(
      children: labels.map((label) => _buildInputField(label)).toList(),
    );
  }

  Widget _buildSectionTitle(String title, Color bgColor) {
    return Container(
      color: bgColor,
      padding: EdgeInsets.all(8),
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

class UnderInfluenceCheckboxes extends StatefulWidget {
  @override
  _UnderInfluenceCheckboxesState createState() => _UnderInfluenceCheckboxesState();
}

class _UnderInfluenceCheckboxesState extends State<UnderInfluenceCheckboxes> {
  bool no = false;
  bool drugs = false;
  bool liquor = false;
  bool others = false;
  TextEditingController othersController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UNDER THE INFLUENCE?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10, // Slightly larger for clarity
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            _buildCheckbox("NO", no, (value) {
              setState(() {
                no = value!;
                if (no) {
                  // If "NO" is checked, uncheck all others
                  drugs = false;
                  liquor = false;
                  others = false;
                  othersController.clear(); // Clear text field if Others was selected
                }
              });
            }),
            _buildCheckbox("DRUGS", drugs, (value) {
              setState(() {
                drugs = value!;
                if (drugs) no = false; // Uncheck "NO" if any option is selected
              });
            }),
            _buildCheckbox("LIQUOR", liquor, (value) {
              setState(() {
                liquor = value!;
                if (liquor) no = false;
              });
            }),
            _buildCheckbox("OTHERS", others, (value) {
              setState(() {
                others = value!;
                if (others) {
                  no = false; // Uncheck "NO" if "OTHERS" is selected
                } else {
                  othersController.clear(); // Clear input when unchecked
                }
              });
            }),
          ],
        ),
        if (others) // Show text field only when "OTHERS" is checked
          Padding(
            padding: const EdgeInsets.only(left: 32.0, top: 8.0),
            child: TextField(
              controller: othersController,
              decoration: InputDecoration(
                labelText: "Specify Other Influences",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          activeColor: Colors.blue,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.black),
        ),
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Make buttons symmetrical
        children: [
          _buildButton("Send Report", const Color.fromARGB(255, 30, 33, 90)),
          _buildButton("Discard", const Color.fromARGB(255, 234, 103, 94)),
          _buildButton("Save Draft", const Color.fromARGB(255, 174, 174, 174)),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8), // Smaller padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {},
      child: Text(label, style: TextStyle(fontSize: 14)), // Smaller font size
    );
  }
}

