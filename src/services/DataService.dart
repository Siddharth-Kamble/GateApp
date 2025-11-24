import 'package:flutter/material.dart';
import 'dart:math';

/// --- Vehicle Entry Data Model ---
class VehicleEntry {
  final String id;
  final String vehicleNumber;
  final String driverName;
  final String unitNumber;
  final String purpose;
  final String timestamp;
  String status; // Pending, Approved, Denied

  VehicleEntry({
    required this.id,
    required this.vehicleNumber,
    required this.driverName,
    required this.unitNumber,
    required this.purpose,
    required this.timestamp,
    this.status = 'Pending',
  });
}

/// --- Visitor Entry Data Model ---
class VisitorEntry {
  final String id;
  final String name;
  final String mobileNumber;
  final String purpose;
  final String timestamp;
  String status; // Pending, Approved, Denied

  VisitorEntry({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.purpose,
    required this.timestamp,
    this.status = 'Pending',
  });
}

/// --- Data Service Singleton ---
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final ValueNotifier<List<VehicleEntry>> vehicleEntries = ValueNotifier([]);
  final ValueNotifier<List<VisitorEntry>> visitorEntries = ValueNotifier([]);

  /// --- Add Vehicle Request ---
  void addRequest({
    required String vehicleNumber,
    required String driverName,
    required String unitNumber,
    required String purpose,
  }) {
    final id = 'VEH-${Random().nextInt(9999).toString().padLeft(4, '0')}';
    final newEntry = VehicleEntry(
      id: id,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
      unitNumber: unitNumber,
      purpose: purpose,
      timestamp: TimeOfDay.now().format(
        navigatorKey.currentState!.overlay!.context,
      ),
      status: 'Pending',
    );
    vehicleEntries.value = [newEntry, ...vehicleEntries.value];
  }

  /// --- Add Visitor Request & return ID ---
  String addVisitorRequestAndGetId({
    required String name,
    required String mobileNumber,
    required String purpose,
  }) {
    final id = 'VIS-${Random().nextInt(9999).toString().padLeft(4, '0')}';
    final newEntry = VisitorEntry(
      id: id,
      name: name,
      mobileNumber: mobileNumber,
      purpose: purpose,
      timestamp: TimeOfDay.now().format(
        navigatorKey.currentState!.overlay!.context,
      ),
      status: 'Pending',
    );
    visitorEntries.value = [newEntry, ...visitorEntries.value];
    return id;
  }
}

/// --- Navigator Key for TimeOfDay formatting ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
