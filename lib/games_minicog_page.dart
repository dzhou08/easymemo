
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

import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'package:intl/intl.dart';
import 'env_config.dart';
import 'util.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';
import 'dart:typed_data';

class CircleClockPaintContent extends PaintContent {
  final Offset center;
  final double radius;
  final Paint circlePaint;
  final Paint tickPaint;

  CircleClockPaintContent({
    required this.center,
    required this.radius,
    required this.circlePaint,
    required this.tickPaint,
  });

  @override
  void drawContent(Canvas canvas, Size size) {
    // Draw the circle
    canvas.drawCircle(center, radius, circlePaint);

    // Draw the hour ticks
    for (int i = 0; i < 12; i++) {
      double angle = (i * 30) * (pi / 180);
      double startX = center.dx + radius * 0.9 * cos(angle);
      double startY = center.dy + radius * 0.9 * sin(angle);
      double endX = center.dx + radius * cos(angle);
      double endY = center.dy + radius * sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'center': {'dx': center.dx, 'dy': center.dy},
      'radius': radius,
      'circlePaint': {
        'color': circlePaint.color.value,
        'strokeWidth': circlePaint.strokeWidth,
        'style': circlePaint.style.index,
      },
      'tickPaint': {
        'color': tickPaint.color.value,
        'strokeWidth': tickPaint.strokeWidth,
        'style': tickPaint.style.index,
      },
    };
  }

  @override
  PaintContent fromJson(Map<String, dynamic> json) {
    return CircleClockPaintContent(
      center: Offset(json['center']['dx'], json['center']['dy']),
      radius: json['radius'],
      circlePaint: Paint()
        ..color = Color(json['circlePaint']['color'])
        ..strokeWidth = json['circlePaint']['strokeWidth']
        ..style = PaintingStyle.values[json['circlePaint']['style']],
      tickPaint: Paint()
        ..color = Color(json['tickPaint']['color'])
        ..strokeWidth = json['tickPaint']['strokeWidth']
        ..style = PaintingStyle.values[json['tickPaint']['style']],
    );
  }

  @override
  PaintContent copy() {
    return CircleClockPaintContent(
      center: center,
      radius: radius,
      circlePaint: circlePaint,
      tickPaint: tickPaint,
    );
  }

  @override
  void draw(Canvas canvas, Size size, bool isFill) {
    drawContent(canvas, size);
  }

  @override
  void drawing(Offset endPoint) {
    // Implement the drawing logic if needed
  }

  @override
  void startDraw(Offset startPoint) {}

  @override
  Map<String, dynamic> toContentJson() {
    return toJson();
  }
}

class MiniCogPage extends StatefulWidget {
  const MiniCogPage({super.key});

  @override
  State<MiniCogPage> createState() =>
      _MiniCogPageState();
}

class _MiniCogPageState extends State<MiniCogPage> {
  static GlobalKey resultContainer = GlobalKey();

  //String? _imageFilePath;
    
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

  String? _googleAccessToken;
  late Client _httpClient;

  late DrawingController _drawingController;

  Uint8List? _imageBytes;

