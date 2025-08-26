
import '/core/app_export.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class FAQScreen extends StatefulWidget {
  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, String>> faqs = [
    {
      "question": "How do I report a missing person?",
      "answer": "To report a missing person, tap 'INCIDENT RECORD FORM' on the home screen. Fill out the detailed form with all required information about the missing person, including personal details, physical description, last known location, and upload a recent photo. Your report will be sent to the PNP for review and processing."
    },
    {
      "question": "How do I track my case?",
      "answer": "Go to your 'PROFILE' screen and view your submitted cases. You can see the status of each case, from 'Reported' to 'Under Investigation' to 'Resolved'. Each case shows progress steps and you can view the generated PDF of your report."
    },
    {
      "question": "How do I view missing persons in my area?",
      "answer": "Tap 'VIEW MISSING PERSON' on the home screen to see all reported missing persons. You can search by name, filter by date, and sort by most recent cases. Each listing shows the person's photo, description, and last known location."
    },
    {
      "question": "Can I report a sighting of a missing person?",
      "answer": "Yes! When viewing a missing person's details, tap 'Report a Sighting' to submit information about where and when you saw them. Include as much detail as possible about the location, time, and circumstances of the sighting."
    },
    {
      "question": "What is the FindMe feature?",
      "answer": "FindMe is a location tracking feature that allows family members to share their real-time location with trusted contacts. When enabled, your location is tracked in the background and can be accessed by designated family members or authorities if you're reported missing."
    },
    {
      "question": "How do I enable family location sharing?",
      "answer": "Go to your Profile, tap 'FindMe Settings', and enable the feature. You can add trusted contacts, enable family sharing, and control who has access to your location. Family members with access can view your real-time location through the 'Find My Devices' feature."
    },
    {
      "question": "What information is required when reporting a missing person?",
      "answer": "You'll need to provide: personal details (name, age, gender, address), physical description (height, weight, hair/eye color), clothing last worn, circumstances of disappearance, last known location and time, recent photo, and your relationship to the missing person as the complainant."
    },
    {
      "question": "Is there a fee for using FindLink services?",
      "answer": "No, all FindLink services are completely free. The app is designed to help the community and law enforcement work together to locate missing persons at no cost to users."
    },
    {
      "question": "How does FindLink work with the PNP?",
      "answer": "FindLink collaborates directly with the Philippine National Police (PNP). Your incident reports are sent to PNP administrators who can create official Missing Person Alarm Sheets (MPAS) and coordinate search efforts. This ensures your report reaches the proper authorities quickly."
    },
  ];

  Future<void> _callPNPHotline() async {
    const phoneNumber = '117'; // Changed to official PNP emergency hotline
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');

    // Request phone call permission
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      try {
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(
            phoneUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Device cannot make phone calls')),
            );
          }
        }
      } catch (e) {
        print('Error launching phone call: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to launch phone dialer')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied for phone calls')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Frequently Asked Questions",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: 20),
        ),
        backgroundColor: Color(0xFF0D47A1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100,],
            stops: [0.0, 50],
          ),
        ),
        child: Column(
          children: [
            // Header Section - Changed text color
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                "Find answers to commonly asked questions about FindLink and missing person reports",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white, // Changed from Colors.grey[700] to app's primary color
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // FAQ List
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        return FAQItem(
                          question: faqs[index]["question"]!,
                          answer: faqs[index]["answer"]!,
                        );
                      },
                    ),
                  ),
                  // Emergency Contact Section
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emergency,
                              color: Colors.red,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Emergency Contact",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          "For immediate assistance or emergency situations",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _callPNPHotline,
                          icon: Icon(Icons.phone, color: Colors.white),
                          label: Text(
                            "Call PNP Hotline (117)",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({
    Key? key,
    required this.question,
    required this.answer,
  }) : super(key: key);

  @override
  _FAQItemState createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue.shade50, // Added to match home screen cards
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: Column(
          children: [
            // Question section
            InkWell(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D47A1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.question_mark,
                        color: Color(0xFF0D47A1),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            
            // Answer section
            AnimatedCrossFade(
              firstChild: Container(height: 0),
              secondChild: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.announcement_outlined,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.answer,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}
