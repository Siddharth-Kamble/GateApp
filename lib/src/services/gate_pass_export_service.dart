
// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:archive/archive.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart'
//     show CompressFormat, FlutterImageCompress;
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:share_plus/share_plus.dart';

// /* ==============================
//    DATE RANGE
// ============================== */
// enum ExportRange { today, week, month, previousMonth, all }

// /* ==============================
//    PROGRESS MODEL
// ============================== */
// class ExportProgress {
//   final double progress;
//   final String sizeText;
//   final String eta;

//   ExportProgress(this.progress, this.sizeText, this.eta);
// }

// /* ==============================
//    PROGRESS ENGINE (1% STEP)
// ============================== */
// class ProgressEngine {
//   int _value = 0;
//   Timer? _timer;
//   final void Function(int) onUpdate;

//   ProgressEngine(this.onUpdate);

//   void start() {
//     _timer = Timer.periodic(
//       const Duration(milliseconds: 80),
//       (_) {
//         if (_value < 99) {
//           _value++;
//           onUpdate(_value);
//         }
//       },
//     );
//   }

//   void complete() {
//     _timer?.cancel();
//     _value = 100;
//     onUpdate(100);
//   }

//   void stop() {
//     _timer?.cancel();
//   }
// }

// /* ==============================
//    EXPORT SERVICE
// ============================== */
// class GatePassExportService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   final StreamController<ExportProgress> _progressCtrl =
//       StreamController<ExportProgress>.broadcast();
//   int _downloadedBytes = 0;
//   int _totalBytes = 0;
//   Stream<ExportProgress> get progressStream => _progressCtrl.stream;

//   void dispose() {
//     if (!_progressCtrl.isClosed) _progressCtrl.close();
//   }

//   void _emit(int percent, String text) {
//     if (!_progressCtrl.isClosed) {
//       final sizeText =
//           '${_fmtBytes(_downloadedBytes)} / ${_fmtBytes(_totalBytes)}';

//       _progressCtrl.add(
//         ExportProgress(percent / 100, sizeText, ''),
//       );
//     }
//   }

//   String _fmtBytes(int bytes) {
//     if (bytes < 1024) return '$bytes B';
//     if (bytes < 1024 * 1024) {
//       return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     }
//     return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//   }

//   /* ==============================
//      DATE HELPERS
//   ============================== */
//   DateTime _start(ExportRange r) {
//     final n = DateTime.now();
//     switch (r) {
//       case ExportRange.today:
//         return DateTime(n.year, n.month, n.day);
//       case ExportRange.week:
//         return n.subtract(const Duration(days: 7));
//       case ExportRange.month:
//         return DateTime(n.year, n.month, 1);
//       case ExportRange.previousMonth:
//         return DateTime(n.year, n.month - 1, 1);
//       case ExportRange.all:
//         return DateTime.fromMillisecondsSinceEpoch(0);
//     }
//   }

//   DateTime _end(ExportRange r) {
//     final n = DateTime.now();
//     if (r == ExportRange.previousMonth) {
//       return DateTime(n.year, n.month, 0, 23, 59, 59);
//     }
//     return n;
//   }

//   /* ==============================
//      FORMAT
//   ============================== */
//   String _fmt(dynamic v) {
//     if (v is Timestamp) {
//       return DateFormat('dd MMM yyyy, hh:mm a').format(v.toDate());
//     }
//     return v?.toString() ?? 'null';
//   }

//   /* ==============================
//      FETCH
//   ============================== */
//   Future<List<Map<String, dynamic>>> _fetch(
//     String col,
//     ExportRange range, {
//     String? type,
//   }) async {
//     Query<Map<String, dynamic>> q = _db.collection(col);
//     if (type != null) q = q.where('type', isEqualTo: type);

//     final snap = await q.get();
//     final start = _start(range);
//     final end = _end(range);

