import 'package:flutter/material.dart';
import 'dart:async';

class SDMTPage extends StatefulWidget {
  const SDMTPage({super.key});

  @override
  _SDMTPageState createState() => _SDMTPageState();
}

class _SDMTPageState extends State<SDMTPage> {
  final Map<String, String> symbolToDigit = {
    '🍎': '1',
    '🍌': '2',
    '🍒': '3',
    '🍉': '4',
    '🍓': '5',
    '🍍': '6',
    '🍊': '7',
    '🍋': '8',
    '🍑': '9',
    '🍒': '0',
  };

  List<String> symbols = [];
  List<String> userAnswers = [];
  int score = 0;
  bool isTesting = false;
  bool isCompleted = false;
  final int _timeLimit = 30; // 30 seconds for the test
  int _remainingTime = 30;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
  }

  void _startTest() {
    setState(() {
      symbols = List.from(symbolToDigit.keys);
      symbols.shuffle();
      userAnswers = List.generate(symbols.length, (index) => ''); // Initialize empty answers
      score = 0;
      _remainingTime = _timeLimit;
      isTesting = true;
      isCompleted = false;
    });

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer.cancel();
          isTesting = false;
          isCompleted = true;
          _calculateScore();
        }
      });
    });
  }

  void _calculateScore() {
    int correctCount = 0;
    for (int i = 0; i < symbols.length; i++) {
      if (userAnswers[i] == symbolToDigit[symbols[i]]) {
        correctCount++;
      }
    }
    setState(() {
      score = correctCount;
    });
  }

  void _onTileTap(int index) {
    String? selectedNumber;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter the number for the symbol'),
          content: Wrap(
            spacing: 10,
            children: List.generate(10, (number) {
              return ChoiceChip(
                label: Text(
                  number.toString(),
                  style: const TextStyle(fontSize: 18),
                ),
                selected: selectedNumber == number.toString(),
                onSelected: (bool selected) {
                  setState(() {
                    selectedNumber = number.toString();
                  });
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedNumber != null) {
                  setState(() {
                    userAnswers[index] = selectedNumber!;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symbol Digit Modalities Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Persistent instructions
            const Column(
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'In this test, you will be shown symbols. Your task is to identify the number associated with each symbol. Tap a tile to select the number. You will have 30 seconds to complete the test.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
              ],
            ),
            if (isTesting) ...[
              const Text(
                'Symbol to Number Mapping:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: symbolToDigit.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key} -> ${entry.value}',
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Time Remaining: $_remainingTime seconds'),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: symbols.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () => _onTileTap(index),
                      child: Card(
                        color: Colors.blueAccent,
                        child: Center(
                          child: Text(
                            userAnswers[index].isEmpty
                                ? symbols[index]
                                : '${symbols[index]} (${userAnswers[index]})',
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (!isTesting && !isCompleted)
              ElevatedButton(
                onPressed: _startTest,
                child: const Text('Start Test'),
              ),
            if (isCompleted)
              Column(
                children: [
                  const Text(
                    'Test Completed!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your Score: $score',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startTest,
                    child: const Text('Restart Test'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
