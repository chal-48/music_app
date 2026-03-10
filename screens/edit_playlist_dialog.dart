import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart';

class EditPlaylistDialog extends StatefulWidget {
  final Map<String, dynamic> playlistData;
  const EditPlaylistDialog({super.key, required this.playlistData});
  @override State<EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends State<EditPlaylistDialog> {
  late TextEditingController _nameController;
  late bool _isPublic;
  String? _existingImageUrl;
  Uint8List? _newImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlistData['name']);
    _isPublic = widget.playlistData['isPublic'] ?? false;
    _existingImageUrl = widget.playlistData['imageUrl'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) { 
      final bytes = await pickedFile.readAsBytes(); 
      setState(() { _newImageBytes = bytes; _existingImageUrl = null; }); 
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    try {
      String finalImageUrl = _existingImageUrl ?? "";
      if (_newImageBytes != null) {
        var res = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'), 
          body: { 'key': '4636b4781d7e416b8c83bc9799a56dd3', 'image': base64Encode(_newImageBytes!) }
        );
        if (res.statusCode == 200) finalImageUrl = jsonDecode(res.body)['data']['display_url'];
      }
      
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(widget.playlistData['id']).update({
        'name': _nameController.text.trim(), 
        'isPublic': _isPublic, 
        'imageUrl': finalImageUrl,
      });
      
      Map<String, dynamic> updatedData = Map.from(widget.playlistData);
      updatedData['name'] = _nameController.text.trim(); 
      updatedData['isPublic'] = _isPublic; 
      updatedData['imageUrl'] = finalImageUrl;
      
      if (mounted) Navigator.pop(context, updatedData);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text(lang.t("Edit Playlist"), style: TextStyle(color: t.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage, 
              child: Container(
                width: 140, height: 140, 
                decoration: BoxDecoration(
                  color: t.surfaceHigh, 
                  borderRadius: BorderRadius.circular(12),
                  image: _newImageBytes != null 
                    ? DecorationImage(image: MemoryImage(_newImageBytes!), fit: BoxFit.cover) 
                    : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) 
                      ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover) 
                      : null
                ), 
                child: (_newImageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) 
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: t.iconMuted, size: 36), const SizedBox(height: 8), Text(lang.t("Change Cover"), style: TextStyle(color: t.textHint, fontSize: 13))]) 
                  : null
              )
            ), 
            const SizedBox(height: 24),
            TextField(
              controller: _nameController, 
              style: TextStyle(color: t.textPrimary), 
              decoration: InputDecoration(labelText: lang.t("Playlist Name"), labelStyle: TextStyle(color: t.textHint), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accent)))
            ), 
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [ 
                Text(lang.t("Public"), style: TextStyle(color: t.textPrimary)), 
                Switch(value: _isPublic, activeColor: AppTheme.accent, onChanged: (val) => setState(() => _isPublic = val)) 
              ]
            ), 
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end, 
              children: [ 
                TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t("Cancel"), style: TextStyle(color: t.textHint))), 
                const SizedBox(width: 12), 
                _isLoading 
                  ? const CircularProgressIndicator(color: AppTheme.accent) 
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), 
                      onPressed: _saveChanges, 
                      child: Text(lang.t("Save"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ) 
              ]
            )
          ]
        )
      )
    );
  }
}