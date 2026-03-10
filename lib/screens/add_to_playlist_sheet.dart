import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_playlist_dialog.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Map<String, dynamic> song;
  const AddToPlaylistSheet({super.key, required this.song});

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color accentColor = const Color(0xFFFF5500);

  final Set<String> _addedPlaylists = {};
  Stream<QuerySnapshot>? _playlistsStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _playlistsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('playlists')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    _checkExistingPlaylists();
  }

  Future<void> _checkExistingPlaylists() async {
    if (user == null) return;
    String songId =
        widget.song['id']?.toString() ??
        widget.song['trackId']?.toString() ??
        '';
    var playlistsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('playlists')
        .get();

    for (var playlist in playlistsSnap.docs) {
      var songSnap = await playlist.reference
          .collection('songs')
          .where('id', isEqualTo: songId)
          .limit(1)
          .get();
      if (songSnap.docs.isNotEmpty && mounted)
        setState(() => _addedPlaylists.add(playlist.id));
    }
  }

  Future<void> _togglePlaylist(
    String playlistId,
    String playlistName,
    bool isCustom,
  ) async {
    if (user == null) return;
    String songId =
        widget.song['id']?.toString() ??
        widget.song['trackId']?.toString() ??
        '';
    bool isCurrentlyAdded = _addedPlaylists.contains(playlistId);

    setState(() {
      if (isCurrentlyAdded)
        _addedPlaylists.remove(playlistId);
      else
        _addedPlaylists.add(playlistId);
    });

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('playlists')
        .doc(playlistId);

    if (!isCurrentlyAdded) {
      if (!isCustom)
        await docRef.set({
          'name': 'Liked Songs',
          'id': 'liked_songs',
          'isCustom': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      await docRef.collection('songs').add({
        'id': songId,
        'title': widget.song['title'] ?? widget.song['trackName'] ?? 'Unknown',
        'artist':
            widget.song['artist'] ?? widget.song['artistName'] ?? 'Unknown',
        'previewUrl': widget.song['previewUrl'] ?? '',
        'image': widget.song['image'] ?? widget.song['artworkUrl100'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
      if (isCustom) await docRef.update({'songCount': FieldValue.increment(1)});
    } else {
      var snapshot = await docRef
          .collection('songs')
          .where('id', isEqualTo: songId)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        if (isCustom)
          await docRef.update({'songCount': FieldValue.increment(-1)});
      }
    }
  }

  // 🌟 ฟังก์ชันสร้างเพลย์ลิสต์ด่วน (พร้อมเคลียร์เมมโมรี่เมื่อปิด)
  void _createNewPlaylistQuick() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "เพลย์ลิสต์ใหม่",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "ตั้งชื่อเพลย์ลิสต์...",
            hintStyle: TextStyle(color: Colors.grey[600]),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || user == null) return;
              Navigator.pop(context);
              String dName =
                  user!.displayName ?? user!.email?.split('@')[0] ?? 'User';
              var newPlaylist = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('playlists')
                  .add({
                    'name': nameController.text.trim(),
                    'description': '',
                    'isPublic': true,
                    'imageUrl': '',
                    'creatorName': dName,
                    'songCount': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                    'isCustom': true,
                  });
              _togglePlaylist(newPlaylist.id, nameController.text.trim(), true);
            },
            child: Text(
              "สร้าง",
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).then((_) {
      // 🌟 เคลียร์กล่องข้อความทิ้งเพื่อป้องกัน Memory Leak!
      nameController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "บันทึกใน",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // 1. เรียกใช้งานและรอให้ผู้ใช้สร้างเพลย์ลิสต์เสร็จ
                    final result = await showCreatePlaylistDialogAutoName(
                      context,
                    );

                    // 2. ถ้าสร้างเสร็จ (มี ID กลับมา) ให้จับเพลงปัจจุบันยัดใส่ไปเลย!
                    if (result != null) {
                      _togglePlaylist(result['id'], result['name'], true);
                    }
                  },
                  child: Text(
                    "เพลย์ลิสต์ใหม่",
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _playlistsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  return Center(
                    child: CircularProgressIndicator(color: accentColor),
                  );
                var docs = snapshot.hasData ? snapshot.data!.docs : [];

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              widget.song['image'] ??
                                  widget.song['artworkUrl100'] ??
                                  '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.song['title'] ??
                                      widget.song['trackName'] ??
                                      'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.song['artist'] ??
                                      widget.song['artistName'] ??
                                      'Unknown',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 20),

                    _buildPlaylistItem(
                      id: 'liked_songs',
                      name: 'เพลงที่ถูกใจ',
                      isCustom: false,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ),

                    // 🌟 เติม .where(...) ดักไว้ก่อนที่จะ .map(...)
                    ...docs.where((doc) => doc.id != 'liked_songs').map((doc) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      String imageUrl = data['imageUrl'] ?? '';
                      int count = data['songCount'] ?? 0;
                      return _buildPlaylistItem(
                        id: doc.id,
                        name: data['name'] ?? 'Unknown',
                        subtitle: count == 0 ? "ว่างเปล่า" : "$count แทร็ก",
                        isCustom: true,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem({
    required String id,
    required String name,
    String? subtitle,
    required bool isCustom,
    required Widget leading,
  }) {
    bool isAdded = _addedPlaylists.contains(id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: leading,
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            )
          : null,
      trailing: GestureDetector(
        onTap: () => _togglePlaylist(id, name, isCustom),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isAdded
              ? Icon(
                  Icons.check_circle,
                  key: const ValueKey('check'),
                  color: accentColor,
                  size: 28,
                )
              : const Icon(
                  Icons.add_circle_outline,
                  key: ValueKey('add'),
                  color: Colors.grey,
                  size: 28,
                ),
        ),
      ),
      onTap: () => _togglePlaylist(id, name, isCustom),
    );
  }
}
