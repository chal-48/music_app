import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// 🌟 Import Theme และ Provider มาใช้งาน
import 'app_theme.dart';
import 'profile_screen.dart';

class AddSongSearchSheet extends StatefulWidget {
  final Map<String, dynamic> playlistData;
  const AddSongSearchSheet({super.key, required this.playlistData});

  @override
  State<AddSongSearchSheet> createState() => _AddSongSearchSheetState();
}

class _AddSongSearchSheetState extends State<AddSongSearchSheet> {
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> _searchResults = [];
  bool _isSearching = false; 
  final Set<int> _addedIndexes = {}; 

  @override
  void initState() {
    super.initState();
    _searchSongs("pop", isHitMode: true); 
  }

  @override
  void dispose() {
    _debounce?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        _searchSongs("pop", isHitMode: true);
      } else {
        _searchSongs(query.trim(), isHitMode: false);
      }
    });
  }

  Future<void> _searchSongs(String query, {required bool isHitMode}) async {
    setState(() => _isSearching = true); 
    
    int limitCount = isHitMode ? 10 : 50; 
    
    try {
      final originalUrl = 'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=$limitCount&country=th';
      final proxyUrl = 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';

      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        String decodedBody = utf8.decode(response.bodyBytes); 
        List<dynamic> fetchedResults = json.decode(decodedBody)['results'];

        if (!isHitMode && query.isNotEmpty) {
          String q = query.toLowerCase(); 

          fetchedResults.sort((a, b) {
            String titleA = (a['trackName'] ?? '').toLowerCase();
            String artistA = (a['artistName'] ?? '').toLowerCase();
            String titleB = (b['trackName'] ?? '').toLowerCase();
            String artistB = (b['artistName'] ?? '').toLowerCase();

            int scoreA = 0;
            if (titleA == q || artistA == q) scoreA = 3; 
            else if (titleA.startsWith(q) || artistA.startsWith(q)) scoreA = 2; 
            else if (titleA.contains(q) || artistA.contains(q)) scoreA = 1; 

            int scoreB = 0;
            if (titleB == q || artistB == q) scoreB = 3;
            else if (titleB.startsWith(q) || artistB.startsWith(q)) scoreB = 2;
            else if (titleB.contains(q) || artistB.contains(q)) scoreB = 1;

            return scoreB.compareTo(scoreA);
          });
        }

        if (mounted) {
          setState(() {
            _searchResults = fetchedResults; 
            _addedIndexes.clear(); 
            _isSearching = false; 
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 ดึงค่า ธีม และ ภาษา
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    bool isShowingHits = _searchController.text.trim().isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: t.sheetBg, // 🌟 สีพื้นหลังแผ่นสไลด์ตามธีม
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: t.bottomSheetDrag, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Center(
            child: Text(
              lang.t("Search songs to add"), // 🌟 ใช้ระบบแปลภาษา
              style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)
            )
          ),
          const SizedBox(height: 16),

          // 🌟 ช่องค้นหา
          TextField(
            controller: _searchController,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              hintText: lang.t("Type song or artist..."), // 🌟 ใช้ระบบแปลภาษา
              hintStyle: TextStyle(color: t.textHint),
              prefixIcon: Icon(Icons.search, color: t.iconMuted),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty && !_isSearching)
                    IconButton(
                      icon: Icon(Icons.clear, color: t.iconMuted),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged(""); 
                      },
                    ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2)),
                    ),
                ],
              ),
              filled: true,
              fillColor: t.surfaceHigh, // 🌟 สีพื้นหลังช่องค้นหา
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
            ),
            onChanged: _onSearchChanged, 
          ),
          const SizedBox(height: 20),

          if (!_isSearching && _searchResults.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: Text(
                 isShowingHits ? lang.t("Recommended for you") : lang.t("Search Results"), // 🌟 ใช้ระบบแปลภาษา
                 style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)
               ),
             ),

          // 🌟 แสดงรายการเพลง
          Expanded(
            child: (_searchResults.isEmpty && !_isSearching)
                ? Center(
                    child: Text(
                      lang.t("No songs found"), // 🌟 ใช้ระบบแปลภาษา
                      style: TextStyle(color: t.textHint)
                    )
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var s = _searchResults[index];
                      bool isAdded = _addedIndexes.contains(index);

                      return ListTile(
                        contentPadding: EdgeInsets.zero, 
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4), 
                          child: Image.network(
                            s['artworkUrl100'], width: 45, height: 45, fit: BoxFit.cover,
                            errorBuilder: (c,e,er) => Container(width: 45, height: 45, color: t.surfaceHigh, child: Icon(Icons.music_note, color: t.iconMuted)),
                          )
                        ),
                        title: Text(s['trackName'], style: TextStyle(color: t.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(s['artistName'], style: TextStyle(color: t.textSecond), maxLines: 1, overflow: TextOverflow.ellipsis),
                        
                        trailing: isAdded 
                          ? const Icon(Icons.check_circle, color: AppTheme.accent)
                          : Icon(Icons.add_circle_outline, color: t.textPrimary),
                        
                        onTap: isAdded ? null : () async {
                          setState(() => _addedIndexes.add(index));

                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (mounted && Navigator.canPop(context)) Navigator.pop(context);
                          });

                          if (user != null) {
                            try {
                              await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(widget.playlistData['id']).collection('songs').add({
                                'id': s['trackId'].toString(),
                                'title': s['trackName'],
                                'artist': s['artistName'],
                                'image': s['artworkUrl100'],
                                'previewUrl': s['previewUrl'],
                                'addedAt': FieldValue.serverTimestamp()
                              });
                              await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('playlists').doc(widget.playlistData['id']).update({
                                'songCount': FieldValue.increment(1)
                              });
                            } catch (e) {
                              print("Error adding song: $e");
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}