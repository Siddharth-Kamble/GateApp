// lib/src/ui/guard/GuardDashboard.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:flutter_application_1/src/ui/guard/add_vehicle/register_vehicle.dart';
import 'package:flutter_application_1/src/ui/guard/add_visitor/register_visit.dart';
import 'package:flutter_application_1/src/ui/guard/employeeGatepass/employeeGatepass.dart'
    show EmployeeGatePassPage;
import 'package:flutter_application_1/src/ui/owner/employee_pass_list_page.dart';
import 'package:flutter_application_1/src/services/fcm_service.dart';
import 'package:flutter_application_1/src/ui/shared/role_selection.dart'
    show RoleSelectionPage;

// ---------------- Colors for Guard UI ----------------
const Color _guardPrimary = Color(0xFF1565C0);
const Color _guardPrimaryDark = Color(0xFF0D47A1);
const Color _guardBackground = Color(0xFFF4F6FB);

// ---------------- Local Notifications ----------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class GuardDashboard extends StatefulWidget {
  final UserModel loggedInUser;
  const GuardDashboard({super.key, required this.loggedInUser});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final List<String> _alertedPasses = [];

  @override
  void initState() {
    super.initState();
    _initLocalNotification();
  }

  void _initLocalNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pass_approval_channel',
      'Pass Approval',
      channelDescription: 'Notification for approved passes',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> _notifyOwner(String ownerId, String title, String body) async {
    try {
      final ownerSnapshot =
          await firebaseFirestore.collection('users').doc(ownerId).get();
      final ownerFCMToken = ownerSnapshot.data()?['fcmToken'];
      if (ownerFCMToken != null) {
        await FCMService().sendPushNotification(
          token: ownerFCMToken,
          title: title,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('Error sending notification to owner: $e');
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guardUserId'); // stored on login
    } catch (e) {
      debugPrint('Error during logout: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _guardBackground,
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_guardPrimaryDark, _guardPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Security Gate Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuardHeaderCard(
                name: widget.loggedInUser.name ?? 'Security Guard',
                location: 'Main Gate',
              ),
              const SizedBox(height: 24),

              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _guardPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Row 1 ----------
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Visitor Pass',
                      description: 'Issue new entry pass for visitors.',
                      color: Colors.green.shade700,
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterVisit(
                              guardUid: widget.loggedInUser.uid!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.directions_car_outlined,
                      title: 'Vehicle Registration',
                      description: 'Log new or temporary vehicle access.',
                      color: Colors.blue.shade700,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterVehicle(
                              loggedInGuard: widget.loggedInUser,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------- Row 2 ----------
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.badge_outlined,
                      title: 'Employee Gate Pass',
                      description: 'Submit employee gate pass requests.',
                      color: Colors.orange.shade700,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeeGatePassPage(
                              guardId: widget.loggedInUser.uid!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.list_alt,
                      title: 'View Employee Passes',
                      description: 'See submitted employee gate passes.',
                      color: Colors.purple.shade700,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmployeePassListPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Recent Gate Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _guardPrimaryDark,
                ),
              ),
              const SizedBox(height: 12),

              _ActivityCard(
                firebaseFirestore: firebaseFirestore,
                alertedPasses: _alertedPasses,
                showNotification: _showNotification,
                loggedInGuardUid: widget.loggedInUser.uid!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Profile Header Card ----------------
class _GuardHeaderCard extends StatelessWidget {
  final String name;
  final String location;

  const _GuardHeaderCard({required this.name, required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('lib/src/assets/guardlogo.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Icon(Icons.security, size: 18, color: _guardPrimary),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Security Guard • $location',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.lightGreenAccent),
        ],
      ),
    );
  }
}

// ---------------- Quick Action Card ----------------
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Card(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: color.withOpacity(0.9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Activity Card ----------------
class _ActivityCard extends StatefulWidget {
  final FirebaseFirestore firebaseFirestore;
  final List<String> alertedPasses;
  final Function(String, String) showNotification;
  final String loggedInGuardUid;

  const _ActivityCard({
    required this.firebaseFirestore,
    required this.alertedPasses,
    required this.showNotification,
    required this.loggedInGuardUid,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  String selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _guardPrimary;

    Stream<QuerySnapshot<Map<String, dynamic>>> stream;

    if (selectedFilter == 'all') {
      stream = widget.firebaseFirestore.collection('passes').snapshots();
    } else {
      stream = widget.firebaseFirestore
          .collection('passes')
          .where('type', isEqualTo: selectedFilter)
          .snapshots();
    }

    return Card(
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: _guardPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gate Activity (${selectedFilter == "all" ? "All" : selectedFilter == "visitor" ? "Visitors" : "Vehicles"})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedFilter,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                        value: 'visitor', child: Text('Visitors')),
                    DropdownMenuItem(
                        value: 'vehicle', child: Text('Vehicles')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedFilter = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: LinearProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading activity: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No recent gate activity has been recorded.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                final sorted = docs.toList()
                  ..sort((a, b) {
                    final ta = (a.data()['createdAt'] as Timestamp?);
                    final tb = (b.data()['createdAt'] as Timestamp?);
                    if (ta == null && tb == null) return 0;
                    if (ta == null) return 1;
                    if (tb == null) return -1;
                    return tb.compareTo(ta);
                  });

                final top = sorted.length > 5 ? sorted.sublist(0, 5) : sorted;

                for (var doc in top) {
                  final data = doc.data();
                  final status =
                      data['status']?.toString().toLowerCase() ?? 'pending';
                  final id = doc.id;

                  if (status == 'approved' &&
                      !widget.alertedPasses.contains(id)) {
                    widget.alertedPasses.add(id);

                    FlutterRingtonePlayer().play(
                      android: AndroidSounds.notification,
                      ios: IosSounds.glass,
                      looping: false,
                      volume: 1.0,
                      asAlarm: false,
                    );

                    widget.showNotification(
                      'Pass Approved',
                      '${data['ownerName'] ?? data['name'] ?? 'Guest'} is approved',
                    );
                  }
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top.length,
                  itemBuilder: (context, index) {
                    final data = top[index].data();
                    final type = data['type'] ?? 'visitor';
                    final name =
                        data['ownerName'] ?? data['name'] ?? 'Unknown Guest';
                    final status =
                        data['status']?.toString().toLowerCase() ?? 'pending';
                    final bool isApproved = status == 'approved';
                    final bool isDeclined = status == 'declined';
                    final bool isEntered = data['isEntered'] == true;

                    String statusText;
                    Color statusColor;

                    if (isEntered) {
                      statusText = 'Entered';
                      statusColor = Colors.blue.shade700;
                    } else if (isDeclined) {
                      statusText = 'Declined';
                      statusColor = Colors.red.shade700;
                    } else if (isApproved) {
                      statusText = 'Approved';
                      statusColor = Colors.green.shade700;
                    } else {
                      statusText = 'Pending';
                      statusColor = Colors.orange.shade700;
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    primaryColor.withOpacity(0.1),
                                child: Icon(
                                  type == 'vehicle'
                                      ? Icons.local_shipping_outlined
                                      : Icons.person_pin_circle_outlined,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${type[0].toUpperCase()}${type.substring(1)}: $name',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Button on the right side
                              if (isApproved && !isEntered)
                                ElevatedButton(
                                  onPressed: () async {
                                    await widget.firebaseFirestore
                                        .collection('passes')
                                        .doc(top[index].id)
                                        .update({'isEntered': true});
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text('Allow Entry'),
                                ),
                            ],
                          ),
                        ),
                        if (index < top.length - 1)
                          const Divider(height: 1, indent: 64),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
