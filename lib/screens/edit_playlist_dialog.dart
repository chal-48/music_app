import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// 🌟 สังเกตว่าผมเอา _ ด้านหน้าออก กลายเป็น EditPlaylistDialog
class EditPlaylistDialog extends StatefulWidget {
  final Map<String, dynamic> playlistData;
  const EditPlaylistDialog({super.key, required this.playlistData});
  
  @override 
  State<EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends State<EditPlaylistDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late bool _isPublic;
  String? _existingImageUrl;
  Uint8List? _newImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlistData['name']);
    _descController = TextEditingController(text: widget.playlistData['description'] ?? '');
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
        'description': _descController.text.trim(), 
        'isPublic': _isPublic, 
        'imageUrl': finalImageUrl,
      });
      
      Map<String, dynamic> updatedData = Map.from(widget.playlistData);
      updatedData['name'] = _nameController.text.trim(); 
      updatedData['description'] = _descController.text.trim(); 
      updatedData['isPublic'] = _isPublic; 
      updatedData['imageUrl'] = finalImageUrl;
      
      if (mounted) Navigator.pop(context, updatedData);
    } finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF282828), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            const Text("แก้ไขเพลย์ลิสต์", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage, 
              child: Container(
                width: 140, height: 140, 
                decoration: BoxDecoration(
                  color: Colors.grey[800], 
                  image: _newImageBytes != null 
                    ? DecorationImage(image: MemoryImage(_newImageBytes!), fit: BoxFit.cover) 
                    : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) 
                      ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover) 
                      : null
                ), 
                child: (_newImageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) 
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.white54, size: 36), SizedBox(height: 8), Text("เปลี่ยนปก", style: TextStyle(color: Colors.white54, fontSize: 13))]) 
                  : null
              )
            ), 
            const SizedBox(height: 24),
            TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "ชื่อเพลย์ลิสต์", labelStyle: TextStyle(color: Colors.grey[500]), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5500))))), 
            const SizedBox(height: 16),
            // TextField(controller: _descController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: "คำอธิบาย", labelStyle: TextStyle(color: Colors.grey[500]), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5500))))), 
            // const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [ 
                const Text("สาธารณะ", style: TextStyle(color: Colors.white)), 
                Switch(value: _isPublic, activeColor: const Color(0xFFFF5500), onChanged: (val) => setState(() => _isPublic = val)) 
              ]
            ), 
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end, 
              children: [ 
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey))), 
                const SizedBox(width: 12), 
                _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFFFF5500)) 
                  : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500)), onPressed: _saveChanges, child: const Text("บันทึก", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))) 
              ]
            )
          ]
        )
      )
    );
  }
}