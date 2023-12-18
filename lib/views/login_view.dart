import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotes/constans/routes.dart';


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromARGB(255, 194, 180, 218),
        ),
         
     body: Column(
                  children: [
                    TextField(
                      controller: _email,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                      ),
                    ),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Enter your password',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final email = _email.text;
                        final password = _password.text;
     
                        try {
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          // ignore: use_build_context_synchronously 
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            notesRoute,
                            (routes) => false,
                          );                          
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'user-not-found') {
                            devtools.log('No user found for that email.');
                          } else if (e.code == 'wrong-password') {
                            devtools.log('Wrong password provided for that user.');
                          } else {
                            devtools.log("hata: $e");
                          }
                        }
                      },
                      child: const Text(
                        'login',
                        style: TextStyle(color: Color.fromARGB(255, 148, 20, 20)),
                      ),
                    ),
                    TextButton(
                      onPressed: (){
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          registerRoute, 
                          (route) => false
                          );
                      }, 
                      child: const Text("not register yet?register here"))
                  ],
                ),
   );
  }
}
  // late  mean is I am not ready for this variable now but I will be ready later

  

 