//     return snap.docs.map((e) => e.data()).where((d) {
//       if (range == ExportRange.all) return true;
//       final ts = d['createdAt'];
//       if (ts is! Timestamp) return false;
//       final dt = ts.toDate();
//       return !dt.isBefore(start) && !dt.isAfter(end);
//     }).toList();
//   }

//   /* ==============================
//      IMAGE LOADER (SAFE)
//   ============================== */
//   static Future<pw.MemoryImage?> _loadImage(
//     String? url,
//     void Function(int bytes) onBytes,
//   ) async {
//     if (url == null || url.isEmpty) return null;

//     final buffer = BytesBuilder();

//     try {
//       final req = await HttpClient().getUrl(Uri.parse(url));
//       final res = await req.close();

//       if (res.statusCode != 200) return null;

//       await for (final chunk in res) {
//         buffer.add(chunk);
//         onBytes(chunk.length); // 🔥 REPORT LIVE BYTES
//       }

//       final compressed = await FlutterImageCompress.compressWithList(
//         buffer.toBytes(),
//         minWidth: 900,
//         minHeight: 900,
//         quality: 70,
//         format: CompressFormat.jpeg,
//       );

//       return pw.MemoryImage(compressed);
//     } catch (_) {
//       return null;
//     }
//   }

//   /* ==============================
//      ATTACH IMAGES (SEQUENTIAL)
//   ============================== */
//   Future<List<Map<String, dynamic>>> _attachImages(
//     List<Map<String, dynamic>> data, {
//     bool isVehicle = false,
//   }) async {
//     final result = <Map<String, dynamic>>[];

//     for (final e in data) {
//       final m = Map<String, dynamic>.from(e);

//       if (isVehicle) {
//         m['_frontImg'] = await _loadImage(
//           e['frontImageUrl'],
//           (bytes) {
//             _downloadedBytes += bytes;
//             _totalBytes += bytes;
//           },
//         );

//         m['_backImg'] = await _loadImage(
//           e['backImageUrl'],
//           (bytes) {
//             _downloadedBytes += bytes;
//             _totalBytes += bytes;
//           },
//         );
//       } else {
//         m['_img'] = await _loadImage(
//           e['imageUrl'],
//           (bytes) {
//             _downloadedBytes += bytes;
//             _totalBytes += bytes;
//           },
//         );
//       }

//       result.add(m);
//     }

//     return result;
//   }

//   /* ==============================
//      PDF BUILDER
//   ============================== */
//   Future<Uint8List> _buildPdf({
//     required String title,
//     required ExportRange range,
//     required List<Map<String, dynamic>> data,
//     required List<String> removeKeys,
//     bool isVehicle = false,
//   }) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         margin: const pw.EdgeInsets.all(16),
//         build: (_) => [
//           pw.Text(
//             title,
//             style: pw.TextStyle(
//               fontSize: 18,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//           pw.SizedBox(height: 12),
//           ...data.map((e) {
//             final keys = e.keys.where(
//               (k) => !k.startsWith('_') && !removeKeys.contains(k),
//             );

//             return pw.Container(
//               margin: const pw.EdgeInsets.only(bottom: 8),
//               padding: const pw.EdgeInsets.all(8),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   if (isVehicle) ...[
//                     pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.start,
//                       crossAxisAlignment: pw.CrossAxisAlignment.center,
//                       children: [
//                         if (e['_frontImg'] != null)
//                           pw.Image(
//                             e['_frontImg'],
//                             width: 80,
//                             height: 60,
//                           ),
//                         if (e['_frontImg'] != null && e['_backImg'] != null)
//                           pw.SizedBox(width: 8),
//                         if (e['_backImg'] != null)
//                           pw.Image(
//                             e['_backImg'],
//                             width: 80,
//                             height: 60,
//                           ),
//                       ],
//                     ),
//                   ] else if (e['_img'] != null) ...[
//                     pw.Image(e['_img'], width: 80, height: 60),
//                   ],
//                   ...keys.map(
//                     (k) => pw.Text(
//                       '$k: ${_fmt(e[k])}',
//                       style: const pw.TextStyle(fontSize: 10),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );

