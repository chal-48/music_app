import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSongSearchSheet extends StatefulWidget {
  final Map<String, dynamic> playlistData;
  const AddSongSearchSheet({super.key, required this.playlistData});

  @override
  State<AddSongSearchSheet> createState() => _AddSongSearchSheetState();
}

class _AddSongSearchSheetState extends State<AddSongSearchSheet> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color accentColor = const Color(0xFFFF5500);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> _searchResults = [];
  bool _isSearching = false; 
  final Set<int> _addedIndexes = {}; 

  @override
  void initState() {
    super.initState();
    // 🌟 ดึงเพลงฮิต 10 เพลง (ใช้คำว่า "pop" จะได้เพลงฮิตจริงๆ ในสโตร์ไทย)
    _searchSongs("pop", isHitMode: true); 
  }

  @override
  void dispose() {
    _debounce?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // รีเฟรชปุ่ม X

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        // 🌟 ถ้าไม่มีการพิมพ์ ให้กลับไปโหมดแนะนำเพลงฮิต 10 เพลง
        _searchSongs("pop", isHitMode: true);
      } else {
        // 🌟 ถ้าพิมพ์ (แม้แต่ตัวเดียว) ให้ค้นหา 50 เพลง!
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
        // 🌟 จุดแก้ตัวอักษรต่างดาว: บังคับให้อ่านข้อมูลดิบ (bodyBytes) เป็น UTF-8 ก่อนแปลงเป็น JSON
        String decodedBody = utf8.decode(response.bodyBytes); 
        List<dynamic> fetchedResults = json.decode(decodedBody)['results'];

        // 🌟 จัดเรียงความแม่นยำ (โค้ดเดิม)
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
        print("🚨 API Error Status: ${response.statusCode}");
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      print("🚨 Search API Error: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    bool isShowingHits = _searchController.text.trim().isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Center(child: Text("ค้นหาเพลงเพื่อเพิ่ม", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),

          // 🌟 ช่องค้นหา
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "พิมพ์ชื่อเพลง หรือ ศิลปิน...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              
              // ปุ่ม X และตัวโหลด
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty && !_isSearching)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged(""); 
                      },
                    ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFFF5500), strokeWidth: 2)),
                    ),
                ],
              ),
              
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5500))),
            ),
            onChanged: _onSearchChanged, 
          ),
          const SizedBox(height: 20),

          // 🌟 โชว์หัวข้อให้ชัดเจน
          if (!_isSearching && _searchResults.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: Text(
                 isShowingHits ? "เพลงแนะนำสำหรับคุณ" : "ผลการค้นหา", 
                 style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
               ),
             ),

          // 🌟 แสดงรายการเพลง
          Expanded(
            child: (_searchResults.isEmpty && !_isSearching)
                ? Center(child: Text("ไม่พบเพลงที่ค้นหา", style: TextStyle(color: Colors.grey[500])))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var s = _searchResults[index];
                      bool isAdded = _addedIndexes.contains(index);

                      return ListTile(
                        contentPadding: EdgeInsets.zero, 
                        leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(s['artworkUrl100'], width: 45, height: 45, fit: BoxFit.cover)),
                        title: Text(s['trackName'], style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(s['artistName'], style: TextStyle(color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        
                        trailing: isAdded 
                          ? const Icon(Icons.check_circle, color: Color(0xFFFF5500))
                          : const Icon(Icons.add_circle_outline, color: Colors.white),
                        
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