import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: const Color.fromARGB(255, 194, 180, 218),
      ),
      body: Column(
        children: [
          const Text(
              "We'he send a link  E mail to your mail account plesa click the link"),
          const Text(
              'if you have not received the email,pres the bottom below'),
          TextButton(
            onPressed: () async {
              AuthService.firebase().sendEmailVerification();
            },
            child: const Text('Send verification email'),
          ),
          TextButton(
            onPressed: () async {
              AuthService.firebase().logout();
            },
            child: const Text('Restart'),
          )
        ],
      ),
    );
  }
}
