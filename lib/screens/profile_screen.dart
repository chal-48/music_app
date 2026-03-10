import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_app/screens/auth_screen.dart'; // แก้ path ให้ตรงกับโปรเจกต์คุณ
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'share_helper.dart'; // นำเข้าฟังก์ชันแชร์จากไฟล์ใหม่

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _audioQuality = "Very High";
  String _downloadedSize = "2.4 GB";
  bool _isAutoplayEnabled = true;
  bool _isDataSaverEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _audioQuality = prefs.getString('audioQuality') ?? "Very High";
      _downloadedSize = prefs.getString('downloadedSize') ?? "2.4 GB";
      _isAutoplayEnabled = prefs.getBool('autoplay') ?? true;
      _isDataSaverEnabled = prefs.getBool('dataSaver') ?? false;
    });
  }

  Future<void> _toggleSwitch(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'autoplay') _isAutoplayEnabled = value;
      if (key == 'dataSaver') _isDataSaverEnabled = value;
    });
  }

  Future<void> _saveAudioQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audioQuality', quality);
    setState(() => _audioQuality = quality);
  }

  Future<void> _clearCache() async {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cache cleared (142 MB freed)."),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showAudioQualityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            "Audio Quality",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Low", "Normal", "High", "Very High"].map((quality) {
              return RadioListTile<String>(
                title: Text(
                  quality,
                  style: const TextStyle(color: Colors.white),
                ),
                value: quality,
                groupValue: _audioQuality,
                activeColor: const Color(0xFFFF5500),
                onChanged: (String? value) {
                  if (value != null) {
                    _saveAudioQuality(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF5500);
    User? user = FirebaseAuth.instance.currentUser;
    String userName = user?.displayName ?? "Guest";
    String userEmail = user?.email ?? "No Email";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF1A1A1A),
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.white54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: (user != null)
                                  ? FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('playlists')
                                        .snapshots()
                                  : null,
                              builder: (context, snapshot) {
                                String playlistCount = "0";
                                if (snapshot.hasData) {
                                  playlistCount = snapshot.data!.docs.length
                                      .toString();
                                }
                                return _buildStatColumn(
                                  playlistCount,
                                  "Playlists",
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildStatColumn("128", "Followers"),
                            _buildDivider(),
                            _buildStatColumn("45", "Following"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Center(
                          child: Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        showShareMenu(context);
                      },
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFF5500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Join Premium",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Listen without limits & ad-free",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 🌟 ใส่ฟังก์ชันที่คุณต้องการเรียกใช้ตรงนี้ได้เลยครับ
                        showDownloadComingSoon(context);
                        // ตัวอย่างเช่น: showUpgradeMenu(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Upgrade",
                          style: TextStyle(
                            color: Color(0xFFFF5500),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionHeader("Playback"),
              _buildMenuItem(
                Icons.high_quality,
                "Audio Quality",
                trailingText: _audioQuality,
                onTap: _showAudioQualityDialog,
              ),
              _buildMenuItem(Icons.equalizer, "Equalizer", onTap: () {}),
              _buildMenuItem(
                Icons.all_inclusive_rounded,
                "Autoplay",
                subtitle: "Keep listening to similar tracks",
                trailingWidget: Switch(
                  value: _isAutoplayEnabled,
                  activeColor: accentColor,
                  onChanged: (val) => _toggleSwitch('autoplay', val),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader("Data & Storage"),
              _buildMenuItem(
                Icons.data_usage_rounded,
                "Data Saver",
                subtitle: "Set audio quality to low on cellular",
                trailingWidget: Switch(
                  value: _isDataSaverEnabled,
                  activeColor: accentColor,
                  onChanged: (val) => _toggleSwitch('dataSaver', val),
                ),
              ),
              _buildMenuItem(
                Icons.download_done_rounded,
                "Downloaded Music",
                trailingText: _downloadedSize,
                onTap: () {},
              ),
              _buildMenuItem(
                Icons.cleaning_services_rounded,
                "Clear Cache",
                subtitle: "Free up space",
                onTap: _clearCache,
              ),

              const SizedBox(height: 20),
              _buildSectionHeader("About"),
              _buildMenuItem(
                Icons.privacy_tip_outlined,
                "Privacy Policy",
                onTap: () {},
              ),
              _buildMenuItem(
                Icons.info_outline,
                "Version",
                trailingText: "1.0.0",
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: _signOut,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[800]!),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      "Log out",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(width: 1, height: 24, color: Colors.grey[800]),
  );

  Widget _buildSectionHeader(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    String? trailingText,
    Widget? trailingWidget,
    String? subtitle,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    splashColor: Colors.white10,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              if (trailingWidget != null) trailingWidget!,
              if (trailingText != null ||
                  (trailingWidget == null && onTap != null)) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[700]),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? "";
    _emailController.text = user?.email ?? "";
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      if (_imageBytes != null) {
        const String imgbbApiKey = '4636b4781d7e416b8c83bc9799a56dd3';
        String base64Image = base64Encode(_imageBytes!);
        Uri url = Uri.parse('https://api.imgbb.com/1/upload');
        var response = await http.post(
          url,
          body: {'key': imgbbApiKey, 'image': base64Image},
        );
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          String downloadUrl = jsonResponse['data']['display_url'];
          await user!.updatePhotoURL(downloadUrl);
        } else {
          throw Exception("Image upload failed: ${response.statusCode}");
        }
      }
      if (_nameController.text.isNotEmpty &&
          _nameController.text != user?.displayName) {
        await user?.updateDisplayName(_nameController.text);
      }
      if (_newPasswordController.text.isNotEmpty) {
        await user?.updatePassword(_newPasswordController.text);
      }
      if (_emailController.text.isNotEmpty &&
          _emailController.text != user?.email) {
        await user?.verifyBeforeUpdateEmail(_emailController.text);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent to new address.'),
            ),
          );
      }
      await user?.reload();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Error',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF5500);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF1A1A1A),
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!) as ImageProvider
                            : (user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null),
                        child: (_imageBytes == null && user?.photoURL == null)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white54,
                              )
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField("Display Name", _nameController),
            const SizedBox(height: 20),
            _buildTextField("Email Address", _emailController),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Change Password",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              "New Password (Leave blank to keep current)",
              _newPasswordController,
              isObscure: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
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
      ),
    );
  }
}
