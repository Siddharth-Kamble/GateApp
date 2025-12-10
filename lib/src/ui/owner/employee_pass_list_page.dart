import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeePassListPage extends StatefulWidget {
  const EmployeePassListPage({super.key});

  @override
  State<EmployeePassListPage> createState() => _EmployeePassListPageState();
}

class _EmployeePassListPageState extends State<EmployeePassListPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String searchQuery = "";
  String sortOrder = "Latest";
  String dateFilter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Passes (Owner Panel)"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name or employee ID",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.trim().toLowerCase());
              },
            ),
          ),

          // 🔽 SORT + FILTER ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // SORT
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: sortOrder,
                    items: const [
                      DropdownMenuItem(value: "Latest", child: Text("Latest")),
                      DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => sortOrder = v);
                    },
                    decoration: const InputDecoration(
                      labelText: "Sort",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // DATE FILTER
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: dateFilter,
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All")),
                      DropdownMenuItem(value: "Today", child: Text("Today")),
                      DropdownMenuItem(
                        value: "ThisWeek",
                        child: Text("This Week"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => dateFilter = v);
                    },
                    decoration: const InputDecoration(
                      labelText: "Filter",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 MAIN LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore
                  .collection("employee_gate_pass")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text("No employee passes found"));
                }

                var docs = snap.data!.docs;

                // SEARCH
                docs = docs.where((d) {
                  final data = d.data();
                  final name =
                      (data["employeeName"] ?? "").toString().toLowerCase();
                  final empId =
                      (data["employeeId"] ?? "").toString().toLowerCase();

                  if (searchQuery.isEmpty) return true;

                  return name.contains(searchQuery) ||
                      empId.contains(searchQuery);
                }).toList();

                // DATE FILTER
                docs = _applyDateFilter(docs);

                // SORT (Latest/Oldest)
                if (sortOrder == "Oldest") {
                  docs = docs.reversed.toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No matching records"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final data = docs[index].data();
                    final timestamp = data["createdAt"]?.toDate();
                    final imageUrl = (data["imageUrl"] ?? "").toString();
                    final name = (data["employeeName"] ?? "").toString();
                    final empId = (data["employeeId"] ?? "").toString();
                    final reason = (data["reason"] ?? "").toString();

                    return _buildPassCard(
                      context: context,
                      name: name,
                      empId: empId,
                      reason: reason,
                      timestamp: timestamp,
                      imageUrl: imageUrl,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 📌 DATE FILTER
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyDateFilter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (dateFilter == "All") return docs;

    final now = DateTime.now();

    return docs.where((d) {
      final data = d.data();
      final ts = data["createdAt"]?.toDate();
      if (ts == null) return false;

      if (dateFilter == "Today") {
        return ts.year == now.year &&
            ts.month == now.month &&
            ts.day == now.day;
      }

      if (dateFilter == "ThisWeek") {
        return now.difference(ts).inDays < 7;
      }

      return true;
    }).toList();
  }

  // 📌 PASS CARD UI
  Widget _buildPassCard({
    required BuildContext context,
    required String name,
    required String empId,
    required String reason,
    required DateTime? timestamp,
    required String imageUrl,
  }) {
    final isToday = timestamp != null &&
        timestamp.year == DateTime.now().year &&
        timestamp.month == DateTime.now().month &&
        timestamp.day == DateTime.now().day;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _openImageFullScreen(context, imageUrl),
          child: Hero(
            tag: imageUrl.isNotEmpty ? imageUrl : "$name-$empId-$timestamp",
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.shade100,
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.photo, color: Colors.deepOrange)
                  : null,
            ),
          ),
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isToday)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Today",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Employee ID: $empId"),
            if (reason.isNotEmpty) Text("Reason: $reason"),
            if (timestamp != null)
              Text(
                "Date: ${timestamp.toString().substring(0, 16)}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 📌 FULL SCREEN IMAGE POPUP
  void _openImageFullScreen(BuildContext context, String url) {
    if (url.isEmpty) return;

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
