
    // Photo by <a href="https://unsplash.com/@leajourniac?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Léa Journiac</a> 
    // on <a href="https://unsplash.com/photos/a-white-dog-is-jumping-in-the-air-5eAmYBA9eV0?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
    // Split the image into 9 pieces
import 'package:flutter/material.dart';

class PuzzlePage extends StatefulWidget {
  @override
  _PuzzlePageState createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  // A list to store the draggable images
  List<String> draggableImages = List.generate(9, (index) {
    int row = index ~/ 3;
    int col = index % 3;
    return 'assets/images/grid_${row}_${col}.jpg';
  });

  // A 2D list to store the grid images for the 3x3 grid
  List<List<String?>> gridImages = List.generate(3, (i) => List<String?>.filled(3, null));

  // Method to restart the game
  void restartGame() {
    setState(() {
      // Reset the grid images to null
      gridImages = List.generate(3, (i) => List<String?>.filled(3, null));
      // Optionally shuffle the draggable images again if desired
      draggableImages = List.generate(9, (index) {
        int row = index ~/ 3;
        int col = index % 3;
        return 'assets/images/grid_${row}_${col}.jpg';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Grid Puzzle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Instruction text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Drag and drop the images into the 3x3 grid below. Enjoy the smiling Shiba Ino picture!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            // Draggable images section
            Center(
              child: Container(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return Draggable<String>(
                            data: draggableImages[index],
                            feedback: Image.asset(
                              draggableImages[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                              ),
                              child: Image.asset(
                                draggableImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // 3x3 grid section
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      int row = index ~/ 3;
                      int col = index % 3;
                      return DragTarget<String>(
                        onAccept: (droppedImagePath) {
                          setState(() {
                            gridImages[row][col] = droppedImagePath;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              color: Colors.grey[100],
                            ),
                            child: gridImages[row][col] != null
                                ? Image.asset(
                                    gridImages[row][col]!,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      '',//'Row: $row\nCol: $col',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            //SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Align buttons horizontally in the center
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Calculate the score
                    int score = 0;
                    for (int row = 0; row < 3; row++) {
                      for (int col = 0; col < 3; col++) {
                        if (gridImages[row][col] == 'assets/images/grid_${row}_${col}.jpg') {
                          score++;
                        }
                      }
                    }
                    // Show the score
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Score'),
                        content: Text('Your score is $score/9'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Confirm Selection'),
                ),
                SizedBox(width: 16), // Add some space between the buttons
                ElevatedButton(
                  onPressed: restartGame,
                  child: Text('Reset'),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }
}
