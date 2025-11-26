import 'package:flutter/material.dart';

Widget makeButton(String text, VoidCallback? onPress) {
  final bool disabled = onPress == null;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: disabled ? null : onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.redAccent.withOpacity(0.5) : Colors.redAccent,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
