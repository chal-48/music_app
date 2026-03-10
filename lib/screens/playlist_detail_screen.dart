import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'add_song_search_sheet.dart';
import 'package:provider/provider.dart';

import 'music_provider.dart';
import 'add_to_playlist_sheet.dart';
import 'share_helper.dart'; // นำเข้าฟังก์ชันแชร์จากไฟล์ใหม่
import 'edit_playlist_dialog.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const PlaylistDetailScreen({super.key, required this.itemData});
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color accentColor = const Color(0xFFFF5500);

  late Map<String, dynamic> _playlistData;

  List<Map<String, dynamic>> _originalSongs = [];
  List<Map<String, dynamic>> _songs = [];

  int _sortMode = 0;
  bool _isLoading = true;
  StreamSubscription? _playlistSub;

  List<dynamic> _cachedSuggestedSongs = [];
  bool _isLoadingSuggestions = true;
  // Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _playlistData = Map.from(widget.itemData);
    _setupSongsListener();
    _fetchSuggestedSongs();
  }

  void _setupSongsListener() {
    if (_playlistData['isCustom'] == true) {
      _playlistSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('playlists')
          .doc(_playlistData['id'])
          .collection('songs')
          .orderBy('addedAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              // 🌟 เอาการดักจับ snapshot.exists ออก เพราะเราใช้ pop 2 รอบช่วยชีวิตไว้แล้ว
              setState(() {
                _originalSongs = snapshot.docs
                    .map(
                      (doc) => {
                        'firestoreId': doc.id,
                        ...doc.data() as Map<String, dynamic>,
                      },
                    )
                    .toList();
                _applySort();
                _isLoading = false;
              });
            }
          });
    } else {
      _fetchiTunesTracks();
    }
  }

  Future<void> _fetchiTunesTracks() async {
    try {
      String url = _playlistData['type'] == 'Album'
          ? "https://itunes.apple.com/lookup?id=${_playlistData['id']}&entity=song"
          : "https://itunes.apple.com/search?term=hits&media=music&entity=song&limit=15";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tracks = _playlistData['type'] == 'Album'
            ? (json.decode(response.body)['results'] as List)
                  .where((i) => i['wrapperType'] == 'track')
                  .toList()
            : json.decode(response.body)['results'] as List;
        if (mounted) {
          setState(() {
            _originalSongs = tracks
                .map(
                  (t) => {
                    'id': t['trackId'].toString(),
                    'title': t['trackName'] ?? 'Unknown',
                    'artist': t['artistName'] ?? 'Unknown',
                    'previewUrl': t['previewUrl'],
                    'image': t['artworkUrl100'],
                  },
                )
                .toList();
            _applySort();
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSuggestedSongs() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://itunes.apple.com/search?term=hits&media=music&entity=song&limit=15",
        ),
      );
      if (response.statusCode == 200) {
        if (mounted)
          setState(() {
            _cachedSuggestedSongs = json.decode(response.body)['results'];
            _isLoadingSuggestions = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    // _debounce?.cancel();
    super.dispose();
  }

  void _toggleSort() {
    setState(() {
      _sortMode = (_sortMode + 1) % 3;
      _applySort();
    });
  }

  void _applySort() {
    if (_sortMode == 0) {
      _songs = List.from(_originalSongs);
    } else if (_sortMode == 1) {
      _songs = List.from(_originalSongs)
        ..sort(
          (a, b) => (a['title'] as String).toLowerCase().compareTo(
            (b['title'] as String).toLowerCase(),
          ),
        );
    } else if (_sortMode == 2) {
      _songs = List.from(_originalSongs)
        ..sort(
          (a, b) => (b['title'] as String).toLowerCase().compareTo(
            (a['title'] as String).toLowerCase(),
          ),
        );
    }
  }

  void _playSongAtIndex(int index) {
    context.read<MusicProvider>().playPlaylist(_songs, index);
  }

  void _toggleBigPlayButton() {
    final provider = context.read<MusicProvider>();
    if (_songs.isEmpty) return;

    if (provider.isPlaying) {
      provider.togglePlay();
    } else {
      if (provider.currentSong == null) {
        provider.playPlaylist(_songs, 0);
      } else {
        provider.togglePlay();
      }
    }
  }

  void _showDownloadComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "ระบบดาวน์โหลดกำลังจะมาเร็วๆ นี้",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      ),
    );
  }

  void _showSongOptions(Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song['image'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.music_note, color: Colors.white54),
              ),
            ),
            title: Text(
              song['title'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            subtitle: Text(
              song['artist'],
              style: const TextStyle(color: Colors.grey),
              maxLines: 1,
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.share_outlined, color: Colors.white),
            title: const Text(
              "แชร์เพลงนี้",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              showShareMenu(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text(
              "เพิ่มลงในเพลย์ลิสต์",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddToPlaylistSheet(song: song),
              );
            },
          ),
          if (_playlistData['isCustom'] == true)
            // 🌟 เลื่อนหาปุ่ม "ลบเพลย์ลิสต์" แล้วแก้โค้ดด้านใน onTap ให้เป็นแบบนี้ครับ:
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                "ลบเพลย์ลิสต์",
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                // 1. สั่งให้เด้งออกก่อนเลย 2 ครั้ง (ปิดเมนู + ปิดหน้าเพลย์ลิสต์) หนีหน้าจอขาว!
                Navigator.pop(context);
                Navigator.pop(context);

                // 2. ค่อยสั่งลบข้อมูลตามหลังเงียบๆ (ไม่ต้องใส่ await)
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('playlists')
                    .doc(_playlistData['id'])
                    .delete();
              },
            ),
        ],
      ),
    );
  }

  void _showAddSongsBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddSongSearchSheet(
        playlistData: _playlistData,
      ), // 🌟 เรียกใช้หน้าค้นหาจากไฟล์ใหม่
    );
  }

  void _showPlaylistOptionsSheet() {
    // 🌟 1. ดึง context ของหน้าจอเก็บไว้ในชื่อ screenContext
    final screenContext = context;

    showModalBottomSheet(
      context: screenContext,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (sheetContext) => Column(
        // 🌟 2. ตรงนี้เปลี่ยนเป็น sheetContext
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.share_outlined, color: Colors.white),
            title: const Text(
              "แชร์เพลย์ลิสต์",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(sheetContext); // 🌟 ใช้ sheetContext
              showShareMenu(screenContext);
            },
          ),

          if (_playlistData['isCustom'] == true)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                "ลบเพลย์ลิสต์",
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                // 🌟 3. ปิดเมนู Bottom Sheet (ใช้ sheetContext)
                Navigator.pop(sheetContext);

                // 🌟 4. ปิดหน้าเพลย์ลิสต์ กลับหน้า Library (ใช้ screenContext)
                Navigator.pop(screenContext);

                // 🌟 5. ค่อยลบข้อมูลใน Firebase (จะไม่จอขาวอีกต่อไป!)
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('playlists')
                      .doc(_playlistData['id'])
                      .delete();
                } catch (e) {
                  print("Delete Error: $e");
                }
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[600]!, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    bool _isAnyPlaying = provider.isPlaying;

    bool isLikedSongs = _playlistData['id'] == 'liked_songs';
    // 🌟 ดักค่า null ให้เป็น false อย่างปลอดภัย
    bool isCustom = _playlistData['isCustom'] ?? false;
    String imageUrl = _playlistData['imageUrl'] ?? '';
    String creatorName = _playlistData['creatorName'] ?? 'Unknown';

    String sortLabel = _sortMode == 0
        ? "จัดเรียง"
        : (_sortMode == 1 ? "เรียง A-Z" : "เรียง Z-A");

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3E3E3E), Color(0xFF121212)],
                  stops: [0.0, 0.6],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.65,
                          height: MediaQuery.of(context).size.width * 0.65,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: isLikedSongs
                              ? Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF4A00E0),
                                        Color(0xFF8E2DE2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                )
                              : (imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 100,
                                          color: Colors.white54,
                                        ),
                                      )),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _playlistData['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            isCustom
                                ? (_playlistData['isPublic'] == true
                                      ? Icons.public
                                      : Icons.lock)
                                : Icons.public,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            creatorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${_songs.length} แทร็ก",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _showDownloadComingSoon,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[600]!,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () => showShareMenu(context),
                                child: Icon(
                                  Icons.share_outlined,
                                  color: Colors.grey[400],
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () => _showPlaylistOptionsSheet(),
                                child: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[400],
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleBigPlayButton,
                                child: Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isAnyPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.black,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (isCustom)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildActionChip(
                                icon: Icons.add,
                                label: "เพิ่ม",
                                onTap: _showAddSongsBottomSheet,
                              ),
                              _buildActionChip(
                                icon: Icons.edit,
                                label: "แก้ไข",
                                onTap: () async {
                                  final updatedData = await showDialog(
                                    context: context,
                                    builder: (context) => EditPlaylistDialog(
                                      playlistData: _playlistData,
                                    ),
                                  );
                                  if (updatedData != null)
                                    setState(() => _playlistData = updatedData);
                                },
                              ),
                              _buildActionChip(
                                icon: Icons.sort,
                                label: sortLabel,
                                onTap: _toggleSort,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5500)),
              ),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_music_outlined,
                      size: 60,
                      color: Colors.grey[800],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "มาค้นหาเพลงกัน",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                var song = _songs[index];
                bool isThisPlaying = provider.currentSong?['id'] == song['id'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        song['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      if (isThisPlaying && _isAnyPlaying)
                        Container(
                          width: 50,
                          height: 50,
                          color: Colors.black.withOpacity(0.6),
                          child: const Icon(
                            Icons.equalizer,
                            color: Color(0xFFFF5500),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    song['title'],
                    style: TextStyle(
                      color: isThisPlaying
                          ? const Color(0xFFFF5500)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song['artist'],
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () => _showSongOptions(song),
                  ),
                  onTap: () => _playSongAtIndex(index),
                );
              }, childCount: _songs.length),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 180)),
        ],
      ),
    );
  }
}
