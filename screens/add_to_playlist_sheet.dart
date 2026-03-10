import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart'; // ดึง ThemeProvider และ LanguageProvider
import 'create_playlist_dialog.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final Map<String, dynamic> song;
  const AddToPlaylistSheet({super.key, required this.song});

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final User? user = FirebaseAuth.instance.currentUser;

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
    String songId = widget.song['id']?.toString() ?? widget.song['trackId']?.toString() ?? '';
    var playlistsSnap = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').get();

    for (var playlist in playlistsSnap.docs) {
      var songSnap = await playlist.reference.collection('songs').where('id', isEqualTo: songId).limit(1).get();
      if (songSnap.docs.isNotEmpty && mounted) setState(() => _addedPlaylists.add(playlist.id));
    }
  }

  Future<void> _togglePlaylist(String playlistId, String playlistName, bool isCustom) async {
    if (user == null) return;
    String songId = widget.song['id']?.toString() ?? widget.song['trackId']?.toString() ?? '';
    bool isCurrentlyAdded = _addedPlaylists.contains(playlistId);

    setState(() {
      if (isCurrentlyAdded) _addedPlaylists.remove(playlistId);
      else _addedPlaylists.add(playlistId);
    });

    final docRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(playlistId);

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
        'artist': widget.song['artist'] ?? widget.song['artistName'] ?? 'Unknown',
        'previewUrl': widget.song['previewUrl'] ?? '',
        'image': widget.song['image'] ?? widget.song['artworkUrl100'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
      if (isCustom) await docRef.update({'songCount': FieldValue.increment(1)});
    } else {
      var snapshot = await docRef.collection('songs').where('id', isEqualTo: songId).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        if (isCustom) await docRef.update({'songCount': FieldValue.increment(-1)});
      }
    }
  }

  // 🌟 นำ Theme และ Language มาใส่ใน Dialog สร้างด่วนด้วย
  void _createNewPlaylistQuick(AppTheme t, LanguageProvider lang) {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lang.t("New Playlist"),
          style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: t.textPrimary),
          decoration: InputDecoration(
            hintText: lang.t("Playlist name..."),
            hintStyle: TextStyle(color: t.textHint),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t("Cancel"), style: TextStyle(color: t.textHint)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || user == null) return;
              Navigator.pop(context);
              String dName = user!.displayName ?? user!.email?.split('@')[0] ?? 'User';
              var newPlaylist = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').add({
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
            child: Text(lang.t("Create"), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox();

    // 🌟 ดึงค่า ธีม และ ภาษา
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: t.sheetBg, // 🌟 สีพื้นหลังแผ่นลากขึ้นตามธีม
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: t.bottomSheetDrag, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.t("Save to"), // 🌟 ใช้ระบบแปลภาษา
                  style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await showCreatePlaylistDialogAutoName(context);
                    if (result != null) {
                      _togglePlaylist(result['id'], result['name'], true);
                    }
                  },
                  child: Text(
                    lang.t("New Playlist"),
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: t.divider, height: 1),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _playlistsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                  return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                var docs = snapshot.hasData ? snapshot.data!.docs : [];

                return ListView(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              widget.song['image'] ?? widget.song['artworkUrl100'] ?? '',
                              width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: t.surfaceHigh),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.song['title'] ?? widget.song['trackName'] ?? 'Unknown',
                                  style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.song['artist'] ?? widget.song['artistName'] ?? 'Unknown',
                                  style: TextStyle(color: t.textSecond, fontSize: 13),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: t.divider, height: 20),

                    _buildPlaylistItem(
                      id: 'liked_songs',
                      name: lang.t("Liked Songs"), // 🌟 ใช้ระบบแปลภาษา
                      isCustom: false,
                      t: t,
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white), // ไอคอนหัวใจสีขาวเสมอ
                      ),
                    ),

                    ...docs.where((doc) => doc.id != 'liked_songs').map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      String imageUrl = data['imageUrl'] ?? '';
                      int count = data['songCount'] ?? 0;
                      return _buildPlaylistItem(
                        id: doc.id,
                        name: data['name'] ?? 'Unknown',
                        subtitle: count == 0 ? lang.t("Empty") : "$count ${lang.t("tracks")}",
                        isCustom: true,
                        t: t,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                              : Container(width: 50, height: 50, color: t.surfaceHigh, child: Icon(Icons.music_note, color: t.iconMuted)),
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
    required AppTheme t, // ส่ง Theme เข้ามาใช้ด้านใน
  }) {
    bool isAdded = _addedPlaylists.contains(id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: leading,
      title: Text(name, style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: t.textSecond, fontSize: 13)) : null,
      trailing: GestureDetector(
        onTap: () => _togglePlaylist(id, name, isCustom),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isAdded
              ? const Icon(Icons.check_circle, key: ValueKey('check'), color: AppTheme.accent, size: 28)
              : Icon(Icons.add_circle_outline, key: const ValueKey('add'), color: t.textHint, size: 28),
        ),
      ),
      onTap: () => _togglePlaylist(id, name, isCustom),
    );
  }
}