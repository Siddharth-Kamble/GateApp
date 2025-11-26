import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:vms/model/pass_model.dart';

class PassListScreen extends StatefulWidget {
  final Future<List<PassModel>> passModels;
  final void Function(PassModel) onTap;

  const PassListScreen(this.passModels, this.onTap, {Key? key}) : super(key: key);

  @override
  State<PassListScreen> createState() => _PassListScreenState();
}

class _PassListScreenState extends State<PassListScreen> {
  bool _loading = true;
  List<PassModel> _passes = [];

  @override
  void initState() {
    super.initState();
    _loadPasses();
  }

  Future<void> _loadPasses() async {
    try {
      final value = await widget.passModels;
      setState(() {
        _passes = value;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _passes = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Passes'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpinKitRotatingCircle(
                    color: Colors.redAccent,
                    size: 40.0,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _passes.isNotEmpty
              ? ListView.separated(
                  itemCount: _passes.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) =>
                      _PassListItem(pass: _passes[index], onTap: widget.onTap),
                  separatorBuilder: (_, __) => const Divider(height: 0),
                )
              : const Center(
                  child: Text(
                    'No passes found.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
    );
  }
}

class _PassListItem extends StatefulWidget {
  final PassModel pass;
  final void Function(PassModel) onTap;

  const _PassListItem({
    Key? key,
    required this.pass,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_PassListItem> createState() => _PassListItemState();
}

class _PassListItemState extends State<_PassListItem> {
  String? _photoUrl;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      final url = await _storage.ref(widget.pass.uid).getDownloadURL();
      if (mounted) {
        setState(() => _photoUrl = url);
      }
    } catch (_) {
      // ignore if no photo found
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adjust these property names to match your PassModel fields
    final String name = widget.pass.name ?? 'Unknown';
    // Use actual PassModel fields: `contactInfo` for mobile and `passSecret` for reference
    final String mobile = widget.pass.contactInfo ?? 'Not available';
    final String reference = widget.pass.passSecret ?? '—';

    return InkWell(
      onTap: () => widget.onTap(widget.pass),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.grey[700],
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Mobile
                  Text(
                    'Mobile: $mobile',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Reference
                  Text(
                    'Ref: $reference',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
