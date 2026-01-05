import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// Models
import '../../models/user_model.dart';

// Pages (make sure paths are correct)
import 'add_vehicle/register_vehicle.dart';
import 'add_visitor/register_visit.dart';

class GuardDashboard extends StatelessWidget {
  final UserModel loggedInUser;

  GuardDashboard({super.key, required this.loggedInUser});

  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Guard Dashboard'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // ---- Cards Row ----
              Row(
                children: [
                  Expanded(
                    child: _DashboardCard(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Add Visitor',
                      subtitle: 'Register visitor details.',
                      buttonText: 'Add Visitor',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterVisit()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DashboardCard(
                      icon: Icons.directions_car,
                      title: 'Add Vehicle',
                      subtitle: 'Register vehicle details.',
                      buttonText: 'Add Vehicle',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterVehicle()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---- Activity Card ----
              _ActivityCard(firebaseFirestore: firebaseFirestore),

              const SizedBox(height: 24),

              // ---- Guard Info ----
              Text(
                '${loggedInUser.firstName ?? ''} ${loggedInUser.secondName ?? ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Guard',
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

/// ----------------------------------------------
/// DASHBOARD CARD WIDGET
/// ----------------------------------------------
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

/// ----------------------------------------------
/// ACTIVITY CARD – SHOW PASSES APPROVED/WAITING
/// ----------------------------------------------
class _ActivityCard extends StatelessWidget {
  final FirebaseFirestore firebaseFirestore;

  const _ActivityCard({required this.firebaseFirestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firebaseFirestore
          .collection('passes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text('No requests yet.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final name = data['name'] ?? 'Unknown';
            final type = data['type'] ?? 'visitor';
            final isApproved = data['isApproved'] == true;
            final status = isApproved ? 'Approved' : 'Pending';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text('$type: $name'),
                subtitle: Text('Status: $status'),
                trailing: isApproved
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Allow Entry (visitor & vehicle)
          if (data['isEntered'] != true)
            ElevatedButton(
              onPressed: () {
                firebaseFirestore
                    .collection('passes')
                    .doc(docs[index].id)
                    .update({'isEntered': true});
              },
              child: const Text('Allow Entry'),
            ),

          // spacing between buttons
          if (data['isEntered'] == true && data['isExited'] != true)
            const SizedBox(width: 8),

          // Allow Exit (visitor & vehicle)
          if (data['isEntered'] == true && data['isExited'] != true)
            ElevatedButton(
              onPressed: () {
                firebaseFirestore
                    .collection('passes')
                    .doc(docs[index].id)
                    .update({'isExited': true});
              },
              child: const Text('Allow Exit'),
            ),
        ],
      )
    : null,

              ),
            );
          },
        );
      },
    );
  }
}
