import 'package:flutter/material.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});

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
      gridImages = List.generate(3, (i) => List<String?>.filled(3, null));
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
        title: const Text('Image Grid Puzzle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Drag and drop the images into the 3x3 grid below. Enjoy the smiling Shiba Inu picture!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: draggableImages.length,
                        itemBuilder: (context, index) {
                          return Draggable<String>(
                            data: draggableImages[index],
                            feedback: Image.asset(
                              draggableImages[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            childWhenDragging: const SizedBox(),
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
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
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      int row = index ~/ 3;
                      int col = index % 3;
                      return DragTarget<String>(
                        onWillAccept: (data) => true,
                        onAcceptWithDetails: (details) {
                          setState(() {
                            if (gridImages[row][col] != null) {
                              draggableImages.add(gridImages[row][col]!);
                            }
                            gridImages[row][col] = details.data;
                            draggableImages.remove(details.data);
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              color: Colors.grey[100],
                            ),
                            child: gridImages[row][col] != null
                                ? Draggable<String>(
                                    data: gridImages[row][col]!,
                                    feedback: Image.asset(
                                      gridImages[row][col]!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                    childWhenDragging: const SizedBox(),
                                    onDragCompleted: () {
                                      setState(() {
                                        draggableImages.add(gridImages[row][col]!);
                                        gridImages[row][col] = null;
                                      });
                                    },
                                    child: Image.asset(
                                      gridImages[row][col]!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const SizedBox(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    int score = 0;
                    for (int row = 0; row < 3; row++) {
                      for (int col = 0; col < 3; col++) {
                        if (gridImages[row][col] == 'assets/images/grid_${row}_${col}.jpg') {
                          score++;
                        }
                      }
                    }
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Score'),
                        content: Text('Your score is ${score}/9'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Confirm Selection'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: restartGame,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