//     return pdf.save();
//   }

//   /* ==============================
//      EXPORT
//   ============================== */
//   Future<File> export({required ExportRange range}) async {
//     const vehicleRemoveKeys = [
//       'isEntered',
//       'registeredByGuard',
//       'notificationSent',
//       'frontImageUrl',
//       'backImageUrl',
//       'isExited',
//       'approvedById',
//       'isApproved',
//     ];
//     final engine = ProgressEngine(
//       (v) => _emit(v, '$v% completed'),
//     );

//     engine.start();

//     try {
//       final visitors =
//           await _attachImages(await _fetch('passes', range, type: 'visitor'));
//       final vehicles = await _attachImages(
//         await _fetch('passes', range, type: 'vehicle'),
//         isVehicle: true, // ✅ THIS WAS MISSING
//       );
//       final employees =
//           await _attachImages(await _fetch('employee_gate_pass', range));

//       final visitorPdf = await _buildPdf(
//         title: 'Visitor Entries',
//         range: range,
//         data: visitors,
//         removeKeys: const [],
//       );

//       final vehiclePdf = await _buildPdf(
//         title: 'Vehicle Entries',
//         range: range,
//         data: vehicles,
//         removeKeys: vehicleRemoveKeys,
//         isVehicle: true,
//       );

//       final employeePdf = await _buildPdf(
//         title: 'Employee Gate Pass',
//         range: range,
//         data: employees,
//         removeKeys: const [],
//       );

//       final archive = Archive()
//         ..addFile(ArchiveFile('visitor.pdf', visitorPdf.length, visitorPdf))
//         ..addFile(ArchiveFile('vehicle.pdf', vehiclePdf.length, vehiclePdf))
//         ..addFile(ArchiveFile('employee.pdf', employeePdf.length, employeePdf));

//       final zipBytes = ZipEncoder().encode(archive)!;

//       final dir = await getApplicationDocumentsDirectory();
//       final file = File(
//         '${dir.path}/GateExport_${DateTime.now().millisecondsSinceEpoch}.zip',
//       );

//       await file.writeAsBytes(zipBytes, flush: true);

//       await Share.shareXFiles([XFile(file.path)], text: 'Gate Activity Export');
//       _totalBytes += zipBytes.length;
//       _downloadedBytes = _totalBytes;
//       _emit(100, 'Completed');
//       engine.complete();

//       return file;
//     } catch (e) {
//       engine.stop();
//       rethrow;
//     }
//   }
// }






import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompress;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/* ==============================
   DATE RANGE
============================== */
enum ExportRange { today, week, month, previousMonth, all }

/* ==============================
   PROGRESS MODEL
============================== */
class ExportProgress {
  final double progress;
  final String sizeText;
  final String eta;

  ExportProgress(this.progress, this.sizeText, this.eta);
}

/* ==============================
   PROGRESS ENGINE (1% STEP)
============================== */
class ProgressEngine {
  int _value = 0;
  Timer? _timer;
  final void Function(int) onUpdate;

  ProgressEngine(this.onUpdate);

  void start() {
    _timer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) {
        if (_value < 99) {
          _value++;
          onUpdate(_value);
        }
      },
    );
  }

  void complete() {
    _timer?.cancel();
    _value = 100;
    onUpdate(100);
  }

  void stop() {
    _timer?.cancel();
  }
}


class ExportDateFilter {
  final DateTime? fromDate;
  final DateTime? toDate;

  const ExportDateFilter({
    this.fromDate,
    this.toDate,
  });

  bool get isSingleDate =>
      fromDate != null && toDate != null && _sameDay(fromDate!, toDate!);

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/* ==============================
   EXPORT SERVICE
============================== */
class GatePassExportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final StreamController<ExportProgress> _progressCtrl =
      StreamController<ExportProgress>.broadcast();
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  Stream<ExportProgress> get progressStream => _progressCtrl.stream;

