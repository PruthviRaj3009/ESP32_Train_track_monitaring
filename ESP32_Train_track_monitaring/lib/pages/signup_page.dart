import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Firebase Signup Function
  Future<void> signupUser(BuildContext context) async {
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
        ),
      );

      // Go back to Login Page after successful signup
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP DESIGN
            Container(
              height: 350,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 1500),
                    child: _inputContainer(
                      children: [
                        _inputField(
                          "Full Name",
                          controller: nameController,
                        ),
                        _inputField(
                          "Email",
                          controller: emailController,
                        ),
                        _inputField(
                          "Password",
                          isPassword: true,
                          controller: passwordController,
                        ),
                        _inputField(
                          "Confirm Password",
                          isPassword: true,
                          controller: confirmPasswordController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // CREATE ACCOUNT BUTTON
                  FadeInUp(
                    duration: const Duration(milliseconds: 1700),
                    child: GestureDetector(
                      onTap: () {
                        signupUser(context);
                      },
                      child: _gradientButton("Create Account"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  FadeInUp(
                    duration: const Duration(milliseconds: 1800),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(
                          color: Color.fromRGBO(143, 148, 251, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// REUSED STYLE
  Widget _inputContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromRGBO(143, 148, 251, 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(143, 148, 251, .2),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _inputField(
    String hint, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(143, 148, 251, 1),
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }

  Widget _gradientButton(String text) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(143, 148, 251, 1),
            Color.fromRGBO(143, 148, 251, .6),
          ],
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
