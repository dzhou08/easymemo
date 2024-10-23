import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class RatingCircleChart extends StatelessWidget {
  final double currentRating; // Current rating value
  final double maxRating; // Maximum rating value

  const RatingCircleChart({required this.currentRating, required this.maxRating});

  @override
  Widget build(BuildContext context) {
    double percentage = currentRating / maxRating;

    return Center(
      child: CircularPercentIndicator(
        radius: 60.0, // Size of the circular chart
        lineWidth: 10.0, // Width of the circular line
        percent: percentage, // Rating percentage (value between 0.0 and 1.0)
        center: Text(
          "${(percentage * 100).toStringAsFixed(1)}%", 
          //($currentRating out of $maxRating)", // Display percentage text
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        progressColor: Colors.purple, // Color for the progress indicator
        backgroundColor: Colors.grey.shade300, // Color for the background line
        circularStrokeCap: CircularStrokeCap.round, // Make the stroke ends round
      ),
    );
  }
}
