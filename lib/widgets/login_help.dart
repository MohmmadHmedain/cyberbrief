import 'package:flutter/material.dart';

class LoginHelp extends StatelessWidget {
  const LoginHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Text(
            "Administrator Access Only",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Valid Admin Accounts:\n"
            "• Mohammad Homedan\n"
            "• Firas Alqasrawi\n"
            "• Ibrahim Dayah\n"
            "• Khaled Alkhateeb",
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
