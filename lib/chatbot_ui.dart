import 'dart:convert';
import 'package:bubble/bubble.dart';
import 'package:catai/api_key.dart';
import 'package:catai/message_info.dart';
import 'package:catai/system_messages.dart';
import 'package:catai/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UIScreen extends StatefulWidget {
  @override
  _UIScreenState createState() => _UIScreenState();
}

class _UIScreenState extends State<UIScreen> {
  final List<Message> _messages = [];

  final TextEditingController _textEditingController = TextEditingController();
  bool isTyping = false;
  void onSendMessage() async {
    Message message = Message(text: _textEditingController.text, isMe: true);

    _textEditingController.clear();

    setState(() {
      isTyping = true;
      _messages.insert(0, message);
    });

    String response = await sendMessageToChatGpt(message.text);
    Message chatGpt = Message(text: response, isMe: false);

    setState(() {
      _messages.insert(0, chatGpt);
      isTyping = false;
    });
  }

  List<MessageInfo> chatHistory = <MessageInfo>[];
  Future<String> sendMessageToChatGpt(String message) async {
    Uri uri = Uri.parse("https://api.openai.com/v1/chat/completions");
    if (chatHistory.isEmpty) {
      chatHistory.add(SystemMessages.assistantIntroduction);
    }
    chatHistory.add(MessageInfo('user', message));
    List<dynamic> requestmessages = [];
    for (var element in chatHistory) {
      requestmessages.add({"role": element.role, "content": element.content});
    }
    Map<String, dynamic> body = {
      "model": "gpt-3.5-turbo",
      "messages": requestmessages,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${APIKey.apiKey}",
      },
      body: json.encode(body),
    );

    print(response.body);

    if (response.statusCode == 200) {
      Map<String, dynamic> parsedResponse = json.decode(response.body);

      if (parsedResponse.containsKey('choices') &&
          parsedResponse['choices'] is List &&
          parsedResponse['choices'].isNotEmpty &&
          parsedResponse['choices'][0].containsKey('message') &&
          parsedResponse['choices'][0]['message'].containsKey('content')) {
        String reply = parsedResponse['choices'][0]['message']['content'];
        chatHistory.add(MessageInfo('assistant', reply));
        return reply;
      } else {
        // Handle the case when the response structure is unexpected
        return 'Error: Unexpected response structure';
      }
    } else {
      // Handle API error or non-200 response
      return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
    }
  }

  Widget _buildMessage(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.isMe ? 'You' : 'Cat AI',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: message.isMe ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getFormattedDate() {
    DateTime now = DateTime.now();
    DateFormat dateFormat = DateFormat("dd-MM-yyyy");
    String formattedDate = dateFormat.format(now);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF4D7F8F),
          child: ListView(
            padding: EdgeInsets.zero,
            children: const [
              DrawerHeader(
                decoration: BoxDecoration(),
                child: Center(
                  child: Text(
                    'GPT Options',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B3B),
        title: Row(
          children: const [
            Image(
              image: AssetImage('imagez/catrobat_icon_bgr.png'),
              width: 30,
              height: 30,
            ),
            SizedBox(width: 10),
            Text(
              'Cat AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF305260),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                child: Text(
                  "Today, ${getFormattedDate()}",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              //nn
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    return chat(
                        _messages[index].text, _messages[index].isMe ? 1 : 0);
                  },
                ),
              ),
              TypingIndicator(showIndicator: isTyping),

              const Divider(height: 1.0),

              const Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10.0),
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: onSendMessage,
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

  Widget chat(String message, int data) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Row(
        mainAxisAlignment:
            data == 1 ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          data == 0
              ? const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircleAvatar(
                    backgroundImage: AssetImage('imagez/catrobat_circle.png'),
                  ),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Bubble(
              radius: const Radius.circular(15.0),
              color: data == 0 ? Colors.cyan.shade200 : const Color(0xFFFFD700),
              elevation: 0.0,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          maxWidth: 250,
                        ),
                        child: SelectableText(
                          message,
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data == 1
              ? const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircleAvatar(
                    backgroundImage: AssetImage('imagez/person.png'),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isMe;

  Message({required this.text, required this.isMe});
}
