import 'package:flutter/material.dart';
import 'dart:math';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  _MatchingPageState createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  // List of cards with their values (images or words)
  final List<String> _cardValues = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', // Unique values for cards
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', // Duplicate values for matching
  ];

  // List of flipped cards (true means the card is flipped over)
  final List<bool> _flippedCards = List.generate(16, (_) => false);

  // List to store the card values that have been revealed
  final List<String?> _revealedCards = List.generate(16, (_) => null);

  int? _firstCardIndex; // Track the index of the first flipped card
  int? _secondCardIndex; // Track the index of the second flipped card

  // Function to shuffle the cards
  void _shuffleCards() {
    _cardValues.shuffle(Random());
  }

  // Function to handle card flip
  void _flipCard(int index) {
    if (_flippedCards[index] || _firstCardIndex == index || _secondCardIndex == index) return;

    setState(() {
      _flippedCards[index] = true;
      _revealedCards[index] = _cardValues[index];

      // If it's the first card being flipped
      if (_firstCardIndex == null) {
        _firstCardIndex = index;
      } 
      // If it's the second card being flipped
      else if (_secondCardIndex == null) {
        _secondCardIndex = index;

        // Check if the two cards match
        if (_revealedCards[_firstCardIndex!] == _revealedCards[_secondCardIndex!]) {
          // Cards match, reset the flipped indexes
          _firstCardIndex = null;
          _secondCardIndex = null;
        } else {
          // Cards don't match, flip them back after a delay
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              _flippedCards[_firstCardIndex!] = false;
              _flippedCards[_secondCardIndex!] = false;
              _firstCardIndex = null;
              _secondCardIndex = null;
            });
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _shuffleCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Matching Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // Grid with 4 columns
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 16, // Total number of cards (8 pairs)
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _flipCard(index),
              child: Card(
                color: Colors.blueGrey,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: _flippedCards[index]
                      ? Text(
                          _revealedCards[index]!,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : Container(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
