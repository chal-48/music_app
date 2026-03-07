import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/screens/main_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Error Messages
  String? _emailError;
  String? _confirmPasswordError;
  String? _nameError;

  // Password Checklist Status
  bool _hasLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;
  bool _showPasswordChecklist = false;

  // Top Banner Variables
  String? _topMessage;
  bool _showTopMessage = false;
  bool _isMessageError = true;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus && !isLogin) {
        setState(() => _showPasswordChecklist = true);
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showTopBanner(String message, {bool isError = true}) {
    setState(() {
      _topMessage = message;
      _showTopMessage = true;
      _isMessageError = isError;
    });
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showTopMessage = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF5500); // Vivid Orange

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  const Icon(
                    Icons.headphones_rounded,
                    size: 80,
                    color: accentColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isLogin ? "Log in to your account" : "Create an account",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (!isLogin) ...[
                    _buildTextField(
                      "Display Name",
                      _nameController,
                      errorText: _nameError,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    "Email Address",
                    _emailController,
                    errorText: _emailError,
                    onChanged: (val) {
                      setState(() {
                        if (val.isEmpty)
                          _emailError = null;
                        else if (!_isValidEmail(val))
                          _emailError = "Invalid email format";
                        else
                          _emailError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildPasswordField(
                    "Password",
                    _passwordController,
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                    focusNode: _passwordFocusNode,
                    onChanged: (value) {
                      _checkPasswordStrength(value);
                      if (!isLogin &&
                          _confirmPasswordController.text.isNotEmpty) {
                        _validateMatch(_confirmPasswordController.text);
                      }
                    },
                  ),

                  if (!isLogin &&
                      _showPasswordChecklist &&
                      _passwordController.text.isNotEmpty &&
                      !_isPasswordStrong()) ...[
                    const SizedBox(height: 12),
                    _buildPasswordChecklist(),
                  ],

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      "Confirm Password",
                      _confirmPasswordController,
                      _obscureConfirmPassword,
                      () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      errorText: _confirmPasswordError,
                      onChanged: (value) => _validateMatch(value),
                    ),
                  ],

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuthSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        disabledBackgroundColor: Colors.grey[800],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isLogin ? "Log In" : "Sign Up",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildSocialDivider(),
                  const SizedBox(height: 30),

                  _buildSocialButton(
                    icon: FontAwesomeIcons.google,
                    label: "Continue with Google",
                    onTap: _handleGoogleSignIn,
                  ),

                  const SizedBox(height: 40),
                  _buildToggleAuth(),
                ],
              ),
            ),
          ),

          // Notification Banner
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showTopMessage ? 0 : -100,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isMessageError
                        ? Colors.redAccent
                        : const Color(0xFF4CAF50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isMessageError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _isMessageError
                          ? Colors.redAccent
                          : const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _topMessage ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildPasswordChecklist() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Password must contain:",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (!_hasLength) _buildCheckItem("At least 8 characters"),
          if (!_hasUpper) _buildCheckItem("1 uppercase letter (A-Z)"),
          if (!_hasLower) _buildCheckItem("1 lowercase letter (a-z)"),
          if (!_hasDigit) _buildCheckItem("1 number (0-9)"),
          if (!_hasSpecial) _buildCheckItem("1 special character (!@#\$&*_)"),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.redAccent, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        floatingLabelStyle: const TextStyle(color: Color(0xFFFF5500)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscured,
    VoidCallback onToggle, {
    String? errorText,
    Function(String)? onChanged,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isObscured,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        floatingLabelStyle: const TextStyle(color: Color(0xFFFF5500)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF1A1A1A),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[800])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "OR",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account? " : "Already have an account? ",
          style: const TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: _toggleAuthMode,
          child: Text(
            isLogin ? "Sign up" : "Log in",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // --- Logic ---
  bool _isValidEmail(String email) => RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  ).hasMatch(email);

  void _checkPasswordStrength(String password) {
    setState(() {
      _hasLength = password.length >= 8;
      _hasUpper = password.contains(RegExp(r'[A-Z]'));
      _hasLower = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecial = password.contains(RegExp(r'[!@#\$&*~_.]'));
    });
  }

  bool _isPasswordStrong() =>
      _hasLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  void _validateMatch(String val) => setState(
    () => _confirmPasswordError = (val != _passwordController.text)
        ? "Passwords do not match"
        : null,
  );

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _nameController.clear();
      _emailError = null;
      _confirmPasswordError = null;
      _nameError = null;
      _showPasswordChecklist = false;
    });
  }

  Future<void> _handleAuthSubmit() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || !_isValidEmail(email)) {
      _showTopBanner("Please provide valid email and password.", isError: true);
      return;
    }

    if (!isLogin) {
      if (_nameController.text.isEmpty) {
        setState(() => _nameError = "Name is required");
        return;
      }
      if (!_isPasswordStrong()) {
        _showTopBanner("Password does not meet requirements.", isError: true);
        return;
      }
      if (password != _confirmPasswordController.text) {
        setState(() => _confirmPasswordError = "Passwords do not match");
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (mounted)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
          );
      } else {
        UserCredential cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.updateDisplayName(_nameController.text.trim());
        await FirebaseAuth.instance
            .signOut(); // สมัครเสร็จ -> ออกจากระบบเพื่อให้ล็อกอินใหม่
        _showTopBanner(
          "Registration successful! Please log in.",
          isError: false,
        );
        _toggleAuthMode();
      }
    } on FirebaseAuthException catch (e) {
      _showTopBanner(e.message ?? "Authentication failed", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      _showTopBanner("Enter a valid email.", isError: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showTopBanner("Reset link sent!", isError: false);
    } catch (e) {
      _showTopBanner("Error sending reset email.", isError: true);
    }
  }

  // 🌟 FIX: ใส่ทั้ง clientId และ serverClientId เพื่อแก้ปัญหา Error 401 และ Assertion Failed
  // 📍 ไฟล์: lib/screens/auth_screen.dart

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    // 🌟 จุดสำคัญ: ก๊อปปี้ Web Client ID ของคุณมาวางตรงนี้ครั้งเดียว
    const String myClientId =
        '1020735028944-ju074sakfhhqm64q6dmfs2198ojpgffa.apps.googleusercontent.com';

    try {
      // 🛠 แก้ไขการสร้าง GoogleSignIn ให้รองรับทุกแพลตฟอร์ม
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: myClientId,
        // ถ้าเป็น Web ห้ามส่ง serverClientId เด็ดขาด, แต่ถ้าเป็น Android/iOS ให้ส่ง
        serverClientId: kIsWeb ? null : myClientId,
        scopes: ['email', 'profile'], // ระบุ Scope ให้ชัดเจน
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } catch (e) {
      print("Google Sign In Details: $e");
      _showTopBanner(
        "Sign in failed. Check console for details.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
