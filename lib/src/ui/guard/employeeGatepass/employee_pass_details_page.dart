import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeePassDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String documentId;
  final bool isGuard;

  const EmployeePassDetailsPage({
    super.key,
    required this.data,
    required this.documentId,
    this.isGuard = false, // ✅ DEFAULT VALUE
  });

  @override
  State<EmployeePassDetailsPage> createState() =>
      _EmployeePassDetailsPageState();
}
class _EmployeePassDetailsPageState extends State<EmployeePassDetailsPage> {
  DateTime? inTime; // Variable to store in-time
  bool isCheckedIn = false; // Flag to disable the Check In button after tap

  // Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Get the inTime from Firestore if it exists when the page is opened
    _getInTime();
  }

  // Fetch the inTime from Firestore
  Future<void> _getInTime() async {
  try {
    final doc = await firestore
        .collection('employee_gate_pass')
        .doc(widget.documentId)
        .get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    if (data.containsKey('inTime') && data['inTime'] != null) {
      setState(() {
        inTime = (data['inTime'] as Timestamp).toDate();
        isCheckedIn = true;
      });
    } else {
      // ✅ No error — employee not checked in
      setState(() {
        inTime = null;
        isCheckedIn = false;
      });
    }
  } catch (e) {
    // ❌ Only show error if Firestore REALLY fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to fetch check-in data")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.data['imageUrl'] ?? '';
    final DateTime? createdAt = widget.data['createdAt'] as DateTime?;
    final String dateTime = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Employee Gate Pass Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 IMAGE (TAP TO FULL SCREEN)
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _openImageFullScreen(context, imageUrl),
                child: Hero(
                  tag: imageUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              _noImage(),

            const SizedBox(height: 20),

            _info("Employee Name", widget.data['employeeName'] ?? "-"),
            _info("Employee ID", widget.data['employeeId'] ?? "-"),
            _info("Reason", widget.data['reason'] ?? "-"),
            _info("Status", widget.data['status'] ?? "-"),
            _info("Date", dateTime),

            // 🕒 In-Time
            const SizedBox(height: 20),
            _buildInTime(),

            const SizedBox(height: 120),

            // Check In Button (Disabled after being tapped)
          if (widget.isGuard) // ✅ SHOW ONLY FOR GUARD
  Center(
    child: ElevatedButton(
      onPressed: isCheckedIn ? null : _checkIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isCheckedIn
          ? const Text("Checked In")
          : const Text(
              "Check In",
              style: TextStyle(color: Colors.white),
            ),
    ),
  ),

          ],
        ),
      ),
    );
  }

  // Method to handle the check-in time and save it to Firestore
  void _checkIn() async {
    setState(() {
      inTime = DateTime.now(); // Capture the current time as the "in-time"
      isCheckedIn = true;  // Disable button after tap
    });

    try {
      // Update the document in Firestore with the captured in-time
      await firestore.collection('employee_gate_pass').doc(widget.documentId).update({
        'inTime': inTime, // Save in-time field in Firestore
      });

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("In-time saved successfully!")),
      );
    } catch (e) {
      // If something goes wrong, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving in-time: $e")),
      );
    }
  }

  // Build the In-Time info box
Widget _buildInTime() {
  return Row(
    children: [
      const Text(
        "In Time: ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(
        inTime != null
            ? DateFormat('hh:mm a').format(inTime!)
            : "Employee is not checked in yet",
        style: TextStyle(
          color: inTime != null ? Colors.black : Colors.grey.shade600,
          fontStyle: inTime != null ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    ],
  );
}

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _noImage() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported, size: 40),
            SizedBox(height: 8),
            Text("No Image Available"),
          ],
        ),
      ),
    );
  }

  // 📌 FULL SCREEN IMAGE VIEW
  void _openImageFullScreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: Hero(
              tag: url,
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
