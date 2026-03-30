import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova_rise_app/core/providers/school_providers.dart";
import "../controllers/session_controller.dart";

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    await ref.read(loginControllerProvider.notifier).signIn(_idController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF003D5B),
              const Color(0xFF003D5B).withOpacity(0.9),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 0.8],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Official Logo
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF003D5B).withOpacity(0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_outlined, size: 48, color: Color(0xFF003D5B)),
                            const SizedBox(height: 4),
                            Text("NOVA RISE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF003D5B).withOpacity(0.5))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "NOVA RISE",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                    ),
              ),
              const Text(
                "Academy Management System",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              
              // Auth Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _idController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Registration ID",
                        hintText: "NRA-XXX-2026",
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF003D5B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003D5B), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Security Password",
                        hintText: "Enter password...",
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF003D5B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF003D5B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF003D5B), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: loginState.isSubmitting ? null : _signIn,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF003D5B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loginState.isSubmitting
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Text(
                                "ACCESS PORTAL",
                                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Secure Administration Interface\n© 2026 Nova Rise Academy",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
