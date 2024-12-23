import 'package:flutter/material.dart';

// Define each game page (e.g., SDMT, Stroop)
import 'games_sdmt_page.dart';
import 'games_stroop_page.dart';
import 'games_puzzle_page.dart';
import 'games_matching_page.dart';

class CognitiveGamesPage extends StatelessWidget {
  const CognitiveGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cognitive Games')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5, // Set width to 60% of screen width
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 4, // Number of games available
              itemBuilder: (context, index) {
                return GameTile(index: index);
              },
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
    'SDMT Test',
    'Stroop Test',
    'Memory Matching',
    'Puzzle Game',
  ];

  // Define game icons
  final List<IconData> gameIcons = [
    Icons.numbers,
    Icons.color_lens,
    Icons.games,
    Icons.image,
  ];

  // Define game routes for navigation
  final List<Widget> gameRoutes = [
    SDMTPage(), // Replace with actual SDMT test widget
    StroopPage(), // Replace with actual Stroop test widget
    MatchingPage(), // Replace with actual memory matching widget
    PuzzlePage(), // Replace with actual puzzle game widget
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
