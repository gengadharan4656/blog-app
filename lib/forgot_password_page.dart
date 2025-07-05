import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final otpControllers = List.generate(4, (_) => TextEditingController());

  bool otpSent = false;
  int secondsRemaining = 0;
  Timer? countdownTimer;

  Future<void> sendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your email.");
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.15.171:5000/send_otp_email"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      setState(() {
        otpSent = true;
        secondsRemaining = 120;
      });
      startTimer();
      _showMessage("OTP sent to your email.");
    } else {
      _showMessage("Failed to send OTP.");
    }
  }

  void startTimer() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  void verifyOtp() async {
    final email = emailController.text.trim();
    final enteredOtp = otpControllers.map((c) => c.text).join();

    if (enteredOtp.length < 4) {
      _showMessage("Please enter the complete OTP.");
      return;
    }

    final response = await http.post(
      Uri.parse("http://192.168.15.171:5000/verify_otp"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': enteredOtp}),
    );

    final result = jsonDecode(response.body);
    if (response.statusCode == 200 && result['status'] == 'success') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(userEmail: email),
        ),
      );
    } else {
      _showMessage("Invalid OTP. Please try again.");
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: Text(message)),
    );
  }

  Widget buildOtpField(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: otpControllers[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(counterText: "", border: OutlineInputBorder()),
        onChanged: (val) {
          if (val.isNotEmpty && index < 3) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    emailController.dispose();
    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get timerText {
    final min = secondsRemaining ~/ 60;
    final sec = secondsRemaining % 60;
    return 'Retry in ${min.toString().padLeft(1, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter your Email", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: secondsRemaining > 0 ? null : sendOtp,
              child: Text(secondsRemaining > 0 ? timerText : "Send OTP"),
            ),
            if (otpSent) ...[
              const SizedBox(height: 30),
              const Text("Enter OTP", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => buildOtpField(index)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: verifyOtp, child: const Text("Verify OTP")),
            ]
          ],
        ),
      ),
    );
  }
}
