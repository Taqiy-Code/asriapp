import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// import halaman kamu
import 'package:asriapp/screens/register_screen.dart';
import 'package:asriapp/screens/kurir/dashboard_kurir.dart';
import 'package:asriapp/screens/user/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;

  // 🔥 FUNCTION LOGIN
  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.48:8000/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
      print("LOGIN REQUEST SELESAI");


      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        print("PINDAH DASHBOARD");

        String role = data['user']['role'];
        String name = data['user']['name'];

        if (!context.mounted) return;

        if (role == 'kurir') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardKurir()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(name: name),
            ),
          );
        }
      } else {
        String message = data['message'] ?? "Login gagal";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Koneksi gagal / server tidak jalan")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              const SizedBox(height: 40),

              // 🔥 ICON
              const Icon(Icons.eco, size: 60, color: Color(0xFF4CAF50)),

              const SizedBox(height: 16),

              const Text(
                "Selamat Datang",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Masuk untuk melanjutkan ke akun Anda",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 🔥 FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [

                    // EMAIL
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: const Color(0xFFE6ECE6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email tidak boleh kosong";
                        }

                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );

                        if (!emailRegex.hasMatch(value)) {
                          return "Format email tidak valid";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: const Color(0xFFE6ECE6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password tidak boleh kosong";
                        }

                        if (value.length < 6) {
                          return "Password minimal 6 karakter";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // 🔥 REMEMBER + FORGOT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  rememberMe = !rememberMe;
                                });
                              },
                              child: const Text("Ingat saya"),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Lupa password?",
                            style: TextStyle(color: Color(0xFF2E7D32)),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔥 BUTTON LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E8C61),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            login();
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔥 REGISTER
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Belum punya akun? Daftar sekarang",
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}