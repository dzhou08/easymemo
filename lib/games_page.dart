import 'package:flutter/material.dart';

// Define each game page (e.g., SDMT, Stroop)
import 'games_minicog_page.dart';
import 'games_sdmt_page.dart';
import 'games_stroop_page.dart';
import 'games_puzzle_page.dart';
import 'games_matching_page.dart';
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
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: kIsWeb
                        ? MediaQuery.of(context).size.width * 0.4
                        : MediaQuery.of(context).size.width * 0.8,
                    child: Column(
                      children: [
                        // Remove Expanded here
                        GridView.builder(
                          shrinkWrap: true, // Allow GridView to take only necessary space
                          physics: NeverScrollableScrollPhysics(), // Disable GridView's scrolling, it will be handled by SingleChildScrollView
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: 5, // Number of games available
                          itemBuilder: (context, index) {
                            return GameTile(index: index);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isExpandedVisible = !_isExpandedVisible;
                    });
                  },
                  child: Text(_isExpandedVisible ? 'Hide Test Result' : 'Show Test Result'),
                ),
                Visibility(
                  visible: _isExpandedVisible,
                  child: Column(
                    children: [ 
                      const SizedBox(height: 20),
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

                      // draw a scatter chart to show the score trend
                      // Placeholder for the chart
                      Container(
                        height: 400,
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
    'SDMT Test',
    'Stroop Test',
    'Memory Matching',
    'Puzzle Game',
  ];

  // Define game icons
  final List<IconData> gameIcons = [
    Icons.medical_information,
    Icons.numbers,
    Icons.color_lens,
    Icons.games,
    Icons.image,
  ];

  // Define game routes for navigation
  final List<Widget> gameRoutes = [
    const MiniCogPage(),
    const SDMTPage(),
    const StroopPage(),
    const MatchingPage(),
    const PuzzlePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the game page based on tile index
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => gameRoutes[index]),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              gameIcons[index],
              size: 50,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 10),
            Text(
              gameTitles[index],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}