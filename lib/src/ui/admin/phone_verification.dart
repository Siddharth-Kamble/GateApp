import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;
  const PhoneVerificationPage({super.key, required this.phoneNumber});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? verificationId;
  final TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sendOTP();
  }

  void sendOTP() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verification (instant)
        await _auth.signInWithCredential(credential);
        print(
          "Phone automatically verified and user signed in: ${_auth.currentUser?.uid}",
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
      },
      codeSent: (String verId, int? resendToken) {
        setState(() => verificationId = verId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent! Check your SMS.")),
        );
      },
      codeAutoRetrievalTimeout: (String verId) {
        setState(() => verificationId = verId);
      },
    );
  }

  void verifyOTP() async {
    if (verificationId == null) return;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone verified! User can now be added.")),
      );
      // Add user to Firestore here
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Phone")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("OTP sent to ${widget.phoneNumber}"),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(labelText: "Enter OTP"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOTP,
              child: const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