  Future<void> _initAsync() async {
    // Initialize the image path asynchronously
    //await _initializeImagePath();
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    _googleAccessToken = authProvider.getAccessToken();
    _httpClient = authProvider.getAuthClient();
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

  // Function to search files by name
  Future<String?> _getGoogleFolderByName(String accessToken, String folderName) async {
    // the return value of folderId
    String? folderId;

    print("in google folder  $accessToken");
    // Google Drive API search query to search for a folder by name
    final query = "name contains '$folderName'";
    print(query);
    try
    {
      var driveApi = drive.DriveApi(_httpClient);//DriveApi(_httpClient);
      // List files in the specified folder
      final fileList = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name)',
      );

      // Loop through and print file details
      for (var file in fileList.files ?? []) {
        print('File ID: ${file.id}, Name: ${file.name}, MIME type: ${file.mimeType}');
        folderId = file.id;
        break;
      }
    }
    catch (e)
    {
      print('error finding google folder $e');
    }
    return folderId;
  }

  Future<void> sendReport() async{
    try {

      print("in sendReport");

      // first, send score report to the scores spreadsheet
      final authProvider = Provider.of<GAuthProvider>(context, listen: false);
      authProvider.reportGameScore('mini-cog', _wordRecallPoints+_clockDrawingPoints);

      // Create a PDF document
      final font = await PdfGoogleFonts.nunitoExtraLight();
      final pdf = pw.Document();
      pw.MemoryImage? imagePdf;
      if ( _imageBytes!= null) {
        //final pngBytes = await Io.File(_imageFilePath!).readAsBytes(); // Read file bytes
        imagePdf = pw.MemoryImage(_imageBytes!); // Create a MemoryImage
      } else {
        print("Image file does not exist or the path is null");
      }

      var now = DateTime.now();
      var hourMin = DateFormat("h:mm a", "en_US").format(now);
      var yearDay = DateFormat("MMM dd, yyyy", "en_US").format(now);
      var timestampFileName = DateFormat("yyyyMMddhmma", "en_US").format(now);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('$yearDay $hourMin', style: pw.TextStyle(font: font)),
              pw.Text('Your Mini-Cog diagnose results are listed below:', style: pw.TextStyle(font: font)),
              pw.Divider(
                thickness: 4,
                color: PdfColors.deepPurple,
              ),
              pw.Text('Word Recall', style: pw.TextStyle(font: font)),
              pw.Text("The original three words are: ${_threeWordsInitSet.join(', ')}", style: pw.TextStyle(font: font)),
              pw.Text("You said:${_threeWordsRepeatSet.join(', ')}", style: pw.TextStyle(font: font)),
              pw.Text("Your score is: $_wordRecallPoints out of 3.", style: pw.TextStyle(font: font)),
              pw.Divider(
                thickness: 4,
                color: PdfColors.deepPurple,
              ),
              pw.Text("Clock Draw Points: $_clockDrawingPoints out of 2", style: pw.TextStyle(font: font)),
              pw.Image(
                imagePdf!,
                width: 400, // Set the desired width
                height: 200, // Set the desired height
              fit: pw.BoxFit.contain, ),
              pw.Text("Clock Draw feedback:", style: pw.TextStyle(font: font)),
              pw.Text(_clockDrawingFeedback, style: pw.TextStyle(font: font)),
              pw.Divider(
                thickness: 4,
                color: PdfColors.deepPurple,
              ),
              pw.Text("Total score: ${_wordRecallPoints+_clockDrawingPoints}", style: pw.TextStyle(font: font)),
            ]
          )
        )
      );

      // Convert the PDF document to bytes
      final pdfBytes = await pdf.save();

      // get local path
      final driveFolderId = await _getGoogleFolderByName(_googleAccessToken.toString(), 'minicog_reports_folder');
      print(driveFolderId);
      
      var driveApi = drive.DriveApi(_httpClient);
      // Prepare the file metadata
      var fileToUpload = drive.File()
        ..name = 'MiniCog_report_$timestampFileName.pdf'
        ..parents = [driveFolderId!]; // You can change this to your specific folder ID if needed

      // Create a media object for uploading
      final media = drive.Media(
        Stream.fromIterable([pdfBytes]),
        pdfBytes.length,
      );

      // Upload the PDF to Google Drive
      final uploadResponse = await driveApi.files.create(
        fileToUpload,
        uploadMedia: media,
      );

      print('File uploaded successfully! File ID: ${uploadResponse.id}');
    }
    catch (e)
    {
      print('error finding google folder $e');
    }
  }

  // Function to draw a circle as a clock with hour ticks
  void _drawCircle() {
    print("draw circle");
    final Paint circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final Paint tickPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Offset center = Offset(200.0, 200.0);
    final double radius = 90.0;

    _drawingController.addContent(
      CircleClockPaintContent(
        center: center,
        radius: radius,
        circlePaint: circlePaint,
        tickPaint: tickPaint,
      ),
    );

    setState(() {}); // Trigger a rebuild to display the new content
  }

  final openAI = OpenAI.instance.build(
    token: EnvConfig.openAIApiKey,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 30)),
    enableLog: true
  );

  late stt.SpeechToText _speechToText;

  bool _isListening = false;
  final String _text = 'Do you remember the three words you heard before? Press the button below to record only those three words.';

  String chatGPTResponse = "";

  Future<void> openAICalling() async {
    // Open the image file and encode it as a base64 string
    //final bytes = Io.File(path).readAsBytesSync();

    String base64Image = base64Encode(_imageBytes!);
    String imageAnalysisInstruction = """
              Help me to analyze the image file. 
              
              Does it contain a normal clock drawing satisfying the following criteria?
              
              1. All numbers from 1 to 12 should be present and in sequence.
              2. Numbers can be outside the circle.
              3. Anchor positions (12, 3, 6, 9) should be roughly correct.
              4. Hands are pointing to the 11 and 2 (11:10). Hand length is not scored.
              
              Please provide a response in plain JSON format (with no extra markdown of formatting).
              The JSON object has two attributes, in lower cases: 
              points, and feedback.
              points = 2, when the image is of a normal clock; Otherwise, points = 0;
              Give the reason of rating in the feedback attribute.
              
              Ensure the response is directly in JSON format without wrapping in backticks.
              """;

    final request_2 = ChatCompleteText(
      messages: [
        Map.of({"role": "system", "content": "You are an expert with Mini-Cog™ analysis for early detection of Alzheimer disease."}),
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
                        data: "<span style='color: purple;'><b>Word Recall:</b></span><br/>The original three words are: <br/> <b>${_threeWordsInitSet.join(', ')}</b><br/>You said: <br/> <b>${_threeWordsRepeatSet.join(', ')}</b><br/>Your score is: <br/> <b> $_wordRecallPoints out of 3.</b>",
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
                        data: "<span style='color: purple;'><b>Clock Draw:</b>"
                    ),
                    if (_imageBytes == null)
                      const CircularProgressIndicator() // Show a loading indicator while waiting for initialization
                    else if (_imageBytes != null)
                      Image.memory(
                        _imageBytes!,
                        width: 200, // Set the width to 200 pixels
                        height: 150, // Set the height to 150 pixels
                        fit: BoxFit.cover) // Adjust the content within the specified dimensions)
                    else
                      const Text('No image found at the specified path'),
                    Html(
                      data: "Clock Draw Points:</b> $_clockDrawingPoints out of 2",
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
                    const Text("Clock Draw feedback:"),
                    const SizedBox(height: 10),
                    Text(_clockDrawingFeedback),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            Text("Total Score: ${_wordRecallPoints+_clockDrawingPoints}"),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
              mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
              children: [
                ElevatedButton(
                  onPressed: () {
                    sendReport();
                  },
                  child: const Text('Send Report'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    resetState();
                  },
                  child: const Text('Reset'),
                ),
              ]
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

        // Get the image data from the drawing controller
        _imageBytes = (await _drawingController.getImageData())?.buffer.asUint8List();
        if (_imageBytes == null) {
          print('No image data');
          return;
        }

        // Optionally call OpenAI API to analyze the image
        openAICalling();
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
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: resultContainer,
        child: Scaffold (
      appBar: AppBar(
      title: const Text('Mini-Cog™ Test'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: isComplete
        ? buildResultPage (_clockDrawingPoints/2.toDouble())
        : Stepper(
            type: StepperType.vertical,
            steps: steps(_clockDrawingPoints, _clockDrawingFeedback),
            currentStep: currentStep,
            onStepContinue: () {
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
              child: Center(
                child: Row(
                  children: [
                    if(!isFirstStep) ...[
                      ElevatedButton(
                        onPressed: isFirstStep ? null : details.onStepCancel,
                        child: const Text('<< Back'),
                      ),
                      const SizedBox(width: 16),
                    ],
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(isLastStep? 'Confirm': 'Next >>'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      )
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
