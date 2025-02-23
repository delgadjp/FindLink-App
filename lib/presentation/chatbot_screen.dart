import '../core/app_export.dart';
class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [
    {"text": "Hello! How can we assist you today?", "sender": "bot"}
  ];

  final List<Map<String, String>> faqs = [
    {
      "question": "How do I report a missing person?",
      "answer": "FILL UP THE IRF FORM (Incident Report Form)."
    },
    {
      "question": "How do I track a case?",
      "answer": "You can track your case through CASE TRACKER."
    },
    {
      "question": "Can I submit a tip anonymously?",
      "answer": "Yes, use the 'Submit Anonymous Tip' option."
    },
    {
      "question": "What is FindLink?",
      "answer":
          "FindLink connects citizens with the police to report missing persons."
    },
  ];

  void sendMessage(String text) {
    if (text.isEmpty) return; // Prevent empty messages

    setState(() {
      messages.add({"text": text, "sender": "user"});

      // Check if the user's message matches an FAQ
      String botResponse = "I'm sorry, I didn't understand that.";
      for (var faq in faqs) {
        if (faq["question"]!.toLowerCase() == text.toLowerCase()) {
          botResponse = faq["answer"]!;
          break;
        }
      }

      messages.add({"text": botResponse, "sender": "bot"});
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, color: Colors.blue.shade900),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("FindLink Assistant",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          image: DecorationImage(
            image: AssetImage("assets/chat_bg.png"), // Add a subtle pattern
            opacity: 0.1,
          ),
        ),
        child: Column(
          children: [
            // Enhanced Chat List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  bool isUser = messages[index]["sender"] == "user";
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: MessageBubble(
                      text: messages[index]["text"] ?? "Error",
                      isUser: isUser,
                    ),
                  );
                },
              ),
            ),

            // Enhanced FAQ Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, 
                           color: Colors.blue.shade900, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Quick Questions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  Wrap(
                    spacing: 8,
                    children: faqs.map((faq) => ActionChip(
                      label: Text(faq["question"]!),
                      onPressed: () => sendMessage(faq["question"]!),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade900),
                    )).toList(),
                  ),
                ],
              ),
            ),

            // Enhanced Message Input
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: sendMessage,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: () => sendMessage(_controller.text),
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

