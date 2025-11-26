import 'package:flutter/material.dart';

// --- Theme Constants ---
const Color ownerPrimaryColor = Color(0xFF1E88E5); // Blue
const Color faintBackground = Color(0xFFF9F9FB);
const double cardRadius = 12.0;

// --- Data Model for Visitor ---
class Visitor {
  final String name;
  final String unit;
  final String purpose;
  final bool isApproved;
  final String time;

  Visitor({
    required this.name,
    required this.unit,
    required this.purpose,
    required this.isApproved,
    required this.time,
  });
}

// --- Metric Card Widget (Helper) ---
class MetricCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and Title
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Value
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- OwnerDashboardPage (Now Stateful) ---
class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  // Simulated Dashboard Data
  final List<Visitor> _allVisitors = [
    Visitor(
      name: 'Delivery Guy (Amazon)',
      unit: '402',
      purpose: 'Package Drop',
      isApproved: true,
      time: '11:30 AM',
    ),
    Visitor(
      name: 'HVAC Technician',
      unit: '201',
      purpose: 'Repair AC Unit',
      isApproved: true,
      time: '10:15 AM',
    ),
    Visitor(
      name: 'Sarah Connor',
      unit: '305',
      purpose: 'Social Visit',
      isApproved: false,
      time: '09:50 AM',
    ),
    Visitor(
      name: 'Landscaper Team',
      unit: 'Common',
      purpose: 'Maintanence',
      isApproved: true,
      time: '08:00 AM',
    ),
    Visitor(
      name: 'Pizza Delivery',
      unit: '103',
      purpose: 'Food Delivery',
      isApproved: true,
      time: '07:45 AM',
    ),
  ];

  // Calculated Metrics
  int get _totalVisitors => _allVisitors.length;
  int get _approvedRequests => _allVisitors.where((v) => v.isApproved).length;
  int get _pendingRequests => _allVisitors.where((v) => !v.isApproved).length;

  // Color/Icon constants for status chips
  Color _getStatusColor(bool isApproved) =>
      isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
  IconData _getStatusIcon(bool isApproved) =>
      isApproved ? Icons.check_circle_outline : Icons.access_time;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: faintBackground,
      appBar: AppBar(
        title: const Text(
          'Owner Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        backgroundColor: ownerPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Section ---
            const Text(
              'Good Afternoon, Owner!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 25),

            // --- Metrics Grid ---
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                // 1. Total Visitors Metric (Using calculated value)
                MetricCard(
                  title: 'Total Logged Visitors (Today)',
                  value: _totalVisitors,
                  icon: Icons.groups_2_outlined,
                  color: ownerPrimaryColor,
                ),

                // 2. Approved Requests Metric (Using calculated value)
                MetricCard(
                  title: 'Approved Entry Requests',
                  value: _approvedRequests,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF4CAF50),
                ),

                // 3. Pending Requests Metric (Using calculated value)
                MetricCard(
                  title: 'Pending Approvals',
                  value: _pendingRequests,
                  icon: Icons.access_time_filled,
                  color: const Color(0xFFFF9800),
                ),

                // 4. Notifications/Quick Action
                MetricCard(
                  title: 'New Notifications',
                  value: 3,
                  icon: Icons.notifications_none,
                  color: const Color(0xFFE53935),
                ),
              ],
            ),

            const SizedBox(height: 35),
            const Divider(),
            const SizedBox(height: 15),

            // --- Total Visitor List Header ---
            const Text(
              'All Visitor Logs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),

            // --- Total Visitor List ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allVisitors.length,
              itemBuilder: (context, index) {
                final visitor = _allVisitors[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ownerPrimaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.person_outline,
                        color: ownerPrimaryColor,
                      ),
                    ),
                    title: Text(
                      visitor.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Unit ${visitor.unit} | Purpose: ${visitor.purpose}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Chip
                        Chip(
                          avatar: Icon(
                            _getStatusIcon(visitor.isApproved),
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            visitor.isApproved ? 'Approved' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _getStatusColor(visitor.isApproved),
                        ),
                        const SizedBox(width: 8),
                        // Time stamp
                        Text(
                          visitor.time,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
