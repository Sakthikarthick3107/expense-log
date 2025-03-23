import 'package:expense_log/models/upi.dart';
import 'package:expense_log/services/upi_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpiLogs extends StatefulWidget {
  const UpiLogs({super.key});

  @override
  State<UpiLogs> createState() => _UpiLogsState();
}

class _UpiLogsState extends State<UpiLogs> {

  late UpiService _upiService;

  @override
  void initState(){
    super.initState();
    _upiService = Provider.of<UpiService>(context , listen: false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<UpiLog>>(
        future: _upiService.getAllLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No UPI logs available.'));
          } else {
            // If logs are available, display them in a ListView
            final logs = snapshot.data!;
            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(log.message), // Display the message
                  subtitle: Text(log.timestamp.toString()), // Optionally, display the timestamp
                );
              },
            );
          }
        },
      ),
    );
  }
}
