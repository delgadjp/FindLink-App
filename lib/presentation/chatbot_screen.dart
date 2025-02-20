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
        title: Text("Chat with us"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
          // FAQ Section (Without the Divider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Frequently Asked Questions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: faqs.map((faq) {
                    return GestureDetector(
                      onTap: () => sendMessage(faq["question"]!),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          faq["question"]!,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Input Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color:
                const Color.fromARGB(255, 255, 255, 255), // No background color to avoid a divider effect
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue.shade900),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.shade900 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
