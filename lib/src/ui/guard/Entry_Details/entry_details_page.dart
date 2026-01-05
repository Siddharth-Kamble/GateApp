import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EntryDetailsPage extends StatelessWidget {
  final String passId;

  const EntryDetailsPage({
    super.key,
    required this.passId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('passes')
            .doc(passId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Entry not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildUI(context, data);
        },
      ),
    );
  }

  // ================== UI ==================
  Widget _buildUI(BuildContext context, Map<String, dynamic> data) {
    final bool isVehicle = data['type'] == 'vehicle';
    final bool isExited = data['isExited'] == true;

    final exitedAt = (data['exitedAt'] as Timestamp?)?.toDate();
    final exitDateTime = exitedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(exitedAt)
        : 'N/A';

    final String? imageUrl = data['imageUrl'];
    final String? frontImageUrl = data['frontImageUrl'];
    final String? backImageUrl = data['backImageUrl'];
    final String? kmReading =
        data['kmReading'] != null ? data['kmReading'].toString() : null;

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateTime = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : 'N/A';

    final Widget imageSection = isVehicle
        ? Row(
            children: [
              Expanded(
                child: _vehicleImage(context, frontImageUrl, 'Front Image'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _vehicleImage(context, backImageUrl, 'Back Image'),
              ),
            ],
          )
        : (imageUrl != null && imageUrl.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullScreenImagePage(imageUrl: imageUrl),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _noImage(),
                  ),
                ),
              )
            : _noImage());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageSection,
          const SizedBox(height: 20),

          if (isVehicle) ...[
            _infoTile('Driver Name', data['driverName'] ?? '-'),
            _infoTile('Vehicle Number', data['vehicleNumber'] ?? '-'),
            _infoTile('Vehicle Type', data['vehicleType'] ?? '-'),
            _infoTile('KM Reading', kmReading ?? '-'),
          ] else ...[
            _infoTile('Visitor Name', data['name'] ?? '-'),
            _infoTile('Mobile Number', data['mobile'] ?? '-'),
            _infoTile('Reason', data['reason'] ?? '-'),
          ],

          const Divider(),

          _infoTile('Created By (Guard)', data['guardName'] ?? 'Unknown'),
          _infoTile('Status', data['status'] ?? '-'),

          if (data['approvedByName'] != null)
            _infoTile('Approved By (Owner)', data['approvedByName']),

          if (data['declinedByName'] != null)
            _infoTile('Declined By (Owner)', data['declinedByName']),

          _infoTile(
            'Entry Status',
            data['isEntered'] == true ? 'Entered' : 'Not Entered',
          ),

          _infoTile('Created At', dateTime),

          _infoTile(
            'Exit Status',
            isExited ? 'Exited' : 'Not Exited',
          ),
          if (isExited) _infoTile('Exited At', exitDateTime),
        ],
      ),
    );
  }

  // ================== HELPERS ==================
  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
            Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('No Image Available'),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED VEHICLE IMAGE METHOD
  Widget _vehicleImage(
    BuildContext context,
    String? url,
    String label,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (url == null || url.isEmpty) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImagePage(imageUrl: url),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url != null && url.isNotEmpty
                ? Image.network(
                    url,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _noImage(),
                  )
                : _noImage(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 80,
            ),
          ),
        ),
      ),
    );
  }
}
