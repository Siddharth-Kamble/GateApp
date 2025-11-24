import 'package:flutter/material.dart';

// IMPORTANT: Using your specific import paths for the pages
import 'package:flutter_application_1/src/ui/guard/purpose.dart'
    show VisitorEntryPage;
import 'package:flutter_application_1/src/ui/guard/vehicleEntryPage.dart'
    show VehicleEntryPage;

// --- Theme Constants ---
const Color primaryGuardColor = Color(0xFF00ACC1);
const Color faintBackground = Color(0xFFF9F9FB);
const Color vehicleAccentColor = Color(0xFFFFB300);
const Color successColor = Color(0xFF4CAF50);
const Color pendingColor = Color(0xFFFF9800);
const double cardRadius = 16.0;

// --- Activity Model (Data Structure) ---
class ActivityLog {
  final String name;
  final String type; // e.g., 'Visitor' or 'Vehicle'
  final bool isApproved;
  final String time;

  ActivityLog({
    required this.name,
    required this.type,
    required this.isApproved,
    required this.time,
  });
}

// --- ActionCard Widget (Helper) ---
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- GuardHomePage (The Main Page - Now Stateful) ---
class GuardHomePage extends StatefulWidget {
  const GuardHomePage({super.key});

  @override
  State<GuardHomePage> createState() => _GuardHomePageState();
}

class _GuardHomePageState extends State<GuardHomePage> {
  // 💡 STATE DATA: Simulated Log Entries
  final List<ActivityLog> _activityLogs = [
    ActivityLog(
      name: 'John Doe',
      type: 'Visitor',
      isApproved: true,
      time: '10:05 AM',
    ),
    ActivityLog(
      name: 'Vehicle ABC-123',
      type: 'Vehicle',
      isApproved: false,
      time: '09:50 AM',
    ),
    ActivityLog(
      name: 'Jane Smith',
      type: 'Visitor',
      isApproved: true,
      time: '09:40 AM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: faintBackground,
      appBar: AppBar(
        title: const Text(
          'Guard Console',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Quick Actions Header ---
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryGuardColor,
              ),
            ),
            const SizedBox(height: 20),

            // --- Action Grid (Visitor and Vehicle) ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: [
                // 1. ADD VISITOR
                ActionCard(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Add Visitor',
                  color: primaryGuardColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VisitorEntryPage(),
                      ),
                    );
                  },
                ),

                // 2. ADD VEHICLE
                ActionCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Add Vehicle',
                  color: vehicleAccentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleEntryPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // --- Current Activity Log Header ---
            const Text(
              'Current Activity Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),

            // 💡 LOG DATA DISPLAY
            _activityLogs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No recent activity logged.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activityLogs.length,
                    itemBuilder: (context, index) {
                      final log = _activityLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: log.isApproved
                                ? successColor.withOpacity(0.5)
                                : pendingColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: log.type == 'Visitor'
                                ? primaryGuardColor.withOpacity(0.1)
                                : vehicleAccentColor.withOpacity(0.1),
                            child: Icon(
                              log.type == 'Visitor'
                                  ? Icons.person
                                  : Icons.directions_car,
                              color: log.type == 'Visitor'
                                  ? primaryGuardColor
                                  : vehicleAccentColor,
                            ),
                          ),
                          title: Text(
                            log.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${log.type} | ${log.time}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: log.isApproved
                                  ? successColor
                                  : pendingColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              log.isApproved ? 'APPROVED' : 'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
