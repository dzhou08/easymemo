
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/paint_contents.dart';

import 'dart:io' as Io;
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

//import 'package:http/http.dart' as http;


import 'package:flutter_dotenv/flutter_dotenv.dart';
//import 'package:enhance_stepper/enhance_stepper.dart';
import 'rating_circle_chart.dart';




class StepperPage extends StatefulWidget {
  const StepperPage({super.key});

  @override
  State<StepperPage> createState() =>
      _StepperPageState();
}

class _StepperPageState extends State<StepperPage> {

  late String _imageFilePath;
    
  int currentStep = 0;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 2; 
  bool isComplete = false;

  // the three words tests
  String _threeWordsInit = "";
  String _threeWordsRepeat = "";


  // the ratings of clock drawing
  int _clockDrawingPoinst=0;
  String _clockDrawingFeedback="";

  late DrawingController _drawingController;

  Future<void> _initializeImagePath () async{
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    setState(() {
      _imageFilePath = '$path/FlutterLetsDraw.png';
    });
  }


  @override
  void initState() {
    super.initState();

    // initialzImagePath
    _initializeImagePath();

    _speechToText = stt.SpeechToText(); // Initialize here
    _drawingController = DrawingController();

    // Add a delay to draw a circle after the widget is loadedSingleChildScrollView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
         _drawCircle();
      });
    });

    _threeWordsInit = "";
    _threeWordsRepeat = "";

    // the ratings of clock drawing
    _clockDrawingPoinst=0;
    _clockDrawingFeedback="";
  }

  void resetState() {
    print("reset state called");
    setState(() {
      _speechToText = stt.SpeechToText(); // Initialize here
      _drawingController.clear;
      
      isComplete=false;
      currentStep=0;

      _threeWordsInit = "";
      _threeWordsRepeat = "";

      // the ratings of clock drawing
      _clockDrawingPoinst=0;
      _clockDrawingFeedback="";
    });
    
    // reset the drawing board
    _drawingController.clear();
    // Add a delay to draw a circle after the widget is loadedSingleChildScrollView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
         _drawCircle();
      });
    });
  }

  // Function to draw a circle
  void _drawCircle() {
    // Define the circle properties
    const Map<String, dynamic> circle = <String, dynamic>{
      'type': 'Circle',
      'isEllipse': false,
      'startFromCenter': true,
      'center': <String, dynamic>{
        'dx': 550.0,
        'dy': 762.0
      },
      'startPoint': <String, dynamic>{
        'dx': 130.94337550070736,
        'dy': 150.05980083656557
      },
      'endPoint': <String, dynamic>{
        'dx': 450.1373386828114,
        'dy': 477.32029957032194
      },
      'radius': 90.0,
      'paint': <String, dynamic>{
        'blendMode': 3,
        'color': 4294198070,
        'filterQuality': 3,
        'invertColors': false,
        'isAntiAlias': false,
        'strokeCap': 1,
        'strokeJoin': 1,
        'strokeWidth': 4.0,
        'style': 1
      }
    };

    _drawingController.addContent(Circle.fromJson(circle));
  }

  final openAI = OpenAI.instance.build(
    token: dotenv.env['OPENAI_API_KEY'].toString(),
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true
  );

  late stt.SpeechToText _speechToText;

  bool _isListening = false;
  String _text = 'Do you remember the three words you heard before? Press the button below to record only those three words.';

  String chatGPTResponse = "";

  Future<void> openAICalling(String path) async {
    // print(dotenv.env['OPENAI_API_KEY']);

    //String path = "/Users/zqian/Library/Containers/com.example.adApp/Data/Documents/FlutterLetsDraw.png";

    // Open the image file and encode it as a base64 string
    final bytes = Io.File(path).readAsBytesSync();

    String base64Image = base64Encode(bytes);
    String imageAnalysisInstruction = """
              Help me to analyze a png image file. Does it contain a norml clock?
              A normal clock has all numbers placed in the correct sequence and approximately correct position.
              (e.g., 12, 3, 6 and 9 are in anchor positions) with no missing or duplicate numbers. 
              Clock hands are pointing to the 11 and 2 (11:10).
              It is OK if the numbers are outside the clock circle.
              Clock hand length is not scored.
              Please provide a response in plain JSON format (with no extra markdown of formatting).
              The JSON object has two attributes, in lower cases: 
              points, and feedback.
              points = 2, when the image is of a normal clock; 0, otherwise;
              Give the reason of rating in the feedback attribute.
              
              Ensure the response is directly in JSON format without wrapping in backticks.
              """;

    final request_2 = ChatCompleteText(
      messages: [
        Map.of({"role": "system", "content": "You are a helpful medical assistant, specialized with the Mini-Cog™ analysis associated with Alzheimer disease."}),
        Map.of({"role": "user", "content": [
              {"type": "text", 
              "text": imageAnalysisInstruction},
              {
                "type": "image_url", 
                "image_url": {
                  "url": "data:image/png;base64,$base64Image"}
              }
          ]})
      ], 
      maxToken: 200, 
      model: Gpt4OChatModel(),
      temperature: 0.0,
    );

    final response = await openAI.onChatCompletion(request: request_2);
    for (var element in response!.choices) {
      print("data -> ${element.message?.content}");
    }
    String answerJSON = response.choices[0].message?.content.trim() ?? 'No response';
    Map<String, dynamic> jsonData = jsonDecode(answerJSON);
    print(jsonData);
    // Access the "values" key, which is a list of lists
    int points = jsonData['points'];
    // only need the first element and get the id value
    String feedback = jsonData['feedback'];
    setState(() {

      _clockDrawingPoinst = points;
      _clockDrawingFeedback = feedback;
    });
    
  }

  void speak() {
    
    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);

    // the list of three-words
    // Define a list of strings
    final List<String> threeWords = [
      'Banana, Sunrise, Chair', 
      'Leader, Season, Table',
      'Village, Kitchen, Baby',
      'River, Nation, Finger', 
      'Captain, Garden, Picture', 
      'Daughter, Heaven, Mountain'
    ];

    // Create a random number generator
    final random = Random();

    // Pick a random element from the list
    String randomThreeWords = threeWords[random.nextInt(threeWords.length)];
    setState(() {
      _threeWordsInit=randomThreeWords;
    });
    flutterTts.speak(randomThreeWords);
  }

  Widget buildResultPage(double clockPointPercentage) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        //mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // const Icon(Icons.done, size: 100, color: Colors.green),
          // const SizedBox(height: 20),
          const Text('Your Mini-Cog™ diagnose results are listed below:'),
          const SizedBox(height: 40),
          Text(
            'The original three words: $_threeWordsInit',
            textAlign: TextAlign.left,
          ),
          Text(
            'The recorded three words: $_threeWordsRepeat',
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 40),
          Image.asset(
            _imageFilePath,
            width: 250, // Set the desired width
            height: 250, // Set the desired height
            fit: BoxFit.contain, // Optional: control how the image fits the widget bounds
          ),
          Text(
            'Clock Draw Points: $_clockDrawingPoinst out of 2',
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                width: 300.0,
                height: 30.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.grey.shade300,
                ),
                child: LinearProgressIndicator(
                  value: clockPointPercentage,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  backgroundColor: Colors.transparent,
                  minHeight: 30.0,
                ),
              ),
              const Positioned(
                left: 0,
                top: 5.0,
                child: Text(
                  '0',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
              const Positioned(
                right: 0,
                top: 5.0,
                child: Text(
                  '2',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Clock Draw feedback:"),
          const SizedBox(height: 10),
          Text(_clockDrawingFeedback),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed: () {
                resetState();
              },
              child: const Text('Reset'),
            ),
          ),
        ],
      ),
    ),
  );


  Future<void> exportImageConetent() async{
   try {
      print("in export");
      final image = (await _drawingController.getImageData())?.buffer.asUint8List();
      if (image == null) {
        print('No image data');
        return;
      }
      print("has data");
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      print(path);
      final filePath = '$path/FlutterLetsDraw.png';
      final file = Io.File(filePath);
      await file.writeAsBytes(image);
      print('File saved at $filePath');

      // call openAI API to analyze the image
      openAICalling(filePath);
      
    } catch (e) {
      print('Error saving file: $e');
    }
  }

    Future<void> _listen() async {
    print("islistening:$_isListening");
    if (!_isListening) {
      if (!_speechToText.isAvailable) {
          print("need to initialize");
          await _speechToText.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError'),//: $val'),
        );
      }
      if (_speechToText.isAvailable) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) => setState(() {
            _threeWordsRepeat = val.recognizedWords;
            print(_threeWordsRepeat);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _sendToChatGPT(String userInput) async {
    if (userInput.isEmpty) return;

    final request = ChatCompleteText(
      messages: [
        Map.of({"role": "user", "content": userInput})
      ],
      maxToken: 100,
      model: Gpt4OChatModel(),
    );

    final response = await openAI.onChatCompletion(request: request);
    if (response != null) {
      String answerJSON = response.choices[0].message?.content.trim() ?? 'No response';
      Map<String, dynamic> jsonData = jsonDecode(answerJSON);

      
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: const Text('EasyMemo'),
      ),
      body: isComplete
        ? buildResultPage (_clockDrawingPoinst/2.toDouble())
        : Stepper(
            type: StepperType.vertical,
            steps: steps(_clockDrawingPoinst, _clockDrawingFeedback),
            currentStep: currentStep,
            onStepContinue: () {
              if (isLastStep) {
                setState(() => isComplete = true);
                exportImageConetent();
              } else {
                setState(() => currentStep += 1);
              }
            },
            onStepCancel:
              isFirstStep ? null : () => setState(() => currentStep -= 1),  
            
            onStepTapped: (step)  => setState(() => currentStep = step),
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Row(
                children: [
                  if(!isFirstStep) ...[
                    Expanded(
                      child:ElevatedButton(
                        onPressed: isFirstStep ? null : details.onStepCancel,
                        child: const Text('<< Back'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child:ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(isLastStep? 'Confirm': 'Next >>'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      );
  }

  List<Step> steps(int points, String feedback) => [
    Step(
      state: currentStep >= 0 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 0,
      title: const Text('Listen to Words'),
      content: Column(
        children: [
          Text (
            "Mini-Cog™ is a brief cognitive screening test for detecting dementia in early phase. ",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          RichText(
              text: const TextSpan(
                text: 'First, click the button below to listen to ',
                style: TextStyle(fontSize: 18.0, color: Colors.black), // Default style for normal text
                children: [
                  TextSpan(
                    text: 'three words',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.red, // Highlighted color
                      fontWeight: FontWeight.bold, // Bold style for highlighting
                    ),
                  ),
                  TextSpan(
                    text: '. Please try to remember them for later steps.',
                    style: TextStyle(fontSize: 18.0, color: Colors.black),
                  )
                ],
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: speak,
            child: const Text('Listen'),
          ),
        ],
      ),
    ),
    Step(
      state: currentStep >= 1 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 1,
      title: const Text('Draw a Clock'),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            RichText(
              text: const TextSpan(
                text: 'Now, draw a ',
                style: TextStyle(fontSize: 18.0, color: Colors.black), // Default style for normal text
                children: [
                  TextSpan(
                    text: 'clock',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.red, // Highlighted color
                      fontWeight: FontWeight.bold, // Bold style for highlighting
                    ),
                  ),
                  TextSpan(
                    text: ' on the pre-printed red circle blow. Include ',
                    style: TextStyle(fontSize: 18.0, color: Colors.black),
                  ),
                  TextSpan(
                    text: 'all the hour numbers',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.red, // Highlighted color
                      fontWeight: FontWeight.bold, // Bold style for highlighting
                    ),
                  ),
                  TextSpan(
                    text: ' and set the time to ',
                    style: TextStyle(fontSize: 18.0, color: Colors.black),
                  ),
                  TextSpan(
                    text: 'ten past eleven',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.red, // Highlighted color
                      fontWeight: FontWeight.bold, // Bold style for highlighting
                    ),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(fontSize: 18.0, color: Colors.black),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple)
              ),
              constraints:
                  const BoxConstraints(
                    maxWidth: 400, 
                    maxHeight: 400),
              padding: const EdgeInsets.all(20.0),// Provide a bounded height
              child: SizedBox(
                width: 400,
                height: 400,
                child:DrawingBoard(
                  controller: _drawingController,
                  transformationController: TransformationController(),
                  background: Container(
                    width: 400, 
                    height: 400, 
                    color: Colors.white,
                  ),
                  showDefaultActions: true, /// Enable default action options
                  showDefaultTools: true,  /// Enable default toolbar
                ),     
              ),
            ),
          ],
        ),
      ),
    ),
    Step(
      state: currentStep >= 2 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 2,
      title: const Text('Repeat the words'),
      content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _listen,
              child: Text(_isListening ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            if (chatGPTResponse.isNotEmpty)
              Text(
                'ChatGPT Response: $chatGPTResponse',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
    ),
  ];
}