  void dispose() {
    if (!_progressCtrl.isClosed) _progressCtrl.close();
  }

  void _emit(int percent, String text) {
    if (!_progressCtrl.isClosed) {
      final sizeText =
          '${_fmtBytes(_downloadedBytes)} / ${_fmtBytes(_totalBytes)}';

      _progressCtrl.add(
        ExportProgress(percent / 100, sizeText, ''),
      );
    }
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /* ==============================
     DATE HELPERS
  ============================== */
  DateTime _start(ExportRange r) {
    final n = DateTime.now();
    switch (r) {
      case ExportRange.today:
        return DateTime(n.year, n.month, n.day);
      case ExportRange.week:
        return n.subtract(const Duration(days: 7));
      case ExportRange.month:
        return DateTime(n.year, n.month, 1);
      case ExportRange.previousMonth:
        return DateTime(n.year, n.month - 1, 1);
      case ExportRange.all:
        return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  DateTime _end(ExportRange r) {
    final n = DateTime.now();
    if (r == ExportRange.previousMonth) {
      return DateTime(n.year, n.month, 0, 23, 59, 59);
    }
    return n;
  }

  /* ==============================
     FORMAT
  ============================== */
  String _fmt(dynamic v) {
    if (v is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(v.toDate());
    }
    return v?.toString() ?? 'null';
  }

  /* ==============================
     FETCH
  ============================== */ 

  Future<List<Map<String, dynamic>>> _fetch(
  String col,
  ExportDateFilter filter, {
  String? type,
}) async {
  Query<Map<String, dynamic>> q = _db.collection(col);
  if (type != null) q = q.where('type', isEqualTo: type);

  final snap = await q.get();

  // If no date provided → return everything
  if (filter.fromDate == null && filter.toDate == null) {
    return snap.docs.map((e) => e.data()).toList();
  }

  // Normalize dates
  final from = DateTime(
    filter.fromDate!.year,
    filter.fromDate!.month,
    filter.fromDate!.day,
  );

  final to = DateTime(
    filter.toDate!.year,
    filter.toDate!.month,
    filter.toDate!.day,
    23,
    59,
    59,
  );

  return snap.docs.map((e) => e.data()).where((d) {
    final ts = d['createdAt'];
    if (ts is! Timestamp) return false;
    final dt = ts.toDate();
    return !dt.isBefore(from) && !dt.isAfter(to);
  }).toList();
}


  /* ==============================
     IMAGE LOADER (SAFE)
  ============================== */
  static Future<pw.MemoryImage?> _loadImage(
    String? url,
    void Function(int bytes) onBytes,
  ) async {
    if (url == null || url.isEmpty) return null;

    final buffer = BytesBuilder();

    try {
      final req = await HttpClient().getUrl(Uri.parse(url));
      final res = await req.close();

      if (res.statusCode != 200) return null;

      await for (final chunk in res) {
        buffer.add(chunk);
        onBytes(chunk.length); // 🔥 REPORT LIVE BYTES
      }

      final compressed = await FlutterImageCompress.compressWithList(
        buffer.toBytes(),
        minWidth: 900,
        minHeight: 900,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      return pw.MemoryImage(compressed);
    } catch (_) {
      return null;
    }
  }

  /* ==============================
     ATTACH IMAGES (SEQUENTIAL)
  ============================== */
  Future<List<Map<String, dynamic>>> _attachImages(
    List<Map<String, dynamic>> data, {
    bool isVehicle = false,
  }) async {
    final result = <Map<String, dynamic>>[];

    for (final e in data) {
      final m = Map<String, dynamic>.from(e);

      if (isVehicle) {
        m['_frontImg'] = await _loadImage(
          e['frontImageUrl'],
          (bytes) {
            _downloadedBytes += bytes;
            _totalBytes += bytes;
          },
        );

        m['_backImg'] = await _loadImage(
          e['backImageUrl'],
          (bytes) {
            _downloadedBytes += bytes;
            _totalBytes += bytes;
          },
        );
      } else {
        m['_img'] = await _loadImage(
          e['imageUrl'],
          (bytes) {
            _downloadedBytes += bytes;
            _totalBytes += bytes;
          },
        );
      }

      result.add(m);
    }

    return result;
  }

  /* ==============================
     PDF BUILDER
  ============================== */
  Future<Uint8List> _buildPdf({
    required String title,
   
    required List<Map<String, dynamic>> data,
    required List<String> removeKeys,
    bool isVehicle = false,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(16),
        build: (_) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          ...data.map((e) {
            final keys = e.keys.where(
  (k) =>
      !k.startsWith('_') &&
      !removeKeys.contains(k) &&
      k != 'name' &&
      k != 'driverName',
);


            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (isVehicle) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (e['_frontImg'] != null)
                          pw.Image(
                            e['_frontImg'],
                            width: 80,
                            height: 60,
                          ),
                        if (e['_frontImg'] != null && e['_backImg'] != null)
                          pw.SizedBox(width: 8),
                        if (e['_backImg'] != null)
                          pw.Image(
                            e['_backImg'],
                            width: 80,
                            height: 60,
                          ),
                      ],
                    ),
                  ]  else if (e['_img'] != null) ...[
  pw.Image(e['_img'], width: 80, height: 60),
  pw.SizedBox(height: 4),
  pw.Text(
    'Name: ${e['name'] ?? e['driverName'] ?? 'Unknown'}',
    style: pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
],

                  ...keys.map(
                    (k) => pw.Text(
                      '$k: ${_fmt(e[k])}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return pdf.save();
  }

  /* ==============================
     EXPORT
  ============================== */
 Future<File> export({required ExportDateFilter filter}) async {
    const visitorRemoveKeys = [
  'isEntered',
  'addedBy',
  'isExited',
  'imageUrl',
  'isApproved',
  'approvedById',
  'notificationSent'
];
    const vehicleRemoveKeys = [
      'isEntered',
      'registeredByGuard',
      'notificationSent',
      'frontImageUrl',
      'backImageUrl',
      'isExited',
      'approvedById',
      'isApproved',
    ];
    final engine = ProgressEngine(
      (v) => _emit(v, '$v% completed'),
    );

    engine.start();

    try {
      final visitors =
          await _attachImages(await _fetch('passes', filter, type: 'visitor'));
      final vehicles = await _attachImages(
        await _fetch('passes', filter, type: 'vehicle'),
        isVehicle: true, // ✅ THIS WAS MISSING
      );
      final employees =
          await _attachImages(await _fetch('employee_gate_pass', filter));

     final visitorPdf = await _buildPdf(
  title: 'Visitor Entries',
  data: visitors,
  removeKeys: visitorRemoveKeys,
  isVehicle: false, // 👈 explicitly visitor
);

      final vehiclePdf = await _buildPdf(
        title: 'Vehicle Entries',
   
        data: vehicles,
        removeKeys: vehicleRemoveKeys,
        isVehicle: true,
      );

      final employeePdf = await _buildPdf(
        title: 'Employee Gate Pass',
     
        data: employees,
        removeKeys: const [],
      );

      final archive = Archive()
        ..addFile(ArchiveFile('visitor.pdf', visitorPdf.length, visitorPdf))
        ..addFile(ArchiveFile('vehicle.pdf', vehiclePdf.length, vehiclePdf))
        ..addFile(ArchiveFile('employee.pdf', employeePdf.length, employeePdf));

      final zipBytes = ZipEncoder().encode(archive)!;

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/GateExport_${DateTime.now().millisecondsSinceEpoch}.zip',
      );

      await file.writeAsBytes(zipBytes, flush: true);

      await Share.shareXFiles([XFile(file.path)], text: 'Gate Activity Export');
      _totalBytes += zipBytes.length;
      _downloadedBytes = _totalBytes;
      _emit(100, 'Completed');
      engine.complete();

      return file;
    } catch (e) {
      engine.stop();
      rethrow;
    }
  }
}
