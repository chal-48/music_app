import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// 🌟 1. เพิ่มฟังก์ชันนี้ไว้ด้านบนสุดของไฟล์เลยครับ
Future<Map<String, dynamic>?> showCreatePlaylistDialogAutoName(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณาล็อกอินก่อนสร้างเพลย์ลิสต์")));
    return null;
  }

  // โชว์แจ้งเตือนโหลดหมุนๆ
  showDialog(
    context: context, 
    barrierDismissible: false, 
    builder: (loadingContext) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
  );

  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('playlists')
        .get()
        .timeout(const Duration(seconds: 10)); 
        
    int maxNum = 0;
    for (var doc in snap.docs) {
      String name = doc['name'] ?? '';
      if (name.startsWith('My playlist #')) {
        int? num = int.tryParse(name.replaceFirst('My playlist #', ''));
        if (num != null && num > maxNum) maxNum = num;
      }
    }

    String defaultName = "My playlist #${maxNum + 1}";

    // 🌟 1. จุดแก้บั๊กจอแดง: สั่งปิด Pop-up โหลด ด้วย rootNavigator: true
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // เปิดหน้าต่างสร้างเพลย์ลิสต์
    if (context.mounted) {
      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CreatePlaylistDialog(defaultName: defaultName),
      );
    }
  } catch (e) {
    print("🔥 Error Firebase: $e");
    
    // 🌟 2. จุดแก้บั๊กจอแดง (กรณีเน็ตหลุด): สั่งปิด Pop-up ด้วย rootNavigator: true เหมือนกัน
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red)
      );
    }
  }
  return null;
}

// 🌟 เปลี่ยนชื่อคลาสเป็น CreatePlaylistDialog
class CreatePlaylistDialog extends StatefulWidget {
  final String defaultName;
  const CreatePlaylistDialog({super.key, required this.defaultName});
  
  @override 
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
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
    
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      String imageUrl = "";
      if (_imageBytes != null) {
        const String imgbbApiKey = '4636b4781d7e416b8c83bc9799a56dd3'; 
        
        // 🌟 1. บังคับ Timeout (15 วินาที) ถ้าระบบอัปโหลดรูปค้าง
        var response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'), 
          body: {'key': imgbbApiKey, 'image': base64Encode(_imageBytes!)}
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception("อัปโหลดรูปภาพใช้เวลานานเกินไป");
        });
        
        if (response.statusCode == 200) {
          imageUrl = jsonDecode(response.body)['data']['display_url'];
        }
      }

      String dName = user.displayName ?? '';
      if (dName.isEmpty && user.email != null) dName = user.email!.split('@')[0];
      if (dName.isEmpty) dName = 'User';

      // 🌟 2. บังคับ Timeout (10 วินาที) ถ้า Firebase ค้าง 
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('playlists').add({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'isPublic': _isPublic,
        'imageUrl': imageUrl,
        'creatorName': dName, 
        'songCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("ไม่สามารถบันทึกลง Firebase ได้ (เชื่อมต่อนานเกินไป)");
      });

      if (mounted) {
        Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("สร้างเพลย์ลิสต์สำเร็จ!"), backgroundColor: Color(0xFFFF5500)));
      }
    } catch (e) {
      // 🌟 3. ถ้าระบบค้างหรือพัง มันจะเด้งเข้าตรงนี้ โชว์ข้อความให้รู้ และปุ่มจะหยุดหมุนทันที!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // หยุดตัวโหลดเสมอ
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI เหมือนเดิมทุกอย่างครับ (ย่อไว้เพื่อความกระชับ)
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("สร้างเพลย์ลิสต์", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))], image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null),
                child: _imageBytes == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.white54, size: 36), SizedBox(height: 12), Text("เพิ่มปก", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold))]) : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _nameController, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: InputDecoration(labelText: "ชื่อเพลย์ลิสต์", labelStyle: TextStyle(color: Colors.grey[500]), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5500))))),
            const SizedBox(height: 16),
            // TextField(controller: _descController, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: InputDecoration(labelText: "คำอธิบาย (ไม่บังคับ)", labelStyle: TextStyle(color: Colors.grey[500]), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5500))))),
            // const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("สาธารณะ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)), Switch(value: _isPublic, activeColor: const Color(0xFFFF5500), onChanged: (val) => setState(() => _isPublic = val))]),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey, fontSize: 16))),
                const SizedBox(width: 12),
                _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFFFF5500))
                  : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), onPressed: _savePlaylist, child: const Text("สร้าง", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            )
          ],
        ),
      ),
    );
  }
}