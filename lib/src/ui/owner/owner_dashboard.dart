import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:flutter_application_1/src/services/gate_pass_export_service.dart'
    show GatePassExportService, ExportDateFilter, ExportProgress;
import 'package:flutter_application_1/src/ui/guard/Entry_Details/entry_details_page.dart'
    show EntryDetailsPage;
import 'package:flutter_application_1/src/ui/guard/employeeGatepass/employee_pass_details_page.dart'
    show EmployeePassDetailsPage;
import 'package:flutter_application_1/src/ui/shared/role_selection.dart'
    show RoleSelectionPage;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/src/ui/owner/owner_login_page.dart';

class OwnerDashboard extends StatefulWidget {
  final UserModel loggedInOwner;

  const OwnerDashboard({super.key, required this.loggedInOwner});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final GatePassExportService _exportService;

  String selectedFilter = "All";
  String employeeFilter = "All";

  final Color purple = const Color(0xFF6A1B9A);
  IconData _getVehicleIcon(String? vehicleType) {
    switch (vehicleType) {
      case 'Two Wheeler':
        return Icons.two_wheeler;
      case 'Four Wheeler':
        return Icons.directions_car;
      case 'Auto Rickshaw':
        return Icons.electric_rickshaw; // 🛺 best icon
      case 'Truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  @override
  void initState() {
    super.initState();
    _initPushNotifications();
    _exportService = GatePassExportService(); // ✅ ADD
  }

  @override
  void dispose() {
    _exportService.dispose(); // close stream controller
    super.dispose();
  }

  // ---------------- PUSH NOTIFICATION ----------------
  Future<void> _initPushNotifications() async {
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await firestore.collection("users").doc(widget.loggedInOwner.uid).set({
        "fcmToken": token,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) {
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: n.title ?? "",
          body: n.body ?? "",
          payload: message.data,
        );
      }
    });
  }

