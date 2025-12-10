import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: Update this import path as per your project structure
import 'package:flutter_application_1/src/ui/owner/owner_login_page.dart';

// TODO: Update this import path & class as per your project structure
import 'package:flutter_application_1/src/ui/shared/role_selection.dart';

class OwnerDashboard extends StatefulWidget {
  final UserModel loggedInOwner;

  const OwnerDashboard({super.key, required this.loggedInOwner});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String selectedFilter = "All";
  String employeeFilter = "All";
  final Color purple = const Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: WillPopScope(
        // 🔙 Android back button -> RoleSelectionPage (not exit app)
        onWillPop: () async {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => RoleSelectionPage(), // change if different
            ),
            (route) => false,
          );
          return false; // prevent default pop (which closes app)
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            elevation: 2,
            backgroundColor: purple,
            systemOverlayStyle: SystemUiOverlayStyle.light,

            // 🔙 AppBar back button -> RoleSelectionPage
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: "Back to roles",
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoleSelectionPage(), // change if needed
                  ),
                  (route) => false,
                );
              },
            ),

            title: const Text(
              "Owner Dashboard",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              // 🔔 NOTIFICATION BADGE FOR PENDING VISITOR/VEHICLE REQUESTS
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestore
                    .collection("passes")
                    .where("status", isEqualTo: "pending")
                    .snapshots(),
                builder: (context, snap) {
                  int pendingCount = 0;
                  if (snap.hasData) {
                    pendingCount = snap.data!.docs.length;
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        tooltip: "Pending approvals",
                        onPressed: _openPendingRequests,
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pendingCount > 99
                                  ? "99+"
                                  : pendingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                tooltip: "Download Employee Pass Report",
                onPressed: _downloadEmployeePassesCsv,
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: "Logout",
                onPressed: _logoutOwner,
              ),
              const SizedBox(width: 10),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: purple,
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: purple,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: "Visitor / Vehicle"),
                      Tab(text: "Employee Passes"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildVisitorVehicleTab(theme),
              _buildEmployeePassTab(theme),
            ],
          ),
        ),
      ),
    );
  }

  // 🔔 When owner taps notification icon -> go to Visitor tab + Pending filter
  void _openPendingRequests() {
    final controller = DefaultTabController.of(context);
    if (controller != null) {
      controller.animateTo(0); // first tab (Visitor / Vehicle)
    }

    setState(() {
      selectedFilter = "Pending";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Showing pending visitor/vehicle requests"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // -------------------- LOGOUT --------------------
  Future<void> _logoutOwner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // ✅ Clear saved owner UID so next time login screen opens
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('owner_uid');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const OwnerLoginPage(),
      ),
      (route) => false,
    );
  }

  // -------------------- VISITOR / VEHICLE --------------------
  Widget _buildVisitorVehicleTab(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  "Filter",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "All",
                        child: Text("All Requests"),
                      ),
                      DropdownMenuItem(
                        value: "Pending",
                        child: Text("Pending"),
                      ),
                      DropdownMenuItem(
                        value: "Approved",
                        child: Text("Approved"),
                      ),
                      DropdownMenuItem(
                        value: "Declined",
                        child: Text("Declined"),
                      ),
                      DropdownMenuItem(
                        value: "Entered",
                        child: Text("Entered"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => selectedFilter = v);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore
                .collection("passes")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              var docs = _applyFilter(snap.data!.docs);
              if (docs.isEmpty) {
                return const Center(
                  child: Text("No matching requests"),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data();
                  final id = docs[i].id;
                  final type = (d["type"] ?? "visitor").toString();
                  final name = (d["name"] ?? "").toString();
                  final ownerName = (d["ownerName"] ?? "").toString();
                  final vehicleNumber = (d["vehicleNumber"] ?? "").toString();
                  final vehicleType = (d["vehicleType"] ?? "").toString();
                  final reason = (d["reason"] ?? "").toString();
                  final status =
                      (d["status"] ?? "pending").toString().toLowerCase();
                  final isApproved = status == "approved";
                  final isDeclined = status == "declined";
                  final isPending = status == "pending";
                  final isEntered = d["isEntered"] == true;

                  IconData vehicleIcon = Icons.directions_car;
                  Color bgColor = purple.withOpacity(0.12);

                  if (type != "vehicle") {
                    vehicleIcon = Icons.person;
                    bgColor = Colors.green.withOpacity(0.12);
                  } else {
                    switch (vehicleType.toLowerCase()) {
                      case "truck":
                        vehicleIcon = Icons.local_shipping;
                        bgColor = Colors.orange.withOpacity(0.12);
                        break;
                      case "bike":
                        vehicleIcon = Icons.motorcycle;
                        bgColor = Colors.blue.withOpacity(0.12);
                        break;
                      default:
                        vehicleIcon = Icons.directions_car;
                        bgColor = purple.withOpacity(0.12);
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: bgColor,
                          child: Icon(vehicleIcon, color: purple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (type == "vehicle")
                                Text(
                                  "$ownerName - $vehicleNumber (${vehicleType.capitalizeSafe()})",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                "Type: $type",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              if (reason.isNotEmpty)
                                Text(
                                  "Reason: $reason",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              _buildStatusLabel(status, isEntered),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButtons(
                          isPending,
                          isApproved,
                          isDeclined,
                          id,
                        ),
                      ],
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

  // -------------------- EMPLOYEE PASS --------------------
  Widget _buildEmployeePassTab(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  "Filter",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: employeeFilter,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "All",
                        child: Text("All"),
                      ),
                      DropdownMenuItem(
                        value: "Today",
                        child: Text("Today"),
                      ),
                      DropdownMenuItem(
                        value: "This Month",
                        child: Text("This Month"),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => employeeFilter = v);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore
                .collection("employee_gate_pass")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              var docs = snap.data!.docs;
              DateTime now = DateTime.now();
              String today = DateFormat("yyyy-MM-dd").format(now);
              String month = DateFormat("yyyy-MM").format(now);

              docs = docs.where((doc) {
                var t = (doc.data()["createdAt"] as Timestamp?)?.toDate();
                if (t == null) return false;
                if (employeeFilter == "Today") {
                  return DateFormat("yyyy-MM-dd").format(t) == today;
                }
                if (employeeFilter == "This Month") {
                  return DateFormat("yyyy-MM").format(t) == month;
                }
                return true;
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No matching employee passes"),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data();
                  final name = (d["employeeName"] ?? "").toString();
                  final empId = (d["employeeId"] ?? "").toString();
                  final reason = (d["reason"] ?? "").toString();
                  final imageUrl = (d["imageUrl"] ?? "").toString();
                  final createdAt =
                      (d["createdAt"] as Timestamp?)?.toDate() ??
                          DateTime.now();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: imageUrl.isEmpty
                                  ? null
                                  : () => _openFullImage(
                                        context,
                                        imageUrl,
                                      ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: purple.withOpacity(0.12),
                                backgroundImage: imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: imageUrl.isEmpty
                                    ? Icon(Icons.badge, color: purple)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("Employee ID: $empId"),
                        if (reason.isNotEmpty) Text("Reason: $reason"),
                        Text(
                          "Date: ${DateFormat("dd MMM yyyy, hh:mm a").format(createdAt)}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (imageUrl.isNotEmpty)
                          GestureDetector(
                            onTap: () => _openFullImage(
                              context,
                              imageUrl,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
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

  // -------------------- FILTER --------------------
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (selectedFilter == "All") return docs;

    return docs.where((doc) {
      final d = doc.data();
      final status = (d["status"] ?? "pending").toString().toLowerCase();
      final isEntered = d["isEntered"] == true;

      if (selectedFilter == "Pending") return status == "pending";
      if (selectedFilter == "Approved") return status == "approved";
      if (selectedFilter == "Declined") return status == "declined";
      if (selectedFilter == "Entered") return isEntered;

      return true;
    }).toList();
  }

  // -------------------- STATUS LABEL --------------------
  Widget _buildStatusLabel(String status, bool entered) {
    Color color;
    if (entered) return _chip("Entered", Colors.blue);

    final s = (status).toLowerCase();

    if (s == "approved") {
      color = Colors.green;
    } else if (s == "declined") {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return _chip(s.capitalizeSafe(), color);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
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

  // -------------------- ACTION BUTTONS --------------------
  Widget _buildActionButtons(
    bool pending,
    bool approved,
    bool declined,
    String id,
  ) {
    if (approved) return const SizedBox.shrink();

    if (pending) {
      return Column(
        children: [
          _actionButton(id, "Approve", Colors.green, true),
          const SizedBox(height: 8),
          _actionButton(id, "Decline", Colors.red, false),
        ],
      );
    }

    if (declined) {
      return _actionButton(id, "Approve Again", Colors.green, true);
    }

    return const SizedBox.shrink();
  }

  Widget _actionButton(
    String id,
    String text,
    Color color,
    bool approve,
  ) {
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        onPressed: () {
          firestore.collection("passes").doc(id).update({
            "status": approve ? "approved" : "declined",
            "isApproved": approve,
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(text),
      ),
    );
  }

  // -------------------- FULL IMAGE --------------------
  void _openFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- ANDROID VERSION UTILITY --------------------
  Future<int> _getAndroidVersion() async {
    try {
      final sdkInt = await const MethodChannel(
        'flutter/platform',
      ).invokeMethod<int>('getSdkInt');
      return sdkInt ?? 33;
    } catch (_) {
      return 33;
    }
  }

  // -------------------- DOWNLOAD CSV --------------------
  Future<void> _downloadEmployeePassesCsv() async {
    final filter = await showDialog<_ExportFilter>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Export Employee Passes"),
        content: const Text("Choose which passes to export:"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExportFilter.all),
            child: const Text("All"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExportFilter.today),
            child: const Text("Today"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExportFilter.month),
            child: const Text("This Month"),
          ),
        ],
      ),
    );

    if (filter == null) return;

    try {
      // ------------------ ANDROID PERMISSION ------------------
      if (Platform.isAndroid) {
        final sdk = await _getAndroidVersion();
        if (sdk < 30) {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Storage permission denied"),
                ),
              );
              return;
            }
          }
        }
      }

      // ------------------ FETCH DATA ------------------
      final snap = await firestore
          .collection("employee_gate_pass")
          .orderBy("createdAt", descending: true)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No employee passes found")),
        );
        return;
      }

      // ------------------ BUILD CSV ------------------
      final buffer = StringBuffer();
      buffer.writeln(
        'Employee Name,Employee ID,Reason,Date,Time,Status,Image URL',
      );

      final now = DateTime.now();
      final todayStr = DateFormat("yyyy-MM-dd").format(now);
      final monthStr = DateFormat("yyyy-MM").format(now);

      for (var doc in snap.docs) {
        final d = doc.data();

        final createdAt = (d["createdAt"] as Timestamp?)?.toDate();
        final createdDateStr =
            createdAt != null ? DateFormat("yyyy-MM-dd").format(createdAt) : "";
        final createdDateDisplay = createdAt != null
            ? DateFormat("dd MMM yyyy").format(createdAt)
            : "";
        final createdTimeDisplay =
            createdAt != null ? DateFormat("hh:mm a").format(createdAt) : "";

        if (filter == _ExportFilter.today && createdDateStr != todayStr) {
          continue;
        }
        if (filter == _ExportFilter.month &&
            (createdDateStr.isEmpty ||
                createdDateStr.substring(0, 7) != monthStr)) {
          continue;
        }

        final name = (d["employeeName"] ?? "").toString();
        final empId = (d["employeeId"] ?? "").toString();
        final reason = (d["reason"] ?? "").toString();
        final status = (d["status"] ?? "").toString();
        final image = (d["imageUrl"] ?? "").toString();

        String esc(String s) {
          final safe = s.replaceAll('"', '""');
          return '"$safe"';
        }

        buffer.writeln(
          [
            esc(name),
            esc(empId),
            esc(reason),
            esc(createdDateDisplay),
            esc(createdTimeDisplay),
            esc(status),
            esc(image),
          ].join(','),
        );
      }

      // ------------------ SAVE FILE ------------------
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to access storage directory"),
          ),
        );
        return;
      }

      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (_) {}
      }

      final timestamp = DateFormat("yyyyMMdd_HHmmss").format(DateTime.now());
      final fileName = "employee_pass_report_$timestamp.csv";
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("CSV saved at: $filePath")));

      try {
        await OpenFilex.open(filePath);
      } catch (_) {}
      try {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: "Employee Pass Report",
        );
      } catch (_) {}
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text("Error saving CSV: $e")),
      );
    }
  }
}

// -------------------- EXPORT FILTER ENUM --------------------
enum _ExportFilter { all, today, month }

// -------------------- STRING EXTENSION --------------------
extension Cap on String {
  String capitalizeSafe() =>
      isEmpty ? "" : "${this[0].toUpperCase()}${substring(1)}";
}
