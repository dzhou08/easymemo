import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';


class DateDisplay extends StatefulWidget {
  const DateDisplay({super.key});

  
  @override
  _DateDisplayState createState() => _DateDisplayState();
}

class _DateDisplayState extends State<DateDisplay> {

  final Logger _logger = Logger('home_date_display');

  void _setupLogging() {
    Logger.root.level = Level.ALL; // Log everything
    Logger.root.onRecord.listen((LogRecord rec) {
      _logger.info('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<GAuthProvider>(context);
    final String? token = authProvider.getAccessToken();

  }
  @override
  void initState() {
    super.initState();
    _setupLogging();
  }

  @override
  Widget build(BuildContext context) {

    var now = DateTime.now();
    var morningAfternoon = now.hour < 12 ? "Morning" : now.hour < 16? "Afternoon": "Evening";
    var dateWeek = DateFormat('EEEEE', 'en_US').format(now);
    var hourMin = DateFormat("h:mm a", "en_US").format(now);
    var yearDay = DateFormat("MMM dd, yyyy", "en_US").format(now);        
    
    return Center(
      child: Card(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
            Text(dateWeek, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 3.0), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(morningAfternoon, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(hourMin, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 4.0), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(yearDay, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0), textAlign: TextAlign.center),
        ],
      ),
      ),
    );
  }
}
