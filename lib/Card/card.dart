import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomePages/home_page.dart';

class CustomCard extends StatefulWidget {
  const CustomCard({super.key});
  @override
  _CustomCardState createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    final String apiUrl =
        'https://acpldemo.co.in/attendance/acpl/login_api.php'; // Replace with your API URL.

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Make the POST request.
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'api_key': '123#', // Replace with your API key.
            'email': _emailController.text,
            'password': _passwordController.text,
          },
        );

        // Parse the response.
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Save login status and user data to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('emp_id', data['Emp_id']);
          await prefs.setString('emp_name', data['emp_name']);
          await prefs.setString('email', data['email']);

          // Navigate to the home page.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Login successful! Welcome ${data['emp_name']}')),
          );
        } else {
          // Show error message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['value'] ?? 'Unknown error occurred')),
          );
        }
      } catch (e) {
        print('An error occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // If user is logged in, navigate to HomePage.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check if user is logged in when the app starts
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width *
            2.9, // Adjusted to 0.9 for better responsiveness.
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/img/user-avatar.png',
                  width: 100,
                ),
              ),
              const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 146, 148, 150),
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Employee ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 0, 112, 208),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your Employee ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Enter Password',
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 0, 112, 208),
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        primary: const Color.fromARGB(255, 0, 112, 208),
                        minimumSize: const Size(double.infinity, 50),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
