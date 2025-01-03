
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';  // Import for JSON parsing

// Ensure this import is present
// For handling file content
// For making API requests
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'env_config.dart';
import 'util.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

//import 'home_speaker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as Io;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:typed_data';

class AskingPage extends StatefulWidget {
  const AskingPage({Key? key}) : super(key: key);

  @override
  State<AskingPage> createState() => _AskingPageState();
}

class _AskingPageState extends State<AskingPage> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();
  
  List<Map<String, String>> messages = [];
  String? _fileContent;
  bool _isLoading = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';
  
  // Controller to manage the TextField
  final TextEditingController _controller = TextEditingController();

  // LabelText that will be updated
  String inputLabelText = "Enter your prompt";

  Uint8List? _image;

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        _image = bytes;
      });
    }
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final authProvider = Provider.of<GAuthProvider>(context);
    final token = authProvider.getAccessToken();

    if (token != null) {
      final content = await authProvider.searchFilesByName(token, 'memo', false);
      setState(() {
        _fileContent = content;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    _speech = stt.SpeechToText();
  }


  @override
  void dispose() {
    // Cancel any async operations if needed
    super.dispose();
  }
  
  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _voiceInput = val.recognizedWords;
          _controller.text = _voiceInput; // Populate the text field with voice input
          // reset
          _voiceInput='';
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> sendToGPT(String message) async {
    if (!mounted) return; // Check if mounted before setting state
    setState(() {
      _isLoading = true;
      messages.add({'user': message});
    });

    final openAI = OpenAI.instance.build(
      token: EnvConfig.openAIApiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 30)),
      enableLog: true
    );
    
    if (_image != null)
    {
      print("with picture");
      try {
        String base64Image = base64Encode(_image!);

        // Step 3: Construct the image analysis instruction
        String imageAnalysisInstruction = """
                  Help me to analyze the image file for an ALzheimer patient or an eldly person. 
                  Answer question based on the image content. 
                  Return a Yes or No answer for simple questions. If you do not have a clear answer, just say no.
                  Explain the image content if needed.
                  """;

        // Step 4: Create a ChatCompleteText request for OpenAI
        final requestImage = ChatCompleteText(
          messages: [
            {"role": "system", "content": "You are a helpful companion for an Alzheimer's patient. Patiently explain details."},
            {
              "role": "user",
              "content": [
                {"type": "text", "text": imageAnalysisInstruction},
                {"type": "image_url", "image_url": {"url": "data:image/png;base64,$base64Image"}}
              ]
            }
          ],
          maxToken: 200,
          model: Gpt4OChatModel(), // Assuming you're using GPT-4 model
          temperature: 0.0, // Adjust as needed
        );

        // Step 5: Send the request to OpenAI and process the response
        final response = await openAI.onChatCompletion(request: requestImage);

        // Step 6: Output the response
        if (response != null) {

          // Get the text response from GPT
          String answer = response.choices[0].message?.content.trim() ?? 'No response';

          if (mounted) {
            setState(() {

              messages.add({'assistant': answer});
              inputLabelText='Enter your message';
              _isLoading = false;
              _controller.clear();
              

            });
          }
        } else {
          print("No valid response received.");
        }
      } catch (e) {
        // Handle any exceptions that may occur during the process
        print("Error occurred: $e");
      }
    }
    else
    {
        final requestText = ChatCompleteText(
        messages: [
          Map.of({"role": "system", "content": "You are a helpful assistant that responds in image analysis."}),
          Map.of({"role": "user", "content": [
                {"type": "text", "text": "Help me answer the following message question based on fileContent value."},
                {
                  "type": "text", 
                  "text": _fileContent
                },
                {
                  "type": "text", 
                  "text": message
                },
            ]})
        ], 
        maxToken: 200, 
        model: Gpt4OChatModel(),
        temperature: 0.0,
      );

      final response = await openAI.onChatCompletion(request: requestText);
      // Get the text response from GPT
      String answer = response?.choices[0].message?.content.trim() ?? 'No response';

      if (mounted) {
        setState(() {
          messages.add({'assistant': answer});
          inputLabelText='Enter your message';
          _isLoading = false;
        });
      }
    }
  }

  // Function to read out the messages list
  void _readMessages() {
    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.3);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);

    String readMessageContent = '';

    // loop through all messages
    // Loop through all messages
    for (var message in messages) {
      if (message.containsKey('user')) {
        // Safely access 'user' and append to the string
        readMessageContent += "From User: ${message['user'] ?? ''}  ";
      } else if (message.containsKey('assistant')) {
        // Safely access 'assistant' and append to the string
        readMessageContent += "From EasyMemo: ${message['assistant'] ?? ''} ";
      }
    }
    flutterTts.speak(readMessageContent);
  }

  // Function to clear the messages list
  void _clearMessages() {
    setState(() {
      messages.clear();
    });
  }

  // Function to clear the messages list
  void _clearQuestion() {
    setState(() {
      _controller.text='';
      _controller.clear();
    });
  }

  // Function to remove the image
  void _removeImage() {
    setState(() {
      _image = null; // Reset the image to null
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<GAuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Me Anything'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
              mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
              children: [
                ElevatedButton(
                  onPressed: _readMessages,
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
                    mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
                    children: [
                      SvgPicture.asset(
                        'assets/icons/microphone.svg', // Path to your SVG asset
                        width: 20.0, // Adjust the size as needed
                        height: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      const Text('Read Messages'),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: _clearMessages,  // Call the clear function to clear messages
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
                    mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
                    children: [
                      SvgPicture.asset(
                        'assets/icons/delete.svg', // Path to your SVG asset
                        width: 20.0, // Adjust the size as needed
                        height: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      const Text('Clear Messages'),
                    ],
                  ),
                ),
                /*const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: _clearQuestion,  // Call the clear function to clear question
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
                    mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
                      
                    children: [
                      SvgPicture.asset(
                        'assets/icons/delete.svg', // Path to your SVG asset
                        width: 20.0, // Adjust the size as needed
                        height: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      const Text('Clear Questions'),
                    ],
                  ),
                ),*/
              ]
            )
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                print(message);
                // Display either user or assistant message
                return SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.containsKey('user'))
                        const Icon(
                          Icons.person,
                          color: Colors.purple
                        ),  // Replace "Assistant:" with an icon
                      if (message.containsKey('assistant'))
                        const Icon(
                          Icons.smart_toy,
                          color: Colors.purple,
                        ),
                      const SizedBox(width: 8), // Add some spacing between the icon and the text
                      Expanded(
                        child: Text(
                          message.containsKey('user')
                              ? message['user'] ?? ''  // Handle null user messages
                              : message['assistant'] ?? '',       // Handle null assistant messages
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Display selected image with a delete button (if any)
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  // Image display
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Image.memory(
                        _image!,
                        //width: 200, // Set the width to 200 pixels
                        //height: 150, // Set the height to 150 pixels
                        fit: BoxFit.cover)
                  ),
                  // Delete button
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _removeImage, // Call the function to remove the image
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,  // Attach the controller to the TextField
              decoration: InputDecoration(
                labelText: "Enter your message here",
                border: const OutlineInputBorder(),
                suffixIcon: Row( 
                  mainAxisSize: MainAxisSize.min, // Adjusts the Row's width
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _pickImage, // Trigger image picker
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),  // Microphone icon
                      onPressed: _isListening ? _stopListening : _startListening,  // Toggle listening
                    ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _controller.text='';
                  sendToGPT(value);
                }
              },
            ),
          ),
          /*
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: pickFile,
              child: const Text('Upload File'),
            ),
          ),*/
          if (_isLoading) const CircularProgressIndicator(),

          //const Speaker(),
          //const SizedBox(height: 10),
        ],
      ),
    );
  }
}