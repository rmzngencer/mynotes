
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return 
       Scaffold(
        appBar:AppBar(
          title: const Text('Verify Email'),
          backgroundColor: const Color.fromARGB(255, 194, 180, 218),
          ),
         body: Column(
          children: [
            const Text('Please verify your email'),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
              },
              child: const Text('Send verification email'),
            ),
          ],
               
             ),
       );
  }
}