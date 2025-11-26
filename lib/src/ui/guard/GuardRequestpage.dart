import 'package:flutter/material.dart';

enum EntryType { visitor, delivery, cab }

class GuardRequestStatusPage extends StatelessWidget {
  final String requestId;
  final String primaryInfo;
  final EntryType type;

  const GuardRequestStatusPage({
    super.key,
    required this.requestId,
    required this.primaryInfo,
    required this.type,
  });

  // Convert enum to user-friendly text
  String getTypeText(EntryType type) {
    switch (type) {
      case EntryType.visitor:
        return "Visitor";
      case EntryType.delivery:
        return "Delivery";
      case EntryType.cab:
        return "Cab";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Status")),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Request ID: $requestId",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Info: $primaryInfo",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  "Type: ${getTypeText(type)}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Approve logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request Approved')),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Deny logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request Denied')),
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Deny"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
