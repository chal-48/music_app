import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart';

import 'add_song_search_sheet.dart';
import 'music_provider.dart';
import 'add_to_playlist_sheet.dart';
import 'share_helper.dart'; 
import 'edit_playlist_dialog.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const PlaylistDetailScreen({super.key, required this.itemData});
  @override State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  late Map<String, dynamic> _playlistData;
  List<Map<String, dynamic>> _originalSongs = [];
  List<Map<String, dynamic>> _songs = [];
  int _sortMode = 0;
  bool _isLoading = true;
  StreamSubscription? _playlistSub;

  @override
  void initState() {
    super.initState();
    _playlistData = Map.from(widget.itemData);
    _setupSongsListener();
  }

  void _setupSongsListener() {
    if (_playlistData['isCustom'] == true) {
      _playlistSub = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(_playlistData['id']).collection('songs').orderBy('addedAt', descending: true).snapshots().listen((snapshot) {
        if (mounted) {
          setState(() {
            _originalSongs = snapshot.docs.map((doc) => {'firestoreId': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
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
      String url = "https://itunes.apple.com/search?term=hits&media=music&entity=song&limit=15";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tracks = json.decode(response.body)['results'] as List;
        if (mounted) {
          setState(() {
            _originalSongs = tracks.map((t) => {'id': t['trackId'].toString(), 'title': t['trackName'] ?? 'Unknown', 'artist': t['artistName'] ?? 'Unknown', 'previewUrl': t['previewUrl'], 'image': t['artworkUrl100']}).toList();
            _applySort();
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    super.dispose();
  }

  void _toggleSort() { setState(() { _sortMode = (_sortMode + 1) % 3; _applySort(); }); }

  void _applySort() {
    if (_sortMode == 0) _songs = List.from(_originalSongs);
    else if (_sortMode == 1) _songs = List.from(_originalSongs)..sort((a, b) => (a['title'] as String).toLowerCase().compareTo((b['title'] as String).toLowerCase()));
    else if (_sortMode == 2) _songs = List.from(_originalSongs)..sort((a, b) => (b['title'] as String).toLowerCase().compareTo((a['title'] as String).toLowerCase()));
  }

  void _playSongAtIndex(int index) => context.read<MusicProvider>().playPlaylist(_songs, index);

  void _toggleBigPlayButton() {
    final provider = context.read<MusicProvider>();
    if (_songs.isEmpty) return;
    if (provider.isPlaying) provider.togglePlay();
    else if (provider.currentSong == null) provider.playPlaylist(_songs, 0);
    else provider.togglePlay();
  }

  void _showSongOptions(Map<String, dynamic> song, AppTheme t, LanguageProvider lang) {
    showModalBottomSheet(
      context: context, useRootNavigator: true, backgroundColor: t.sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.bottomSheetDrag, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(song['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.music_note, color: t.iconMuted))),
            title: Text(song['title'], style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold), maxLines: 1),
            subtitle: Text(song['artist'], style: TextStyle(color: t.textSecond), maxLines: 1),
          ),
          Divider(color: t.divider),
          ListTile(
            leading: Icon(Icons.share_outlined, color: t.textPrimary),
            title: Text(lang.t("Share Song"), style: TextStyle(color: t.textPrimary)),
            onTap: () { Navigator.pop(context); showShareMenu(context); },
          ),
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: t.textPrimary),
            title: Text(lang.t("Add to Playlist"), style: TextStyle(color: t.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(context: context, useRootNavigator: true, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AddToPlaylistSheet(song: song));
            },
          ),
          // 🌟 แก้บั๊ก: เปลี่ยนจากลบเพลย์ลิสต์ เป็นลบเพลงออกจากเพลย์ลิสต์
          if (_playlistData['isCustom'] == true)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              title: Text(lang.t("Remove from Playlist"), style: const TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(_playlistData['id']).collection('songs').doc(song['firestoreId']).delete();
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(_playlistData['id']).update({'songCount': FieldValue.increment(-1)});
                } catch (e) {}
              },
            ),
        ],
      ),
    );
  }

  void _showAddSongsBottomSheet() {
    showModalBottomSheet(context: context, useRootNavigator: true, isScrollControlled: true, backgroundColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => AddSongSearchSheet(playlistData: _playlistData));
  }

  void _showPlaylistOptionsSheet(AppTheme t, LanguageProvider lang) {
    final screenContext = context;
    showModalBottomSheet(
      context: screenContext, useRootNavigator: true, backgroundColor: t.sheetBg,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.bottomSheetDrag, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.share_outlined, color: t.textPrimary),
            title: Text(lang.t("Share Playlist"), style: TextStyle(color: t.textPrimary)),
            onTap: () { Navigator.pop(sheetContext); showShareMenu(screenContext); },
          ),
          if (_playlistData['isCustom'] == true)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(lang.t("Delete Playlist"), style: const TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(sheetContext);
                Navigator.pop(screenContext);
                try { await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(_playlistData['id']).delete(); } catch (e) {}
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required VoidCallback onTap, required AppTheme t}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(border: Border.all(color: t.border, width: 1.5), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Icon(icon, color: t.textPrimary, size: 16), const SizedBox(width: 6), Text(label, style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    bool _isAnyPlaying = provider.isPlaying;
    bool isLikedSongs = _playlistData['id'] == 'liked_songs';
    bool isCustom = _playlistData['isCustom'] ?? false;
    String imageUrl = _playlistData['imageUrl'] ?? '';
    String creatorName = _playlistData['creatorName'] ?? 'Unknown';

    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    String sortLabel = _sortMode == 0 ? lang.t("Sort") : (_sortMode == 1 ? lang.t("Sort A-Z") : lang.t("Sort Z-A"));

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: t.textPrimary)),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.surfaceHigh, t.bg], stops: const [0.0, 0.6]),
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
                          width: MediaQuery.of(context).size.width * 0.65, height: MediaQuery.of(context).size.width * 0.65,
                          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))]),
                          child: isLikedSongs
                              ? Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: const Icon(Icons.favorite, size: 100, color: Colors.white))
                              : (imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover) : Container(color: t.surfaceHigh, child: Icon(Icons.music_note, size: 100, color: t.iconMuted))),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(_playlistData['name'] ?? 'Unknown', style: TextStyle(color: t.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(isCustom ? (_playlistData['isPublic'] == true ? Icons.public : Icons.lock) : Icons.public, color: t.textSecond, size: 16),
                          const SizedBox(width: 8),
                          Text(creatorName, style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("${_songs.length} ${lang.t("tracks")}", style: TextStyle(color: t.textSecond, fontSize: 13)),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(onTap: () => showDownloadComingSoon(context), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: t.border), shape: BoxShape.circle), child: Icon(Icons.arrow_downward, color: t.textSecond, size: 20))),
                              const SizedBox(width: 20),
                              GestureDetector(onTap: () => showShareMenu(context), child: Icon(Icons.share_outlined, color: t.textSecond, size: 26)),
                              const SizedBox(width: 20),
                              GestureDetector(onTap: () => _showPlaylistOptionsSheet(t, lang), child: Icon(Icons.more_vert, color: t.textSecond, size: 28)),
                            ],
                          ),
                          GestureDetector(
                            onTap: _toggleBigPlayButton,
                            child: Container(width: 55, height: 55, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle), child: Icon(_isAnyPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (isCustom)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildActionChip(icon: Icons.add, label: lang.t("Add"), onTap: _showAddSongsBottomSheet, t: t),
                              _buildActionChip(
                                icon: Icons.edit, label: lang.t("Edit"), t: t,
                                onTap: () async {
                                  final updatedData = await showDialog(context: context, builder: (context) => EditPlaylistDialog(playlistData: _playlistData));
                                  if (updatedData != null) setState(() => _playlistData = updatedData);
                                },
                              ),
                              _buildActionChip(icon: Icons.sort, label: sortLabel, onTap: _toggleSort, t: t),
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
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.accent)))
          else if (_songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_music_outlined, size: 60, color: t.iconMuted),
                    const SizedBox(height: 16),
                    Text(lang.t("Let's find some songs"), style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(song['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: t.surfaceHigh, child: Icon(Icons.music_note, color: t.iconMuted))),
                      if (isThisPlaying && _isAnyPlaying) Container(width: 50, height: 50, color: Colors.black.withOpacity(0.6), child: const Icon(Icons.equalizer, color: AppTheme.accent)),
                    ],
                  ),
                  title: Text(song['title'], style: TextStyle(color: isThisPlaying ? AppTheme.accent : t.textPrimary, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song['artist'], style: TextStyle(color: t.textSecond, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(icon: Icon(Icons.more_vert, color: t.iconMuted), onPressed: () => _showSongOptions(song, t, lang)),
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