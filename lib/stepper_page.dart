
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

import 'package:flutter_html/flutter_html.dart';


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

  String? _imageFilePath;
    
  int currentStep = 0;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == 2; 
  bool isComplete = false;

  // the three words tests
  Set<String> _threeWordsInitSet = {};
  Set<String> _threeWordsRepeatSet = {};
  int _wordRecallPoints=0;


  // the ratings of clock drawing
  int _clockDrawingPoints=0;
  String _clockDrawingFeedback="";

  late DrawingController _drawingController;

  Future<void> _initializeImagePath() async {
    final directory = await getApplicationDocumentsDirectory(); // Await the future to get the directory
    final path = directory.path;

    setState(() {
      _imageFilePath = '$path/FlutterLetsDraw.png';
      print("init set $_imageFilePath");
    });

    // Delete the file if it exists
    final file = Io.File(_imageFilePath!); // Correct import prefix 'io'
    if (await file.exists()) { // Use await for asynchronous file operations
      await file.delete(); // Asynchronously delete the file
      print('FlutterLetsDraw.png deleted successfully');
    }
  }

  Future<void> _initAsync() async {
    // Initialize the image path asynchronously
    await _initializeImagePath();
  }
  @override
  void initState() {
    super.initState();

    // Call asynchronous initialization
    _initAsync();

    _drawingController = DrawingController();
    _speechToText = stt.SpeechToText(); // Initialize here
    isComplete=false;
    currentStep=0;

    _threeWordsInitSet = {};
    _threeWordsRepeatSet = {};
    _wordRecallPoints=0;

    // the ratings of clock drawing
    _clockDrawingPoints=0;
    _clockDrawingFeedback="";

    // Add a delay to draw a circle after the widget is loadedSingleChildScrollView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
         _drawCircle();
      });
    });
  }

  void resetState() {
    print("reset state called");
    
    // initialzImagePath
    _initAsync();

    setState(() {
      _speechToText = stt.SpeechToText(); // Initialize here
      _drawingController.clear;
      
      isComplete=false;
      currentStep=0;

      _threeWordsInitSet = {};
      _threeWordsRepeatSet = {};
      _wordRecallPoints=0;

      // the ratings of clock drawing
      _clockDrawingPoints=0;
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
        'dx': 120.94337550070736,
        'dy': 150.05980083656557
      },
      'endPoint': <String, dynamic>{
        'dx': 440.1373386828114,
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
  final String _text = 'Do you remember the three words you heard before? Press the button below to record only those three words.';

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
    String answerJSON = response!.choices[0].message?.content.trim() ?? 'No response';
    Map<String, dynamic> jsonData = jsonDecode(answerJSON);
    // Access the "values" key, which is a list of lists
    int points = jsonData['points'];
    // only need the first element and get the id value
    String feedback = jsonData['feedback'];
    setState(() {
      _clockDrawingPoints = points;
      _clockDrawingFeedback = feedback;
    });
    
  }

  void speak() {
    
    FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.3);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);

    // the list of three-words
    // Define a list of strings
    final List<Set<String>> threeWords = [
      {'banana', 'sunrise', 'chair'}, 
      {'leader', 'season', 'table'},
      {'village', 'kitchen', 'baby'},
      {'river', 'nation', 'finger'}, 
      {'captain', 'garden', 'picture'}, 
      {'daughter', 'heaven', 'mountain'}
    ];

    // Create a random number generator
    final random = Random();

    // Pick a random element from the list
    int randomIndex = random.nextInt(threeWords.length);
    Set<String> randomThreeWords = threeWords[randomIndex];
    setState(() {
      _threeWordsInitSet=randomThreeWords;
    });
    flutterTts.speak(randomThreeWords.join(' '));
  }

  Widget buildResultPage(double clockPointPercentage) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const Text('Your Mini-Cog™ diagnose results are listed below:'),
            Card(
              
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                      Html(
                        data: "<span style='color: purple;'><b>Word Recall:</b></span>",
                      ),
                      Html(
                        data: "The original three words are: <br/> <b>${_threeWordsInitSet.join(', ')}</b>",
                      ),
                      Html(
                        data: "You said: <br/> <b>${_threeWordsRepeatSet.join(', ')}</b>",
                      ),
                      Html(
                        data: "Your score is: <br/> <b> $_wordRecallPoints out of 3.</b>",
                      ),
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
                              value: _wordRecallPoints/3,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
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
                              '3',
                              style: TextStyle(fontSize: 18.0, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ),
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Html(
                        data: "<span style='color: purple;'><b>Clock Draw:</b></span>",
                    ),
                    if (_imageFilePath == null)
                      const CircularProgressIndicator() // Show a loading indicator while waiting for initialization
                    else if (_imageFilePath != null && Io.File(_imageFilePath!).existsSync())
                      Image.file(
                        Io.File(_imageFilePath!),
                        key: UniqueKey(), 
                        width: 250,
                        height: 250,
                      )
                    else
                      Text('No image found at the specified path $_imageFilePath'),
                    Html(
                      data: "<b>Clock Draw Points:</b> $_clockDrawingPoints out of 2",
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
                            value: _clockDrawingPoints/2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
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
                    Html(
                      data: "<b>Clock Draw feedback:</b>"
                    ),
                    const SizedBox(height: 10),
                    Text(_clockDrawingFeedback),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            Html(
                data: "<span style='color: purple;'><b>Total Score:</b></span> <b>${_wordRecallPoints+_clockDrawingPoints}</b>",
            ),
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
    ),
  );


  Future<void> exportImageConetent() async{
   try {
      print("in export");

      // Wait for the current frame to complete before exporting the image
      WidgetsBinding.instance.addPostFrameCallback((_) async {

        // Step 1: delete previous data file
        final file = Io.File(_imageFilePath!);

        // Delete the file if it exists
        if (await file.exists()) {
          print('FlutterLetsDraw.png to be deleted');
          await file.delete();
          print('FlutterLetsDraw.png deleted successfully');
        }

        // Step 2: Get the image data from the drawing controller
        final image = (await _drawingController.getImageData())?.buffer.asUint8List();
        if (image == null) {
          print('No image data');
          return;
        }
        print("has data");

        // Write the new image data to the file
        String newImageFilePath = _imageFilePath! + DateTime.now().millisecondsSinceEpoch.toString();
        await Io.File(newImageFilePath).writeAsBytes(image, flush: true);
        print('File saved at $newImageFilePath');

        // Trigger a rebuild to update the displayed image
        setState(() {
          // Optionally update _imageFilePath if the path changes
          _imageFilePath = newImageFilePath;
        });

        // Optionally call OpenAI API to analyze the image
        openAICalling(_imageFilePath!);
      });  
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
            _threeWordsRepeatSet = val.recognizedWords.toLowerCase().split(RegExp(r'[ ,]+')).toSet();
            _wordRecallPoints = _threeWordsRepeatSet.intersection(_threeWordsInitSet).length;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }
  /*
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
  }*/
  
  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: const Text('EasyMemo'),
      ),
      body: isComplete
        ? buildResultPage (_clockDrawingPoints/2.toDouble())
        : Stepper(
            type: StepperType.vertical,
            steps: steps(_clockDrawingPoints, _clockDrawingFeedback),
            currentStep: currentStep,
            onStepContinue: () {
              print("isLastStep $isLastStep");
              if (isLastStep) {
                setState(() => isComplete = true);
              } else {
                if (currentStep == 1)
                {
                  // step 2; export image
                  exportImageConetent();
                }
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
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple)
              ),
              constraints:
                  const BoxConstraints(
                    maxWidth: 450, 
                    maxHeight: 450),
              padding: const EdgeInsets.all(20.0),// Provide a bounded height
              child: SizedBox(
                width: 450,
                height: 450,
                child:DrawingBoard(
                  controller: _drawingController,
                  transformationController: TransformationController(),
                  background: Container(
                    width: 450, 
                    height: 450, 
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
