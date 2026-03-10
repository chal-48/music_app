import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'music_provider.dart';
// 🌟 นำเข้าไฟล์ AddToPlaylistSheet (แก้ชื่อไฟล์ตรงนี้ให้ตรงกับโปรเจกต์ของคุณนะครับ)
import 'add_to_playlist_sheet.dart'; 

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // ข้อมูลหมวดหมู่
  // ข้อมูลหมวดหมู่ (อัปเดตลิงก์รูปใหม่ที่ใช้งานได้ 100%)
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'เพลงฮิต (Hits)',
      'query': 'top hits',
      'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80',
    },
    {
      'title': 'เพลงไทย (T-Pop)',
      'query': 'thai pop',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80',
    },
    {
      'title': 'ลูกทุ่งมาแรง',
      'query': 'มนต์แคน', // 🌟 ใช้ชื่อศิลปินดังเลย รับรองเพลงลูกทุ่งมาตรึม!
      'image': 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=500&q=80', // 🌟 ลิงก์รูปใหม่ เสถียรแน่นอน
    },
    {
      'title': 'เคป็อป (K-Pop)',
      'query': 'korean pop',
      'image': 'https://images.unsplash.com/photo-1611002214172-792c1f90b59a?w=500&q=80',
    },
    {
      'title': 'สากลฮิต',
      'query': 'billboard hot 100',
      // 🌟 เปลี่ยนรูปสากลฮิตใหม่
      'image': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=500&q=80',
    },
    {
      'title': 'ร็อค (Rock)',
      'query': 'rock music',
      'image': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=500&q=80',
    },
    {
      'title': 'อินดี้ (Indie)',
      'query': 'indie pop',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
    },
    {
      'title': 'ชิลล์ (Acoustic)',
      'query': 'acoustic chill',
      'image': 'https://images.unsplash.com/photo-1460723237483-7a6dc9d0b212?w=500&q=80',
    },
  ];
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
      if (query.trim().isNotEmpty) {
        _searchSongs(query.trim());
      } else {
        setState(() => _searchResults.clear());
      }
    });
  }

  Future<void> _searchSongs(String query) async {
    setState(() => _isSearching = true);
    try {
      final originalUrl =
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=50&country=th';
      final proxyUrl =
          'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';

      final response = await http
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        String decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> fetchedResults = json.decode(decodedBody)['results'];

        String q = query.toLowerCase();
        fetchedResults.sort((a, b) {
          String titleA = (a['trackName'] ?? '').toLowerCase();
          String artistA = (a['artistName'] ?? '').toLowerCase();
          String titleB = (b['trackName'] ?? '').toLowerCase();
          String artistB = (b['artistName'] ?? '').toLowerCase();

          int scoreA = 0, scoreB = 0;
          if (titleA == q || artistA == q)
            scoreA = 3;
          else if (titleA.startsWith(q) || artistA.startsWith(q))
            scoreA = 2;
          else if (titleA.contains(q) || artistA.contains(q))
            scoreA = 1;

          if (titleB == q || artistB == q)
            scoreB = 3;
          else if (titleB.startsWith(q) || artistB.startsWith(q))
            scoreB = 2;
          else if (titleB.contains(q) || artistB.contains(q))
            scoreB = 1;

          return scoreB.compareTo(scoreA);
        });

        if (mounted)
          setState(() {
            _searchResults = fetchedResults;
            _isSearching = false;
          });
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isShowingCategories = _searchController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "ค้นหา",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "ศิลปิน, เพลง, หรือพอดแคสต์...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF5500),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF5500)),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 24),

              Expanded(
                child: isShowingCategories
                    ? _buildCategoriesGrid()
                    : _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "เลือกดูตามหมวดหมู่",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              var cat = _categories[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(categoryData: cat),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(cat['image']),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.topLeft,
                  child: Text(
                    cat['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isSearching)
      return Center(
        child: Text(
          "ไม่พบผลการค้นหา",
          style: TextStyle(color: Colors.grey[500]),
        ),
      );

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var s = _searchResults[index];

        var provider = context.watch<MusicProvider>();
        bool isPlaying = false;
        try {
          if (provider.currentSong?['id'] == s['trackId'].toString()) {
            isPlaying = true;
          }
        } catch (e) {}

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          
          // 🌟 นำดีไซน์ Stack จากหน้า Library มาใส่ตรงนี้!
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. รูปภาพหน้าปก
                Image.network(
                  s['artworkUrl100'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, err) => Container(
                    width: 50, height: 50, color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
                // 2. ถ้ากำลังเล่นอยู่ ให้โชว์ฟิลเตอร์ดำมืดๆ + ไอคอนคลื่นเสียงทับบนรูป!
                if (isPlaying)
                  Container(
                    width: 50,
                    height: 50,
                    color: Colors.black.withOpacity(0.6), // สีดำโปร่งแสงทับรูป
                    child: const Icon(Icons.equalizer, color: Color(0xFFFF5500)), // ไอคอนคลื่นเสียง
                  ),
              ],
            ),
          ),

          // ชื่อเพลง (เปลี่ยนสีเมื่อเล่นอยู่)
          title: Text(
            s['trackName'],
            style: TextStyle(
              color: isPlaying ? const Color(0xFFFF5500) : Colors.white,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ชื่อศิลปิน (เอาคลื่นเสียงด้านหน้าออก เพราะย้ายไปอยู่บนรูปแล้ว)
          subtitle: Text(
            s['artistName'],
            style: TextStyle(color: Colors.grey[400]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // จุดไข่ปลา
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              _showSongOptions(context, {
                'id': s['trackId'].toString(),
                'title': s['trackName'],
                'artist': s['artistName'],
                'image': s['artworkUrl100'],
                'previewUrl': s['previewUrl'],
              });
            },
          ),

          onTap: () {
            var playProvider = Provider.of<MusicProvider>(context, listen: false);
            playProvider.playSong({
              'id': s['trackId'].toString(),
              'title': s['trackName'],
              'artist': s['artistName'],
              'image': s['artworkUrl100'],
              'previewUrl': s['previewUrl'],
            });
          },
        );;
      },
    );
  }

  // 🌟 ฟังก์ชันจุดไข่ปลา
  void _showSongOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),

          // 1. โชว์รูปปก ชื่อเพลง ศิลปิน
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
            title: Text(song['title'] ?? 'Unknown',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1),
            subtitle: Text(song['artist'] ?? 'Unknown',
                style: const TextStyle(color: Colors.grey), maxLines: 1),
          ),
          const Divider(color: Colors.white12),

          // 2. ปุ่มแชร์
          ListTile(
            leading: const Icon(Icons.share_outlined, color: Colors.white),
            title: const Text("แชร์เพลงนี้",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(sheetContext);
              // showShareMenu(context);
            },
          ),

          // 3. ปุ่มเพิ่มลงเพลย์ลิสต์
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text("เพิ่มลงในเพลย์ลิสต์",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(sheetContext);

              // เปิดหน้าต่าง AddToPlaylistSheet
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddToPlaylistSheet(song: song),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// 🌟 หน้าจอเพลย์ลิสต์ของหมวดหมู่ 
// ============================================================================
class CategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> categoryData;
  const CategoryDetailScreen({super.key, required this.categoryData});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategorySongs();
  }

  Future<void> _fetchCategorySongs() async {
    try {
      final originalUrl =
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(widget.categoryData['query'])}&media=music&entity=song&limit=50&country=th';
      final proxyUrl =
          'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';

      final response = await http
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _songs = json.decode(utf8.decode(response.bodyBytes))['results'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playSong(Map<String, dynamic> songInfo) {
    var provider = Provider.of<MusicProvider>(context, listen: false);
    provider.playSong({
      'id': songInfo['trackId'].toString(),
      'title': songInfo['trackName'],
      'artist': songInfo['artistName'],
      'image': songInfo['artworkUrl100'],
      'previewUrl': songInfo['previewUrl'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5500)),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: const Color(0xFF121212),
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.categoryData['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.categoryData['image'],
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                const Color(0xFF121212),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "เพลงแนะนำสำหรับคุณ",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_songs.length} แทร็ก",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFF5500),
                          child: IconButton(
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () {
                              if (_songs.isNotEmpty) _playSong(_songs[0]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var s = _songs[index];

                    var provider = context.watch<MusicProvider>();
                    bool isPlaying = false;
                    try {
                      if (provider.currentSong?['id'] ==
                          s['trackId'].toString()) {
                        isPlaying = true;
                      }
                    } catch (e) {}

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      
                      // 🌟 ดีไซน์ Stack ซ้อนรูปเหมือนกัน
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              s['artworkUrl100'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, err) => Container(
                                width: 50, height: 50, color: Colors.grey[800],
                                child: const Icon(Icons.music_note, color: Colors.white54),
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.black.withOpacity(0.6),
                                child: const Icon(Icons.equalizer, color: Color(0xFFFF5500)),
                              ),
                          ],
                        ),
                      ),

                      title: Text(
                        s['trackName'],
                        style: TextStyle(
                          color: isPlaying ? const Color(0xFFFF5500) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      subtitle: Text(
                        s['artistName'],
                        style: TextStyle(color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () {
                          _showSongOptions(context, {
                            'id': s['trackId'].toString(),
                            'title': s['trackName'],
                            'artist': s['artistName'],
                            'image': s['artworkUrl100'],
                            'previewUrl': s['previewUrl'],
                          });
                        },
                      ),

                      onTap: () => _playSong(s),
                    );;
                  }, childCount: _songs.length),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  // 🌟 ฟังก์ชันจุดไข่ปลา
  void _showSongOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),

          // 1. โชว์รูปปก ชื่อเพลง ศิลปิน
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
            title: Text(song['title'] ?? 'Unknown',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                maxLines: 1),
            subtitle: Text(song['artist'] ?? 'Unknown',
                style: const TextStyle(color: Colors.grey), maxLines: 1),
          ),
          const Divider(color: Colors.white12),

          // 2. ปุ่มแชร์
          ListTile(
            leading: const Icon(Icons.share_outlined, color: Colors.white),
            title: const Text("แชร์เพลงนี้",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(sheetContext);
              // showShareMenu(context);
            },
          ),

          // 3. ปุ่มเพิ่มลงเพลย์ลิสต์
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text("เพิ่มลงในเพลย์ลิสต์",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(sheetContext);

              // เปิดหน้าต่าง AddToPlaylistSheet
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddToPlaylistSheet(song: song),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}