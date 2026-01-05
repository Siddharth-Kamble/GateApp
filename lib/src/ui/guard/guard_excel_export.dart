  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:excel/excel.dart';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:path_provider/path_provider.dart';
  import 'package:share_plus/share_plus.dart';

  enum DownloadType {
    today,
    thisMonth,
    previousMonth,
    full,
  }

  class GuardExcelExport {

    // ================= SHOW DOWNLOAD OPTIONS =================
    static Future<void> showDownloadOptions(
      BuildContext context,
      FirebaseFirestore firestore,
    ) async {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                "Download Gate Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              _optionTile(context, firestore, "Today", DownloadType.today),
              _optionTile(context, firestore, "This Month", DownloadType.thisMonth),
              _optionTile(context, firestore, "Previous Month", DownloadType.previousMonth),
              _optionTile(context, firestore, "Full Data", DownloadType.full),

              const SizedBox(height: 10),
            ],
          );
        },
      );
    }

    static Widget _optionTile(
      BuildContext context,
      FirebaseFirestore firestore,
      String title,
      DownloadType type,
    ) {
      return ListTile(
        leading: const Icon(Icons.download),
        title: Text(title),
        onTap: () async {
          Navigator.pop(context);
          await downloadAllGateData(context, firestore, type);
        },
      );
    }

    // ================= MAIN DOWNLOAD FUNCTION =================
    static Future<void> downloadAllGateData(
      BuildContext context,
      FirebaseFirestore firestore,
      DownloadType type,
    ) async {
      try {
        final excel = Excel.createExcel();

        // ================= DATE RANGE =================
        DateTime now = DateTime.now();
        DateTime? startDate;
        DateTime? endDate;

        switch (type) {
          case DownloadType.today:
            startDate = DateTime(now.year, now.month, now.day);
            endDate = startDate.add(const Duration(days: 1));
            break;
          case DownloadType.thisMonth:
            startDate = DateTime(now.year, now.month, 1);
            endDate = DateTime(now.year, now.month + 1, 1);
            break;
          case DownloadType.previousMonth:
            startDate = DateTime(now.year, now.month - 1, 1);
            endDate = DateTime(now.year, now.month, 1);
            break;
          case DownloadType.full:
            startDate = null;
            endDate = null;
            break;
        }

        // ================= VISITOR SHEET =================
        final Sheet visitorSheet = excel['Visitors'];
        visitorSheet.appendRow([
          'Visitor Name',
          'Contact Number',
          'Purpose',
          'Status',
          'Created Date',
          'Created Time',
          'Approved At',
          'Approved By',
          'Entry Time',
          'Created By (Guard)',
          'Image URL',
        ]);

        // ================= VEHICLE SHEET =================
        final Sheet vehicleSheet = excel['Vehicles'];
        vehicleSheet.appendRow([
          'Vehicle Number',
          'Driver Name',
          'Contact Number',
          'Vehicle Type',
          'Approved At',
          'Approved By',
          'Entry Time',
          'Exit Time',
          'Front Image URL',
          'Back Image URL',
        ]);

        // ================= EMPLOYEE SHEET =================
        final Sheet employeeSheet = excel['Employee Passes'];
        employeeSheet.appendRow([
          'Employee Name',
          'Employee ID',
          'Reason',
          'Status',
          'Date',
          'Time',
        ]);

        // ================= FETCH PASSES =================
        Query passQuery = firestore.collection('passes');

        if (startDate != null && endDate != null) {
          passQuery = passQuery
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('createdAt', isLessThan: Timestamp.fromDate(endDate));
        }

        final passesSnap = await passQuery.get();

        for (var doc in passesSnap.docs) {
          final d = doc.data() as Map<String, dynamic>;

          String createdDate = '';
          String createdTime = '';
          String approvedAt = '';
          String entryTime = '';
          String exitTime = '';

          if (d['createdAt'] != null) {
            final dt = (d['createdAt'] as Timestamp).toDate();
            createdDate = DateFormat('dd-MM-yyyy').format(dt);
            createdTime = DateFormat('HH:mm').format(dt);
          }

          if (d['approvedAt'] != null) {
            approvedAt = DateFormat(
              'dd-MM-yyyy HH:mm',
            ).format((d['approvedAt'] as Timestamp).toDate());
          }

          if (d['enteredAt'] != null) {
            entryTime = DateFormat(
              'dd-MM-yyyy HH:mm',
            ).format((d['enteredAt'] as Timestamp).toDate());
          }

          if (d['exitedAt'] != null) {
            exitTime = DateFormat(
              'dd-MM-yyyy HH:mm',
            ).format((d['exitedAt'] as Timestamp).toDate());
          }

          // ---------------- VISITOR ROW ----------------
          if (d['type'] == 'visitor') {
            visitorSheet.appendRow([
              d['name'] ?? '',
              d['mobile'] ?? '',
              d['reason'] ?? '',
              d['status'] ?? '',
              createdDate,
              createdTime,
              approvedAt,
              d['approvedByName'] ?? '',
              entryTime,
              d['guardName'] ?? '',
              d['imageUrl'] ?? '',
            ]);
          }

          // ---------------- VEHICLE ROW ----------------
          if (d['type'] == 'vehicle') {
            vehicleSheet.appendRow([
              d['vehicleNumber'] ?? '',
              d['driverName'] ?? '',
              d['contact'] ?? '',
              d['vehicleType'] ?? '',
              approvedAt,
              d['approvedByName'] ?? '',
              entryTime,
              exitTime,
              d['frontImageUrl'] ?? '',
              d['backImageUrl'] ?? '',
            ]);
          }
        }

        // ================= EMPLOYEE GATE PASS =================
        Query empQuery = firestore.collection('employee_gate_pass');

        if (startDate != null && endDate != null) {
          empQuery = empQuery
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('createdAt', isLessThan: Timestamp.fromDate(endDate));
        }

        final empSnap = await empQuery.get();

        for (var doc in empSnap.docs) {
          final d = doc.data() as Map<String, dynamic>;

          String date = '';
          String time = '';

          if (d['createdAt'] != null) {
            final dt = (d['createdAt'] as Timestamp).toDate();
            date = DateFormat('dd-MM-yyyy').format(dt);
            time = DateFormat('HH:mm').format(dt);
          }

          employeeSheet.appendRow([
            d['employeeName'] ?? '',
            d['employeeId'] ?? '',
            d['reason'] ?? '',
            d['status'] ?? '',
            date,
            time,
          ]);
        }

        // ================= SAVE FILE =================
        final directory = await getExternalStorageDirectory();
        final fileName = _fileName(type);
        final file = File('${directory!.path}/$fileName');

        await file.writeAsBytes(excel.encode()!);

        // ================= SHARE =================
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Gate Report Excel',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download / Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    static String _fileName(DownloadType type) {
      switch (type) {
        case DownloadType.today:
          return 'gate_report_today.xlsx';
        case DownloadType.thisMonth:
          return 'gate_report_this_month.xlsx';
        case DownloadType.previousMonth:
          return 'gate_report_previous_month.xlsx';
        case DownloadType.full:
        default:
          return 'gate_report_full.xlsx';
      }
    }
  }
