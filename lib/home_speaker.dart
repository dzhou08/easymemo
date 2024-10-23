import 'package:flutter/material.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:logging/logging.dart';


class Speaker extends StatefulWidget {
  const Speaker({super.key});

  
  @override
  _SpeakerState createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> {

  final Logger _logger = Logger('home_speaker');

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Press the button and start speaking";
  double _confidence = 1.0;

  void _setupLogging() {
    Logger.root.level = Level.ALL; // Log everything
    Logger.root.onRecord.listen((LogRecord rec) {
      _logger.info('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _setupLogging();
  }

  Future<void> _listen() async {
    //_logger.info('in _listen');
    //_logger.info(_isListening);
    if (!_isListening) {
      _logger.info('_isListening is false');
      bool available = await _speech.initialize(
        onStatus: (status) => _logger.info('onStatus: $status'),
        onError: (errorNotification) => _logger.info('onError: $errorNotification'),
      );
      //_logger.info('after speech init');
      //_logger.info(available);
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
            if (result.hasConfidenceRating && result.confidence > 0.5) {
              _confidence = result.confidence;
              _text="$_text: words recorded.";
            }
            else {
              _confidence = result.confidence;
              _text="please repeat the question again.";
            }
          });
        });
      } else {
        setState(() => _isListening = false);
      }
    } else {
      _logger.info('_isListening is true');
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = ThemeData.light(useMaterial3: true);
        
    //Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      //color: theme.colorScheme.onPrimary,
      color: theme.colorScheme.onPrimary,
    );
    
    return Center(
      child: Card(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
            const SizedBox(height: 10),
            const VerticalDivider(
              color: Colors.black,
              thickness: 4,
            ),
            const VerticalDivider(
              color: Colors.black,
              thickness: 4,
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 10),
            Text(
                'Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 20.0),
              ),
            Text(
              _text,
              style: const TextStyle(fontSize: 32.0),
            ),
            FloatingActionButton(
              onPressed: () {
                _listen();
              },
              child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            ),
        ],
      ),
      ),
    );
  }
}
