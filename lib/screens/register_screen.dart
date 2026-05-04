import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool isLoading = false;
  bool isObscure = true;

  // 🔥 FUNCTION REGISTER
  Future<void> register() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.48:8000/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'password_confirmation': confirmPasswordController.text,
          'role': 'nasabah',
          'no_hp': phoneController.text,
          'alamat': addressController.text,
        }),
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");
      print("REGISTER SELESAI");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registrasi berhasil")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal register")),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
              const Icon(Icons.person_add, size: 60, color: Color(0xFF4CAF50)),

              const SizedBox(height: 16),

              const Text(
                "Buat Akun",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Daftar untuk mulai menggunakan aplikasi",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 🔥 FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [

                    // NAMA
                    _buildInput(
                      controller: nameController,
                      hint: "Nama",
                      icon: Icons.person,
                    ),

                    const SizedBox(height: 15),

                    // EMAIL
                    _buildInput(
                      controller: emailController,
                      hint: "Email",
                      icon: Icons.email,
                    ),

                    const SizedBox(height: 15),

                    // PASSWORD
                    _buildInput(
                      controller: passwordController,
                      hint: "Password",
                      icon: Icons.lock,
                      isPassword: true,
                    ),

                    const SizedBox(height: 15),

                    // Confirm PASSWORD
                    _buildInput(
                      controller: confirmPasswordController,
                      hint: "Konfirmasi Password",
                      icon: Icons.lock,
                      isPassword: true,
                    ),

                    const SizedBox(height: 15),
                    // PHONE
                    _buildInput(
                      controller: phoneController,
                      hint: "No HP",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 15),

                    // ADDRESS
                    _buildInput(
                      controller: addressController,
                      hint: "Alamat",
                      icon: Icons.location_on,
                    ),

                    const SizedBox(height: 25),

                    // 🔥 BUTTON
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
                            register();
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Daftar",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔥 LOGIN
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Sudah punya akun? Login",
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

  // 🔥 INPUT STYLE (BIAR CONSISTENT)
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isObscure : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFE6ECE6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              isObscure = !isObscure;
            });
          },
        )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$hint tidak boleh kosong";
        }

        if (hint == "Email") {
          final emailRegex = RegExp(
            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          );
          if (!emailRegex.hasMatch(value)) {
            return "Format email tidak valid";
          }
        }

        if (hint == "Password" && value.length < 6) {
          return "Password minimal 6 karakter";
        }

        if (hint == "Konfirmasi Password") {
          if (value != passwordController.text) {
            return "Password tidak sama";
          }
        }

        if (hint == "No HP" && value.length < 10) {
          return "No HP tidak valid";
        }

        return null;
      },
    );
  }
}