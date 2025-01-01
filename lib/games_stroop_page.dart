import 'dart:async';
import 'package:flutter/material.dart';
import 'util.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class StroopPage extends StatefulWidget {
  const StroopPage({super.key});

  @override
  _StroopPageState createState() => _StroopPageState();
}

class _StroopPageState extends State<StroopPage> {
  final List<String> _colorNames = ['Red', 'Green', 'Blue', 'Yellow'];
  final Map<String, Color> _colorMap = {
    'Red': Colors.red,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Yellow': Colors.yellow,
  };

  String _currentWord = '';
  Color _currentColor = Colors.black;
  int _score = 0;
  int _timeRemaining = 30;
  Timer? _timer;

  late List<String> _shuffledColorNames;
  bool _isGameStarted = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _shuffledColorNames = List.from(_colorNames)..shuffle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      _isGameOver = false;
      _score = 0;
      _timeRemaining = 30;
    });

    _nextQuestion();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          timer.cancel();
          setState(() {
            _isGameOver = true;
            _isGameStarted = false;
          });
        }
      });
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentWord = (_colorNames..shuffle()).first;
      _currentColor = (_colorMap.values.toList()..shuffle()).first;
    });
  }

  void _checkAnswer(String colorName) {
    if (_colorMap[colorName] == _currentColor) {
      setState(() {
        _score++;
      });
    }
    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    // Generate buttons using the shuffled color names
    List<Widget> buttons = _shuffledColorNames.map((colorName) {
      return ElevatedButton(
        onPressed: (_isGameStarted && !_isGameOver) ? () => _checkAnswer(colorName) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorMap[colorName],
        ),
        child: Text(
          colorName,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroop Test'),
        centerTitle: true,
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Persistent instructions
            const Text(
              'In this test, you will be shown a word displayed in a specific color. \n\n Your task is to identify the color of the text, not the word itself. \n\n Tap the button that matches the color of the word.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Game state or start/restart button
            if (_isGameOver) ...[
              Text(
                'Game Over! Your score: $_score',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              Row (
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.reportGameScore('stroop', _score);
                    },
                    child: const Text('Record Score'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startGame,
                    /*style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),*/
                    child: const Text('Restart Game'),
                  ),
                ]
              ),
            ] else if (_isGameStarted) ...[
              Text(
                'Time Remaining: $_timeRemaining',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                _currentWord,
                style: TextStyle(fontSize: 40, color: _currentColor),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                alignment: WrapAlignment.center,
                children: buttons,
              ),
              const SizedBox(height: 20),
              Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 20),
              ),
            ] else ...[
              Center(
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Start Game'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
