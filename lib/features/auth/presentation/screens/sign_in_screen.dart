import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/models/app_user.dart";
import "../../../../shared/widgets/app_surface.dart";
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

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null && mounted) {
        context.go("/");
      }
    });

    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          // Elegant Split Background
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF003D5B), Color(0xFF002A3F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(color: Colors.white),
              ),
            ],
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Floating Branded Header
                  Center(
                    child: Hero(
                      tag: "academy_logo",
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset("assets/images/logo.png", height: 100, width: 100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Nova Rise Academy",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ESTABLISHED TO EMPOWER",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 4,
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Simplified Login Card
                  Card(
                    elevation: 16,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Authorized Entry",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF003D5B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _CustomTextField(
                            controller: _idController,
                            label: "PHONE NUMBER OR STUDENT ID",
                            hint: "e.g. 9876543210",
                            icon: Icons.phone_android_outlined,
                          ),
                          const SizedBox(height: 24),
                          _CustomTextField(
                            controller: _passwordController,
                            label: "ACCESS PIN / BIRTH DATE",
                            hint: "••••••••",
                            icon: Icons.lock_open_outlined,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          
                          if (state.error != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: FilledButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => controller.signIn(_idController.text.trim(), _passwordController.text),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: const Color(0xFF003D5B),
                              ),
                              child: state.isSubmitting 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("LOG IN TO ACADEMY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // Minimalist Feature Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactFeature(icon: Icons.verified_user, label: "Encrypted"),
                      _CompactFeature(icon: Icons.cloud_done, label: "Live Sync"),
                      _CompactFeature(icon: Icons.support_agent, label: "24/7 Support"),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  // Secondary Actions
                  Column(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.push("/register-admin"),
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: const Text("New Administrator Setup"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD4AF37), // Heritage Gold
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.black38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF003D5B)),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.black26),
                  onPressed: onTogglePassword,
                )
              : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF1F3F5), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF003D5B), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactFeature extends StatelessWidget {
  const _CompactFeature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF003D5B).withValues(alpha: 0.4)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Demo tiles removed for final version
