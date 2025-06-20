import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'main.dart';
import 'inbox.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController mobileController = TextEditingController();
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    fcmToken = await FirebaseMessaging.instance.getToken();
    print("📱 FCM Token: $fcmToken");
  }

  Future<void> _registerMobile(BuildContext context) async {
    final mobile = mobileController.text.trim();
    if (mobile.isEmpty) {
      _showSnackBar(context, "Mobile number cannot be empty");
      return;
    }
    if (fcmToken == null) {
      _showSnackBar(context, "FCM token not available");
      return;
    }

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/api/register-device/${fcmToken}/${mobile}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobile": mobile, "fcm_token": fcmToken}),
    );

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobile', mobile);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InboxPage(mobile: mobile)),
      );
    } else {
      _showSnackBar(context, "❌ Registration failed");
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📲 Register")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "📱 Enter your mobile number",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _registerMobile(context),
              child: const Text("🔐 Register"),
            ),
          ],
        ),
      ),
    );
  }
}
