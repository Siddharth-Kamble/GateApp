import 'package:cloud_firestore/cloud_firestore.dart';

class PassModel {
  String? uid;
  String? name;
  String? contactInfo;
  String? idType;
  String? idValue;
  String? hostName;
  String? hostEmail;
  int? days;
  String? location; // visit reason
  String? userId;
  String? email;
  String? passSecret;
  bool? isActive;
  bool? isVerified;
  DateTime? createdAt;

  PassModel();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'contactInfo': contactInfo,
      'location': location,
      'idType': idType,
      'idValue': idValue,
      'hostName': hostName,
      'hostEmail': hostEmail,
      'days': days,
      'userId': userId,
      'email': email,
      'passSecret': passSecret,
      'isActive': isActive,
      'isVerified': isVerified,
    };
  }

  static PassModel fromMap(String id, Map<String, dynamic> map) {
    PassModel p = PassModel();
    p.uid = id;
    p.name = map['name'];
    p.contactInfo = map['contactInfo'];
    p.location = map['location'];
    p.userId = map['userId'];
    p.email = map['email'];
    p.passSecret = map['passSecret'];
    p.idType = map['idType'];
    p.idValue = map['idValue'];
    p.hostName = map['hostName'];
    p.hostEmail = map['hostEmail'];
    // safe parsing for days (int or numeric string)
    final dynamic daysRaw = map['days'];
    if (daysRaw is int) {
      p.days = daysRaw;
    } else if (daysRaw is String) {
      p.days = int.tryParse(daysRaw);
    } else if (daysRaw is num) {
      p.days = daysRaw.toInt();
    }

    p.isActive = map['isActive'];
    p.isVerified = map['isVerified'];
    p.createdAt = map['createdAt'] != null
        ? (map['createdAt'] as Timestamp).toDate()
        : null;
    return p;
  }
}
