import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'env_config.dart';
import 'dart:convert';
import 'util.dart';

class TriviaQuestion {
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String answer;

  TriviaQuestion({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.answer,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      question: json['Question'],
      optionA: json['A'],
      optionB: json['B'],
      optionC: json['C'],
      optionD: json['D'],
      answer: json['Answer'],
    );
  }
}

class TriviaPage extends StatefulWidget {
  const TriviaPage({super.key});

  @override
  _TriviaPageState createState() => _TriviaPageState();
}

class _TriviaPageState extends State<TriviaPage> {
  String selectedAnswer = '';
  String? _content = '';
  String? _token = '';
  late List<TriviaQuestion> _triviaQuestions = [];

  void checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
    });
  }
  
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _fetchTriviaQuestions();
  }

  Future<void> _fetchTriviaQuestions() async {
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    final token = authProvider.getAccessToken();

    if (token != null) {
      final content = await authProvider.searchFilesByName(token, 'memo', true);
      print(content);
      setState(() {
        _content = content;
      });
      final questions = await generateTriviaWithGPT();
      setState(() {
        _triviaQuestions = questions;
        selectedAnswer = '';
      });
    }
  }

  Future<List<TriviaQuestion>> generateTriviaWithGPT() async {

    final openAI = OpenAI.instance.build(
      token: EnvConfig.openAIApiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 30)),
      enableLog: true
    );
    
    final requestText = ChatCompleteText(
      messages: [
        Map.of({"role": "system", "content": "You are a helpful Trivia master."}),
        Map.of({"role": "user", "content": [
              {
                "type": "text", 
                "text":
                '''
                Fenerate one trivia questions based on the provided content below.
                For the question, provide one correct answer based on the content, 
                and three distractor answers. 
                Output the trivia questions and answers in the following format as JSON Array, 
                even if there is just one question:
                Question: What is the capital of France?
                A. Berlin
                B. Madrid
                C. Paris
                D. Rome
                Answer: C. Paris
                '''
              },
              {
                "type": "text", 
                "text": _content!,
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

    answer = answer.replaceAll('```json', '').replaceAll('```', '').trim();
    print('GPT Response after: $answer');
    
    // Parse the JSON array
    List<dynamic> jsonData = jsonDecode(answer);
    List<TriviaQuestion> questions = jsonData.map((item) => TriviaQuestion.fromJson(item)).toList();
    return questions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia Game'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_triviaQuestions.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              Expanded(
                child: ListView.builder(
                      itemCount: _triviaQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _triviaQuestions[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.question,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            ListTile(
                              title: Text('A. ${question.optionA}'),
                              leading: Radio<String>(
                                value: 'A. ${question.optionA}',
                                groupValue: selectedAnswer,
                                onChanged: (value) {
                                  checkAnswer(value!);
                                },
                              ),
                            ),
                            ListTile(
                              title: Text('B. ${question.optionB}'),
                              leading: Radio<String>(
                                value: 'B. ${question.optionB}',
                                groupValue: selectedAnswer,
                                onChanged: (value) {
                                  checkAnswer(value!);
                                },
                              ),
                            ),
                            ListTile(
                              title: Text('C. ${question.optionC}'),
                              leading: Radio<String>(
                                value: 'C. ${question.optionC}',
                                groupValue: selectedAnswer,
                                onChanged: (value) {
                                  checkAnswer(value!);
                                },
                              ),
                            ),
                            ListTile(
                              title: Text('D. ${question.optionD}'),
                              leading: Radio<String>(
                                value: 'D. ${question.optionD}',
                                groupValue: selectedAnswer,
                                onChanged: (value) {
                                  checkAnswer(value!);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (selectedAnswer.isNotEmpty)
                              Text(
                                selectedAnswer == question.answer
                                    ? 'Correct! The answer is ${question.answer}.'
                                    : 'Incorrect. The correct answer is ${question.answer}.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: selectedAnswer == question.answer ? Colors.green : Colors.red,
                                ),
                              ),
                            const Divider(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10), // Adjust the height as needed
              ElevatedButton(
                onPressed: () {
                  _fetchTriviaQuestions(); // Call the method to fetch new questions
                },
                child: Text('New Question'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}