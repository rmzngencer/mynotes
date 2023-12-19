import 'package:flutter/material.dart';
import 'package:mynotes/constans/routes.dart';
import 'package:mynotes/services/auth/auth_exception.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewStateState();
}

class _RegisterViewStateState extends State<RegisterView> {
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
        title: const Text('Register'),
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
                await AuthService.firebase().creatUser(
                  email: email,
                  password: password,
                );
                AuthService.firebase().sendEmailVerification();
                Navigator.of(context).pushNamed(
                  verifyEmailRoute,
                );
              } on WeakPasswordException {
                await showErrorDialog(
                  context,
                  'The password provided is too weak.',
                );
              } on EmailAlreadyInUseException {
                showErrorDialog(
                  context,
                  'The account already exists for that email.',
                );
              } on InvalidEmailException {
                showErrorDialog(
                  context,
                  'The email address is not valid.',
                );
              } on GenericAuthException {
                showErrorDialog(
                  context,
                  'An unknown error occurred.',
                );
              }
            },
            child: const Text(
              registerRoute,
              style: TextStyle(color: Color.fromARGB(255, 148, 20, 20)),
            ),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text("Already registered? Login  "))
        ],
      ),
    );
  }
}
