import 'package:flutter/material.dart';
import 'package:vms/model/user_model.dart';
import 'package:vms/model/pass_model.dart';
import 'package:vms/screens/visitor/register_visit.dart';
import 'package:vms/screens/vehical/register_vehical.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class VisitorDashboard extends StatelessWidget {
  final UserModel loggedInUser;

  VisitorDashboard({Key? key, required this.loggedInUser}) : super(key: key);

  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  Future<List<PassModel>> getUserActivePasses() async {
    final res = await firebaseFirestore
        .collection('passes')
        .where('userId', isEqualTo: loggedInUser.uid ?? 'error')
        .where('isActive', isEqualTo: true)
        .get();

    return res.docs.map((e) => PassModel.fromMap(e.id, e.data())).toList();
  }

  Future<List<PassModel>> getUserAllPasses() async {
    final res = await firebaseFirestore
        .collection('passes')
        .where('userId', isEqualTo: loggedInUser.uid ?? 'error')
        .get();

    return res.docs.map((e) => PassModel.fromMap(e.id, e.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- PAGE TITLE ----
              Text(
                'Gate Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Quick actions to manage visitors and vehicles at the gate.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // ------ 2 main cards row ------
              Row(
                children: [
                  Expanded(
                    child: _DashboardCard(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Add Visitor',
                      subtitle:
                          'Register a new visitor entry for any flat / owner.',
                      buttonText: 'Add Visitor',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterVisit(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DashboardCard(
                      icon: Icons.directions_car_filled_outlined,
                      title: 'Add Vehicle',
                      subtitle:
                          'Record vehicle / material details entering or leaving.',
                      buttonText: 'Add Vehicle',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterVehical(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ------ Today's activity card (LIVE) ------
              _ActivityCard(
                firebaseFirestore: firebaseFirestore,
                userId: loggedInUser.uid,
              ),

              const SizedBox(height: 24),

              // ---- User info at bottom ----
              Text(
                '${loggedInUser.firstName ?? ''} ${loggedInUser.secondName ?? ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Visitor',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable dashboard card
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _DashboardCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Today's activity" card – reads today's passes for this user
class _ActivityCard extends StatelessWidget {
  final FirebaseFirestore firebaseFirestore;
  final String? userId;

  const _ActivityCard({
    Key? key,
    required this.firebaseFirestore,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (userId == null) {
      return _buildShell(
        context,
        const Text('No user found.'),
      );
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firebaseFirestore
          .collection('passes')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShell(
            context,
            Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading today\'s activity...'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildShell(
            context,
            const Text('No activity for today yet.'),
          );
        }

        // Filter only today's docs
        final todaysDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final ts = data['createdAt'];
          if (ts == null || ts is! Timestamp) return false;
          final dt = ts.toDate();
          return dt.year == todayStart.year &&
              dt.month == todayStart.month &&
              dt.day == todayStart.day;
        }).toList();

        if (todaysDocs.isEmpty) {
          return _buildShell(
            context,
            const Text('No activity for today yet.'),
          );
        }

        // Take latest 3
        final limited = todaysDocs.take(3).toList();

        return _buildShell(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: limited.map((doc) {
              final data = doc.data();
              final name = (data['name'] ?? 'Unknown visitor') as String;
              final reason =
                  (data['location'] ?? 'No reason provided') as String;
              final ts = data['createdAt'] as Timestamp?;
              final timeStr = ts != null
                  ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
                  : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            reason,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildShell(BuildContext context, Widget child) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                Text(
                  "Today's activity",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
