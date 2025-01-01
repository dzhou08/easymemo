import 'package:flutter/material.dart';

// Define each game page (e.g., SDMT, Stroop)
import 'games_minicog_page.dart';
import 'games_sdmt_page.dart';
import 'games_stroop_page.dart';
import 'games_puzzle_page.dart';
import 'games_matching_page.dart';
import 'games_trivia_page.dart';
import 'games_picture_recall_page.dart';
import 'util.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class CognitiveGamesPage extends StatefulWidget {
  const CognitiveGamesPage({super.key});

  @override
  _CognitiveGamesPageState createState() => _CognitiveGamesPageState();
}

class _CognitiveGamesPageState extends State<CognitiveGamesPage> {
  bool _isExpandedVisible = false;
  String _scoreGameType = 'sdmt';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cognitive Games'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: kIsWeb
                      ? MediaQuery.of(context).size.width * 0.4
                      : MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 450, 
                        child: ListView.builder(// Allow GridView to take only necessary space
                          itemCount: 6, // Number of games available
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                const SizedBox(height: 20),
                                GameTile(index: index), // Add space between each GameTile
                              ],
                            );
                          },
                        ),
                      ),
                      Divider(
                        indent: 20,
                        endIndent: 20,
                        thickness: 2,
                        color: Colors.purple,
                      ), // Add a divider between items
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isExpandedVisible = !_isExpandedVisible;
                          });
                        },
                        child: Text(_isExpandedVisible ? 'Hide Test Result' : 'Show Test Result'),
                      ),
                      if (_isExpandedVisible)
                        Visibility(
                          visible: _isExpandedVisible,
                          child: Column(
                            children: [ 
                              const SizedBox(height: 10),
                              // add a dropdown menu
                              DropdownButton<String>(
                                value: _scoreGameType,
                                items: <String>['sdmt', 'stroop', 'mini-cog'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text("Show $value Test Score"),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    // Update the selected game
                                    _scoreGameType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              // draw a scatter chart to show the score trend
                              // Placeholder for the chart
                              Container(
                                height: 350,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: FutureBuilder<List<List<dynamic>>>(
                                  future: authProvider.readGameScore(_scoreGameType),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(child: Text('Error: ${snapshot.error}'));
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return Center(child: Text('No data available'));
                                    } else {
                                      List<List<dynamic>> testResults = snapshot.data!;
                                      // Calculate the maximum score
                                      double maxScore = testResults
                                          .map((entry) => double.parse(entry[2]))
                                          .reduce((a, b) => a > b ? a : b);

                                      // Group scores by days away from today and calculate frequency within each group
                                      DateTime today = DateTime.now();
                                      Map<int, Map<double, int>> daysAwayScoreFrequency = {};
                                      for (var entry in testResults) {
                                        DateTime dateTime = DateTime.parse(entry[0]);
                                        int daysAway = today.difference(dateTime).inDays;
                                        double score = double.parse(entry[2]);

                                        if (!daysAwayScoreFrequency.containsKey(daysAway)) {
                                          daysAwayScoreFrequency[daysAway] = {};
                                        }

                                        if (daysAwayScoreFrequency[daysAway]!.containsKey(score)) {
                                          daysAwayScoreFrequency[daysAway]![score] =
                                              daysAwayScoreFrequency[daysAway]![score]! + 1;
                                        } else {
                                          daysAwayScoreFrequency[daysAway]![score] = 1;
                                        }
                                      }

                                      return Center(
                                        child: ScatterChart(
                                          ScatterChartData(
                                            scatterSpots: testResults
                                                .map((entry) {
                                                  DateTime dateTime = DateTime.parse(entry[0]);
                                                  double daysAway = today.difference(dateTime).inDays.toDouble();
                                                  double score = double.parse(entry[2]);
                                                  double radius =
                                                      (daysAwayScoreFrequency[daysAway.toInt()]![score] ?? 1) * 2.0; // Adjust the multiplier as needed
                                                  return ScatterSpot(
                                                    daysAway,
                                                    score,
                                                    dotPainter: FlDotCirclePainter(
                                                      color: Colors.blue,
                                                      radius: radius * 2,
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                            gridData: FlGridData(show: true),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(fontSize: 10),
                                                    );
                                                  },
                                                ),
                                                axisNameWidget: const Padding(
                                                  padding: EdgeInsets.only(left: 4.0),
                                                  child: Text('Score', style: TextStyle(fontSize: 12)),
                                                ),
                                              ),
                                              rightTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(fontSize: 10),
                                                    );
                                                  },
                                                  interval: 5, // Only one tick per day
                                                ),
                                                axisNameWidget: const Padding(
                                                  padding: EdgeInsets.only(top: 1.0),
                                                  child: Text('Days Away', style: TextStyle(fontSize: 12)),
                                                ),
                                              ),
                                              topTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false), // Hide top titles
                                              ),
                                            ),
                                            borderData: FlBorderData(show: true),
                                            minX: 0, // Set minimum value for the x-axis (days away)
                                            maxX: 30, // Set maximum value for the x-axis (days away)
                                            minY: 0, // Set minimum value for the y-axis (score)
                                            maxY: maxScore, // Set maximum value for the y-axis (score)
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ]
                          ),
                        ),
                    ],
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}

class GameTile extends StatelessWidget {
  final int index;

  GameTile({super.key, required this.index});

  // Define game titles
  final List<String> gameTitles = [
    'Mini-Cog™ Test',
    'Trivia Game',
    'Picture Recall',
    'SDMT Test',
    'Stroop Test',
    'Puzzle Game',
    'Memory Match',
  ];

  // Define game icons
  final List<IconData> gameIcons = [
    Icons.medical_information,
    Icons.question_answer,
    Icons.picture_as_pdf,
    Icons.numbers,
    Icons.color_lens,
    Icons.wysiwyg,
    Icons.games,
  ];

  // Define game routes for navigation
  final List<Widget> gameRoutes = [
    const MiniCogPage(),
    const TriviaPage(),
    const PictureRecallPage(),
    const SDMTPage(),
    const StroopPage(),
    const PuzzlePage(),
    const MatchingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Add padding for better spacing
            alignment: Alignment.center, // Align content to the center
          ),
          onPressed: () {
            // Navigate to the game page based on tile index
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => gameRoutes[index]),
            );
          },
          child:  Row(
          mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gameIcons[index],
              size: 15,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(width: 20),
            Text(
              gameTitles[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
  }
}