
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
import 'package:enhance_stepper/enhance_stepper.dart';



class StepperPage extends StatefulWidget {
  const StepperPage({super.key});

  @override
  State<StepperPage> createState() =>
      _StepperPageState();
}

class _StepperPageState extends State<StepperPage> {
  int currentStep = 0;

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == steps().length - 1; 
  bool isComplete = false;

  late DrawingController _drawingController;

  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController();

    // Add a delay to draw a circle after the widget is loadedSingleChildScrollView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
         _drawCircle();
      });
    });
  }

  // Function to draw a circle
  /*void _drawCircle() {
    // Define the circle properties
    const Map<String, dynamic> circle = <String, dynamic>{
      'type': 'Circle',
      'isEllipse': false,
      'startFromCenter': true,
      'center': <String, dynamic>{
        'dx': 768.0,
        'dy': 762.0
      },
      'startPoint': <String, dynamic>{
        'dx': 150.94337550070736,
        'dy': 150.05980083656557
      },
      'endPoint': <String, dynamic>{
        'dx': 477.1373386828114,
        'dy': 477.32029957032194
      },
      'radius': 100.0,
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
  }*/
  // Function to draw a circle using flutter_drawing_board package
  void _drawCircle() {
    // Get the size of the drawing board to avoid out-of-bounds issues
    const Size boardSize = Size(400, 400);

    // Define the circle properties with updated size constraints
    final Map<String, dynamic> circle = <String, dynamic>{
      'type': 'Circle',
      'isEllipse': false,
      'startFromCenter': true,
      'center': <String, dynamic>{
        'dx': boardSize.width / 2,
        'dy': boardSize.height / 2,
      },
      'startPoint': <String, dynamic>{
        'dx': boardSize.width / 4,
        'dy': boardSize.height / 4,
      },
      'endPoint': <String, dynamic>{
        'dx': (boardSize.width / 4) * 3,
        'dy': (boardSize.height / 4) * 3,
      },
      'radius': (boardSize.width < boardSize.height ? boardSize.width : boardSize.height) / 5,
      'paint': <String, dynamic>{
        'blendMode': 3,
        'color': 4294198070,
        'filterQuality': 3,
        'invertColors': false,
        'isAntiAlias': true,
        'strokeCap': 1,
        'strokeJoin': 1,
        'strokeWidth': 4.0,
        'style': 1,
      }
    };

    // Add the circle content to the drawing controller
    _drawingController.addContent(Circle.fromJson(circle));
  }

  final openAI = OpenAI.instance.build(
    token: dotenv.env['OPENAI_API_KEY'].toString(),
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true
  );

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Do you remember the three words you heard before? Press the button below to record the words.';

  String chatGPTResponse = "";

  Future<void> openAICalling(String path) async {
    // print(dotenv.env['OPENAI_API_KEY']);

    //String path = "/Users/zqian/Library/Containers/com.example.adApp/Data/Documents/FlutterLetsDraw.png";

    // Open the image file and encode it as a base64 string
    final bytes = Io.File(path).readAsBytesSync();

    String base64Image = base64Encode(bytes);

    final request_2 = ChatCompleteText(
      messages: [
        Map.of({"role": "system", "content": "You are a helpful assistant that responds in image analysis."}),
        Map.of({"role": "user", "content": [
              {"type": "text", 
              "text": """
              Help me to analyze a png image file. Does it contain a norml clock?
              A normal clock has all numbers placed in the correct sequence and approximately correct position 
              (e.g., 12, 3, 6 and 9 are in anchor positions) with no missing or duplicate numbers. 
              Clock hands are pointing to the 11 and 2 (11:10). 
              Hand length is not scored.
              Please give your rating in a JSON format with the following two attributes:
                Points: 2 for a normal clock; 0 otherwise;
                Feedback: give the reason of rating.
              """},
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

    flutterTts.speak(randomThreeWords);
  }

  Widget buildSuccessPage() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.done, size: 100, color: Colors.green),
        const SizedBox(height: 20),
        const Text('You have successfully completed the diagnose steps!'),
        const SizedBox(height: 40),
        Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                currentStep = 0;
                isComplete = false;
              });
            },
            child: const Text('Reset'),
          ),
        )
      ],
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
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError'),//: $val'),
      );
      if (available) {
        print("available");
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _sendToChatGPT(_text);
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
      setState(() {
        for (var element in response.choices) {
          print("data -> ${element.message?.content}");
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('EasyMemo'),
    ),
    body: isComplete
      ? buildSuccessPage ()
      : EnhanceStepper(
      type: StepperType.horizontal,
      horizontalTitlePosition: HorizontalTitlePosition.bottom,
      horizontalLinePosition: HorizontalLinePosition.top,
      steps: steps(),
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

  List<EnhanceStep> steps() => [
    // https://www.alz.org/media/documents/mini-cog.pdf
    EnhanceStep(
      state: currentStep >= 0 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 0,
      title: const Text('Listen'),
      content: Column(
        children: [
          Text (
            "We'll begin with a few questions that require some concentration. ",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text (
            'First, click the button below to listen to three words. Please try to remember them for later. ',
            style: Theme.of(context).textTheme.bodyMedium,),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: speak,
            child: const Text('Listen'),
          ),
        ],
      ),
    ),
    EnhanceStep(
      state: currentStep >= 1 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 1,
      title: const Text('Draw'),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Text (
              'Now, draw a clock on the pre-printed red circle below. include all the hour numbers and set the time to ten past eleven.', 
              style: Theme.of(context).textTheme.bodyMedium,),
            const SizedBox(height: 20),
            Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple)
              ),
              constraints:
                  const BoxConstraints(
                    minWidth: 400,
                    maxWidth: 400, 
                    maxHeight: 400,
                    minHeight: 400),
              padding: const EdgeInsets.all(20.0),// Provide a bounded height
              child: SizedBox(
                width: 400,
                height: 400,
                child:DrawingBoard(
                  controller: _drawingController,
                  transformationController: TransformationController(),
                  background: Container(
                    width: 300, 
                    height: 300, 
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
    EnhanceStep(

      state: currentStep >= 2 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 2,
      title: const Text('Repeat'),
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
    EnhanceStep(
      state: currentStep >= 3 ? StepState.complete : StepState.indexed,
      isActive: currentStep >= 3,
      title: const Text('Results'),
      content: const Text('Content 4'),
    ),
  ];
}

