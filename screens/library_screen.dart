import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart'; // ดึง Provider
import 'create_playlist_dialog.dart';
import 'playlist_detail_screen.dart';

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
    // 🌟 ดึงค่า ธีม และ ภาษา
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: t.bg, // 🌟 สีพื้นหลังเปลี่ยนตามธีม
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t("Your Library"),
                        style: GoogleFonts.inter(
                          color: t.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        lang.t("All your playlists in one place 🎶"),
                        style: GoogleFonts.inter(
                          color: t.textSecond,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => showCreatePlaylistDialogAutoName(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t("Playlists"),
                    style: GoogleFonts.inter(
                      color: t.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isGrid = !isGrid),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: t.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                        color: t.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: currentUser == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: t.iconMuted, size: 48),
                          const SizedBox(height: 12),
                          Text("Please log in to view your library", style: GoogleFonts.inter(color: t.textHint, fontSize: 14)),
                        ],
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('playlists').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                        }
                        List<Map<String, dynamic>> finalItems = [
                          { "id": "liked_songs", "name": lang.t("Liked Songs"), "subtitle": lang.t("Your favorite tracks"), "isCustom": false },
                        ];
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            if (doc.id == 'liked_songs') continue;
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            int songCount = data['songCount'] ?? 0;
                            String creatorName = data['creatorName'] ?? '';
                            if (creatorName.isEmpty || creatorName == 'Unknown') {
                              creatorName = currentUser!.displayName ?? currentUser!.email?.split('@')[0] ?? 'User';
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
                        if (finalItems.length == 1) {
                          return Column(
                            children: [
                              _buildListItem(finalItems[0], t),
                              const SizedBox(height: 32),
                              Icon(Icons.library_music_outlined, color: t.iconMuted, size: 48),
                              const SizedBox(height: 12),
                              Text(lang.t("No playlists yet"), style: GoogleFonts.inter(color: t.textHint, fontSize: 15)),
                              const SizedBox(height: 6),
                              Text(lang.t("Tap + to create your first playlist"), style: GoogleFonts.inter(color: t.textHint, fontSize: 13)),
                            ],
                          );
                        }
                        return isGrid ? _buildGridView(finalItems, t) : _buildListView(finalItems, t);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> items, AppTheme t) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 180),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildListItem(items[index], t),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, AppTheme t) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistDetailScreen(itemData: item))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            _buildImage(item, t, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: GoogleFonts.inter(color: item['id'] == 'liked_songs' ? AppTheme.accent : t.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(item['subtitle'], style: GoogleFonts.inter(color: t.textSecond, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.iconMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items, AppTheme t) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 180),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 20, childAspectRatio: 0.70,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistDetailScreen(itemData: item))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌟 แก้ตรงนี้: ใช้ AspectRatio บังคับให้เป็นสี่เหลี่ยมจัตุรัส 1:1 รูปจะไม่ยืดแล้วครับ
              AspectRatio(
                aspectRatio: 1, 
                child: _buildImage(item, t, size: double.infinity),
              ),
              const SizedBox(height: 10),
              Text(item['name'], style: GoogleFonts.inter(color: item['id'] == 'liked_songs' ? AppTheme.accent : t.textPrimary, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(item['subtitle'], style: GoogleFonts.inter(color: t.textSecond, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(Map<String, dynamic> item, AppTheme t, {required double size}) {
    if (item['id'] == 'liked_songs') {
      return Container(
        width: size == double.infinity ? null : size, height: size == double.infinity ? null : size,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFF4A00E0).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: size == double.infinity ? 36 : size * 0.38),
      );
    }
    if (item['imageUrl'] != null && (item['imageUrl'] as String).isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(item['imageUrl'], width: size == double.infinity ? null : size, height: size == double.infinity ? null : size, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(size, t)),
      );
    }
    return _buildPlaceholder(size, t);
  }

  Widget _buildPlaceholder(double size, AppTheme t) {
    return Container(
      width: size == double.infinity ? null : size, height: size == double.infinity ? null : size,
      decoration: BoxDecoration(color: t.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.my_library_music_rounded, color: t.iconMuted, size: size == double.infinity ? 36 : size * 0.38),
    );
  }
}