  // ---------------- UI ----------------
  Future<void> _showExportDatePicker() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Single Date'),
              onTap: () => Navigator.pop(_, 'single'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              onTap: () => Navigator.pop(_, 'range'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    DateTime? from;
    DateTime? to;

    if (choice == 'single') {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (date == null) return;
      from = date;
      to = date;
    } else {
      from = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (from == null) return;

      to = await showDatePicker(
        context: context,
        initialDate: from,
        firstDate: from,
        lastDate: DateTime.now(),
      );
      if (to == null) return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Confirm Export'),
            content: Text(
              from == to
                  ? 'Download data for ${DateFormat('dd MMM yyyy').format(from!)}?'
                  : 'Download data from '
                      '${DateFormat('dd MMM yyyy').format(from!)} '
                      'to ${DateFormat('dd MMM yyyy').format(to!)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(_, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(_, true),
                child: const Text('Download'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final filter = ExportDateFilter(fromDate: from, toDate: to);
    await _exportService.export(filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 117, 8, 154),
          elevation: 1,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                (route) => false,
              );
            },
          ),
          title: StreamBuilder<ExportProgress>(
            stream: _exportService.progressStream,
            builder: (_, snap) {
              final p = snap.data?.progress ?? 0.0;

              return Text(
                p > 0 && p < 1
                    ? 'Exporting ${(p * 100).toInt()}%'
                    : 'Owner Dashboard',
                style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.archive),
              tooltip: 'Download Gate Pass ZIP',
              color: Colors.white,
              onPressed: _showExportDatePicker,
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              color: Colors.white,
              onPressed: _downloadEmployeePassesCsv,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.white,
              onPressed: _logoutOwner,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<ExportProgress>(
                  stream: _exportService.progressStream,
                  builder: (_, snap) {
                    final p = snap.data?.progress ?? 0.0;
                    if (p <= 0 || p >= 1) return const SizedBox(height: 4);

                    return LinearProgressIndicator(
                      value: p,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
                const TabBar(
  labelColor: Colors.white,
  unselectedLabelColor: Colors.white70,
  indicatorColor: Colors.white, // optional underline
  tabs: const [
    Tab(text: "Visitor / Vehicle"),
    Tab(text: "Employee Passes"),
  ],
)
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [_buildVisitorVehicleTab(), _buildEmployeePassTab()],
        ),
      ),
    );
  }

  // ---------------- VISITOR / VEHICLE ----------------
  Widget _buildVisitorVehicleTab() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: selectedFilter,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "All", child: Text("All")),
              DropdownMenuItem(value: "Pending", child: Text("Pending")),
              DropdownMenuItem(value: "Approved", child: Text("Approved")),
              DropdownMenuItem(value: "Declined", child: Text("Declined")),
              DropdownMenuItem(value: "Entered", child: Text("Entered")),
              DropdownMenuItem(value: "Exited", child: Text("Exited")),
            ],
            onChanged: (v) => setState(() => selectedFilter = v!),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore
                .collection("passes")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = _applyFilter(snap.data!.docs);

              if (docs.isEmpty) {
                return const Center(child: Text("No requests"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data();
                  final id = docs[i].id;
                  final vehicleType = d["vehicleType"]?.toString();

                  final status =
                      (d["status"] ?? "pending").toString().toLowerCase();
                  final isPending = status == "pending";
                  final isDeclined = status == "declined";
                  final isEntered = d["isEntered"] == true;
                  final isExited = d["isExited"] == true;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EntryDetailsPage(
                            passId: id,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🧿 ICON or IMAGE for JCB
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: purple.withOpacity(0.1),
                              child: vehicleType == 'JCB'
                                  ? Image.asset(
                                      'lib/src/assets/jcb.jpg', // JCB image path
                                      width: 30, // Adjust size as needed
                                      height: 30,
                                    )
                                  : Icon(
                                      d["type"] == "vehicle"
                                          ? _getVehicleIcon(vehicleType)
                                          : Icons.person,
                                      color: purple,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (d["type"] == "vehicle" &&
                                      (d["driverName"] ?? "")
                                          .toString()
                                          .isNotEmpty)
                                    Text("Driver: ${d["driverName"]}"),
                                  if (d["type"] == "vehicle" &&
                                      (d["vehicleNumber"] ?? "")
                                          .toString()
                                          .isNotEmpty)
                                    Text("Vehicle No: ${d["vehicleNumber"]}"),
                                  if (d["type"] == "visitor" &&
                                      (d["name"] ?? "").toString().isNotEmpty)
                                    Text("Visitor: ${d["name"]}"),
                                  if (d["type"] == "visitor" &&
                                      (d["reason"] ?? "").toString().isNotEmpty)
                                    Text("Reason: ${d["reason"]}"),
                                  Text("Type: ${d["type"] ?? ""}"),
                                  const SizedBox(height: 6),
                                  _buildStatusLabel(
                                      status, isEntered, isExited),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: _buildActionButtons(
                                isPending,
                                status == "approved",
                                isDeclined,
                                id,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- EMPLOYEE PASSES ----------------
  Widget _buildEmployeePassTab() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: employeeFilter,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "All", child: Text("All")),
              DropdownMenuItem(value: "Today", child: Text("Today")),
              DropdownMenuItem(value: "This Month", child: Text("This Month")),
            ],
            onChanged: (v) => setState(() => employeeFilter = v!),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore
                .collection("employee_gate_pass")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snap.data!.docs;
              final now = DateTime.now();

              docs = docs.where((doc) {
                final t = (doc["createdAt"] as Timestamp?)?.toDate() ?? now;
                if (employeeFilter == "Today") {
                  return DateFormat("yyyy-MM-dd").format(t) ==
                      DateFormat("yyyy-MM-dd").format(now);
                }
                if (employeeFilter == "This Month") {
                  return t.year == now.year && t.month == now.month;
                }
                return true;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No employee passes"));
              }

              return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d =
                        docs[i].data(); // Get data from Firestore document
                    final createdAt =
                        (d["createdAt"] as Timestamp?)?.toDate() ??
                            DateTime.now(); // Extract createdAt timestamp
                    final documentId = docs[i].id; // Get the documentId

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeePassDetailsPage(
                              data: {
                                ...d, // pass all existing employee pass fields
                                "createdAt":
                                    createdAt, // ensure DateTime is passed
                              },
                              documentId:
                                  documentId,
                                  isGuard: false, // Pass documentId to EmployeePassDetailsPage
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // 🧿 ICON or IMAGE for Employee (Badge Icon)
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: purple
                                    .withOpacity(0.1), // Non-constant value
                                child: Icon(
                                  Icons.badge,
                                  color: purple, // Non-constant value
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d["employeeName"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text("Employee ID: ${d["employeeId"]}"),
                                    Text("Reason: ${d["reason"] ?? ""}"),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat("dd MMM yyyy, hh:mm a")
                                          .format(createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            },
          ),
        ),
      ],
    );
  }

  // ---------------- HELPERS ----------------
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (selectedFilter == "All") return docs;

    return docs.where((d) {
      final status = (d["status"] ?? "").toString().toLowerCase();

      // Null check for isEntered and isExited fields
      final isEntered =
          d.data().containsKey('isEntered') ? d["isEntered"] : false;
      final isExited = d.data().containsKey('isExited') ? d["isExited"] : false;

      // Entered but NOT exited
      if (selectedFilter == "Entered") {
        return isEntered == true && isExited != true;
      }

      // Exited only
      if (selectedFilter == "Exited") {
        return isExited == true;
      }

      // Approved but NOT entered or exited
      if (selectedFilter == "Approved") {
        return status == "approved" && isEntered == false && isExited == false;
      }

      // Pending
      if (selectedFilter == "Pending") {
        return status == "pending";
      }

      return status == selectedFilter.toLowerCase();
    }).toList();
  }

  Widget _buildStatusLabel(String status, bool entered, bool exited) {
    if (exited) return _chip("Exited", Colors.grey.shade700);
    if (entered) return _chip("Entered", Colors.blue);
    if (status == "approved") return _chip("Approved", Colors.green);
    if (status == "declined") return _chip("Declined", Colors.red);
    return _chip("Pending", Colors.orange);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    bool isPending,
    bool isApproved,
    bool isDeclined,
    String id,
  ) {
    if (isPending) {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => _updatePassStatus(id, "approved"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(90, 34),
            ),
            child: const Text("Approve",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                )),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () => _updatePassStatus(id, "declined"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(90, 34),
            ),
            child: const Text("Decline",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                )),
          ),
        ],
      );
    }

    if (isDeclined) {
      return ElevatedButton(
        onPressed: () => _updatePassStatus(id, "approved"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text("Approve Again",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            )),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _updatePassStatus(String id, String status) async {
    final Map<String, dynamic> updateData = {
      "status": status,
    };

    // ✅ IF APPROVED
    if (status == "approved") {
      updateData.addAll({
        "approvedByName": widget.loggedInOwner.name,
        "approvedById": widget.loggedInOwner.uid,
        "approvedAt": FieldValue.serverTimestamp(),
        "isApproved": true,
        // optional: clear decline info if re-approved
        "declinedByName": FieldValue.delete(),
        "declinedById": FieldValue.delete(),
        "declinedAt": FieldValue.delete(),
      });
    }

    // ❌ IF DECLINED
    if (status == "declined") {
      updateData.addAll({
        "declinedByName": widget.loggedInOwner.name,
        "declinedById": widget.loggedInOwner.uid,
        "declinedAt": FieldValue.serverTimestamp(),
        "isApproved": false,
        // optional: clear approval info if declined after approval
        "approvedByName": FieldValue.delete(),
        "approvedById": FieldValue.delete(),
        "approvedAt": FieldValue.delete(),
      });
    }

    await firestore.collection("passes").doc(id).update(updateData);
  }

  // ---------------- CSV DOWNLOAD ----------------
  Future<void> _downloadEmployeePassesCsv() async {
    final snap = await firestore.collection("employee_gate_pass").get();

    if (snap.docs.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/employee_passes.csv");

    // ✅ CSV HEADING (UPPERCASE = LOOKS BOLD)
    String csvData = "EMPLOYEE NAME,EMPLOYEE ID,REASON\n";

    for (var doc in snap.docs) {
      csvData +=
          "${doc["employeeName"]},${doc["employeeId"]},${doc["reason"]}\n";
    }

    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: "Employee Gate Passes");
  }

  // ---------------- LOGOUT ----------------
  Future<void> _logoutOwner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("owner_uid");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OwnerLoginPage()),
      (_) => false,
    );
  }
}
