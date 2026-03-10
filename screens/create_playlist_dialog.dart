import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart'; // สำหรับ ThemeProvider และ LanguageProvider

Future<Map<String, dynamic>?> showCreatePlaylistDialogAutoName(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return null;

  showDialog(
    context: context, 
    barrierDismissible: false, 
    builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: AppTheme.accent))
  );

  try {
    final snap = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('playlists').get().timeout(const Duration(seconds: 10)); 
    int maxNum = 0;
    for (var doc in snap.docs) {
      String name = doc['name'] ?? '';
      if (name.startsWith('My playlist #')) {
        int? num = int.tryParse(name.replaceFirst('My playlist #', ''));
        if (num != null && num > maxNum) maxNum = num;
      }
    }
    String defaultName = "My playlist #${maxNum + 1}";

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) {
      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CreatePlaylistDialog(defaultName: defaultName),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }
  return null;
}

class CreatePlaylistDialog extends StatefulWidget {
  final String defaultName;
  const CreatePlaylistDialog({super.key, required this.defaultName});
  @override State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  late TextEditingController _nameController;
  final TextEditingController _descController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _savePlaylist() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }

    try {
      String imageUrl = "";
      if (_imageBytes != null) {
        const String imgbbApiKey = '4636b4781d7e416b8c83bc9799a56dd3'; 
        var response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'), 
          body: {'key': imgbbApiKey, 'image': base64Encode(_imageBytes!)}
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) imageUrl = jsonDecode(response.body)['data']['display_url'];
      }

      String dName = user.displayName ?? '';
      if (dName.isEmpty && user.email != null) dName = user.email!.split('@')[0];
      if (dName.isEmpty) dName = 'User';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('playlists').add({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'isPublic': _isPublic,
        'imageUrl': imageUrl,
        'creatorName': dName, 
        'songCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isCustom': true,
      }).timeout(const Duration(seconds: 10));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return Dialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.t("Create Playlist"), style: TextStyle(color: t.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(color: t.surfaceHigh, borderRadius: BorderRadius.circular(12), image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null),
                child: _imageBytes == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: t.iconMuted, size: 36), const SizedBox(height: 12), Text(lang.t("Add Cover"), style: TextStyle(color: t.textHint, fontSize: 13, fontWeight: FontWeight.bold))]) : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController, 
              style: TextStyle(color: t.textPrimary, fontSize: 16), 
              decoration: InputDecoration(
                labelText: lang.t("Playlist Name"), 
                labelStyle: TextStyle(color: t.textHint), 
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accent))
              )
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(lang.t("Public"), style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)), 
                Switch(value: _isPublic, activeColor: AppTheme.accent, onChanged: (val) => setState(() => _isPublic = val))
              ]
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t("Cancel"), style: TextStyle(color: t.textHint, fontSize: 16))),
                const SizedBox(width: 12),
                _isLoading 
                  ? const CircularProgressIndicator(color: AppTheme.accent)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), 
                      onPressed: _savePlaylist, 
                      child: Text(lang.t("Create"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                    ),
              ],
            )
          ],
        ),
      ),
    );
  }
}