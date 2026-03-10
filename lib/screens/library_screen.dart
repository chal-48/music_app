import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'create_playlist_dialog.dart';
import 'playlist_detail_screen.dart'; // เช็คชื่อไฟล์ให้ตรงกันนะครับ

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isGrid = false;

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF5500);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[900],
                          backgroundImage: currentUser?.photoURL != null
                              ? NetworkImage(currentUser!.photoURL!)
                              : null,
                          child: currentUser?.photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Your Library",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // IconButton(
                      //   icon: const Icon(Icons.search, color: Colors.white),
                      //   onPressed: () {},
                      // ),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          // เรียกฟังก์ชันจากไฟล์นู้นได้เลย
                          showCreatePlaylistDialogAutoName(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Playlists",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isGrid = !isGrid),
                    child: Icon(
                      isGrid ? Icons.grid_view : Icons.list,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: currentUser == null
                  ? const Center(
                      child: Text(
                        "Please log in",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser!.uid)
                          .collection('playlists')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                            ),
                          );
                        }

                        List<Map<String, dynamic>> finalItems = [
                          {
                            "id": "liked_songs",
                            "name": "Liked Songs",
                            "subtitle": "Your favorite tracks",
                            "isCustom": false,
                          },
                        ];

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            // 🌟 เพิ่มบรรทัดนี้เข้าไป เพื่อข้าม document ที่ชื่อ liked_songs
                            if (doc.id == 'liked_songs') continue;

                            Map<String, dynamic> data =
                                doc.data() as Map<String, dynamic>;
                            // ... โค้ดที่เหลือเหมือนเดิม
                            int songCount = data.containsKey('songCount')
                                ? data['songCount']
                                : 0;
                            String creatorName = data.containsKey('creatorName')
                                ? data['creatorName']
                                : 'Unknown';

                            // 🌟 ไฮไลท์การแก้: ถ้าชื่อเป็น Unknown ให้ดึงชื่อจาก Gmail มาโชว์แทน
                            if ((creatorName == 'Unknown' ||
                                    creatorName.isEmpty) &&
                                currentUser != null) {
                              creatorName =
                                  currentUser!.displayName ??
                                  currentUser!.email?.split('@')[0] ??
                                  'User';
                            }

                            finalItems.add({
                              "id": doc.id,
                              "name": data['name'] ?? 'Unknown',
                              "subtitle": "$songCount songs • By $creatorName",
                              "isCustom": true,
                              "imageUrl": data['imageUrl'] ?? '',
                              "description": data['description'] ?? '',
                              "isPublic": data['isPublic'] ?? false,
                              "creatorName": creatorName,
                            });
                          }
                        }

                        return isGrid
                            ? _buildGridView(finalItems)
                            : _buildListView(finalItems);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(itemData: item),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _buildImage(item, size: 70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          color: item['id'] == 'liked_songs'
                              ? const Color(0xFFFF5500)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['subtitle'],
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(itemData: item),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildImage(item, size: double.infinity)),
              const SizedBox(height: 12),
              Text(
                item['name'],
                style: TextStyle(
                  color: item['id'] == 'liked_songs'
                      ? const Color(0xFFFF5500)
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'],
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(Map<String, dynamic> item, {required double size}) {
    if (item['id'] == 'liked_songs') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.favorite, color: Colors.white, size: size * 0.4),
      );
    }
    if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item['imageUrl'],
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.my_library_music_rounded,
        color: Colors.grey[700],
        size: size * 0.4,
      ),
    );
  }
}

// ==========================================================
// 🌟 หน้าต่างสร้าง Playlist
// ==========================================================
// class _CreatePlaylistDialog extends StatefulWidget {
//   final String defaultName;
//   const _CreatePlaylistDialog({required this.defaultName});
//   @override State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
// }

// class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
//   late TextEditingController _nameController;
//   final TextEditingController _descController = TextEditingController();
//   bool _isPublic = true;
//   bool _isLoading = false;
//   Uint8List? _imageBytes;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.defaultName);
//   }

//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
//     if (pickedFile != null) {
//       final bytes = await pickedFile.readAsBytes();
//       setState(() => _imageBytes = bytes);
//     }
//   }

//   Future<void> _savePlaylist() async {
//     if (_nameController.text.isEmpty) return;
//     setState(() => _isLoading = true);
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       String imageUrl = "";
//       if (_imageBytes != null) {
//         const String imgbbApiKey = '4636b4781d7e416b8c83bc9799a56dd3'; 
//         var response = await http.post(Uri.parse('https://api.imgbb.com/1/upload'), body: {
//           'key': imgbbApiKey, 'image': base64Encode(_imageBytes!),
//         });
//         if (response.statusCode == 200) imageUrl = jsonDecode(response.body)['data']['display_url'];
//       }

//       // 🌟 จัดการเรื่องชื่อ Unknown
//       String dName = user.displayName ?? '';
//       if (dName.isEmpty && user.email != null) {
//         dName = user.email!.split('@')[0];
//       }
//       if (dName.isEmpty) dName = 'User';

//       await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('playlists').add({
//         'name': _nameController.text.trim(),
//         'description': _descController.text.trim(),
//         'isPublic': _isPublic,
//         'imageUrl': imageUrl,
//         'creatorName': dName, 
//         'songCount': 0,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Playlist created successfully!"), backgroundColor: Color(0xFFFF5500)));
//       }
//     } catch (e) {
//       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: const Color(0xFF1A1A1A),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text("Create Playlist", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
//             const SizedBox(height: 24),
            
//             GestureDetector(
//               onTap: _isLoading ? null : _pickImage,
//               child: Container(
//                 width: 140, height: 140,
//                 decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))], image: _imageBytes != null ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) : null),
//                 child: _imageBytes == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.white54, size: 36), SizedBox(height: 12), Text("Add Cover", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold))]) : null,
//               ),
//             ),
//             const SizedBox(height: 24),

//             TextField(
//               controller: _nameController, style: const TextStyle(color: Colors.white, fontSize: 16),
//               decoration: InputDecoration(labelText: "Playlist Name", labelStyle: TextStyle(color: Colors.grey[500]), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5500)))),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _descController, style: const TextStyle(color: Colors.white, fontSize: 16),
//               decoration: InputDecoration(labelText: "Description (Optional)", labelStyle: TextStyle(color: Colors.grey[500]), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5500)))),
//             ),
//             const SizedBox(height: 24),
            
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text("Public Playlist", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                 Switch(value: _isPublic, activeColor: const Color(0xFFFF5500), onChanged: (val) => setState(() => _isPublic = val)),
//               ],
//             ),
//             const SizedBox(height: 30),

//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16))),
//                 const SizedBox(width: 12),
//                 _isLoading 
                  // ? const CircularProgressIndicator(color: Color(0xFFFF5500))
//                   : ElevatedButton(
//                       style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
//                        onPressed: _savePlaylist, 
//                       child: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
//                     ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }