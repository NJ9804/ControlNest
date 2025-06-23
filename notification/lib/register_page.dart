import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'inbox.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final TextEditingController mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? fcmToken;
  bool isLoading = false;
  bool isRegistering = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getFCMToken();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  Future<void> _getFCMToken() async {
    setState(() {
      isLoading = true;
    });

    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      print("📱 FCM Token: $fcmToken");
    } catch (e) {
      print("Error getting FCM token: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _registerMobile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final mobile = mobileController.text.trim();
    if (fcmToken == null) {
      _showSnackBar(
        context,
        "Unable to initialize notifications. Please try again.",
      );
      return;
    }

    setState(() {
      isRegistering = true;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      final response = await http.post(
        Uri.parse(
          "http://10.0.2.2:8000/api/register-device/${fcmToken}/${mobile}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile": mobile, "fcm_token": fcmToken}),
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mobile', mobile);

        _showSnackBar(context, "Registration successful");

        // Small delay to show success message
        await Future.delayed(const Duration(milliseconds: 1200));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      InboxPage(mobile: mobile),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
          );
        }
      } else {
        final errorData =
            response.statusCode == 404
                ? "Phone number not found"
                : "Registration failed";
        _showSnackBar(context, errorData);
      }
    } catch (e) {
      _showSnackBar(context, "Connection error. Please check your network.");
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
        elevation: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Hero Section
                  _buildHeroSection(colorScheme),

                  const SizedBox(height: 50),

                  // Registration Form
                  _buildRegistrationForm(colorScheme),

                  const SizedBox(height: 40),

                  // Register Button
                  _buildRegisterButton(colorScheme),

                  const SizedBox(height: 30),

                  // Footer Info
                  _buildFooterInfo(colorScheme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme) {
    return Column(
      children: [
        // App Icon/Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_active,
            size: 60,
            color: colorScheme.onPrimary,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          "Welcome to",
          style: TextStyle(
            fontSize: 24,
            color: colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "NotifyHub",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Register Your Device",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Enter your mobile number to get started",
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 24),

            // Mobile Number Input
            TextFormField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              enabled: !isLoading && !isRegistering,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Mobile number is required";
                }
                if (value.trim().length < 10) {
                  return "Please enter a valid mobile number";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: "Mobile Number",
                hintText: "Enter your mobile number",
                prefixIcon: Icon(
                  Icons.phone_android,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton(ColorScheme colorScheme) {
    final isButtonEnabled = !isLoading && !isRegistering && fcmToken != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient:
            isButtonEnabled
                ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                : null,
        color: !isButtonEnabled ? colorScheme.outline.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isButtonEnabled
                ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isButtonEnabled ? () => _registerMobile(context) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRegistering) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                Icon(
                  isRegistering ? null : Icons.app_registration,
                  color:
                      isButtonEnabled
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),

                const SizedBox(width: 8),

                Text(
                  isRegistering ? "Registering..." : "Register Device",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isButtonEnabled
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterInfo(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          "Secure • Private • Reliable",
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
