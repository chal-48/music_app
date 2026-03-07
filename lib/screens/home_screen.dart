import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'music_provider.dart';
import 'add_to_playlist_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🌟 State สำหรับปุ่ม Filter
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["ทั้งหมด", "เพลง", "พอดแคสต์"];

  // 🌟 ข้อมูลเพลง
  List<dynamic> _recentSongs = [];
  List<dynamic> _recommendedSongs = [];
  List<dynamic> _topHitsSongs = [];
  List<dynamic> _newReleaseSongs = [];

  bool _isLoading = true;

  // 🌟 ข้อมูลศิลปิน
  final List<Map<String, String>> _artists = [
    {
      'name': 'Three Man Down',
      'image':
          'https://images.unsplash.com/photo-1520182205149-1e5e4e7329b4?w=300&q=80',
    },
    {
      'name': 'Tilly Birds',
      'image':
          'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=300&q=80',
    },
    {
      'name': 'Bowkylion',
      'image':
          'https://images.unsplash.com/photo-1493225457124-a1a4a5aa99b8?w=300&q=80',
    },
    {
      'name': 'Polycat',
      'image':
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
    },
    {
      'name': 'Nont Tanont',
      'image':
          'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'อรุณสวัสดิ์ ☀️';
    if (hour < 17) return 'สวัสดีตอนบ่าย ☕';
    if (hour < 20) return 'สวัสดีตอนเย็น 🌆';
    return 'ราตรีสวัสดิ์ 🌙';
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchCategory('thai pop', (data) => _recentSongs = data),
      _fetchCategory('acoustic chill', (data) => _recommendedSongs = data),
      _fetchCategory('top hits thailand', (data) => _topHitsSongs = data),
      _fetchCategory('new release 2024', (data) => _newReleaseSongs = data),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCategory(
    String query,
    Function(List<dynamic>) onDataLoaded,
  ) async {
    try {
      final originalUrl =
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=10&country=th';
      final proxyUrl =
          'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';
      final response = await http
          .get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        String decodedBody = utf8.decode(response.bodyBytes);
        onDataLoaded(json.decode(decodedBody)['results']);
      }
    } catch (e) {
      print("Error: $e");
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

  // 🌟 ฟังก์ชันโชว์แจ้งเตือนสวยๆ เวลากดปุ่มที่ยังไม่มีหน้าต่าง
  void _showModernSnackbar(String message, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        content: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF5500)),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSongOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
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
              song['title'] ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            subtitle: Text(
              song['artist'] ?? 'Unknown',
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
              Navigator.pop(sheetContext);
              _showModernSnackbar("คัดลอกลิงก์แชร์แล้ว!", Icons.check_circle);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text(
              "เพิ่มลงในเพลย์ลิสต์",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌟 อัปเกรดพื้นหลังแบบไล่สี (Gradient) เพื่อความมีมิติแบบพรีเมียม
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A1B14), Color(0xFF121212), Color(0xFF121212)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5500)),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 🌟 ระบบเนื้อหาเปลี่ยนตาม Filter อัจฉริยะ
                      if (_selectedFilterIndex == 2)
                        _buildPodcastEmptyState() // ถ้าเลือกพอดแคสต์ โชว์หน้าว่าง
                      else ...[
                        // ถ้าเลือกทั้งหมด หรือ เพลง ให้โชว์คอนเทนต์ตามปกติ
                        _buildFeaturedBanner(),
                        const SizedBox(height: 24),

                        if (_recentSongs.isNotEmpty) ...[
                          _buildRecentGrid(),
                          const SizedBox(height: 32),
                        ],

                        _buildArtistsList(),
                        const SizedBox(height: 32),

                        if (_recommendedSongs.isNotEmpty) ...[
                          _buildHorizontalList(
                            "มิกซ์สำหรับคุณ",
                            _recommendedSongs,
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (_newReleaseSongs.isNotEmpty) ...[
                          _buildHorizontalList(
                            "เพลงใหม่เพิ่งออก",
                            _newReleaseSongs,
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (_topHitsSongs.isNotEmpty) ...[
                          _buildHorizontalList(
                            "ฮิตติดชาร์ตประเทศไทย",
                            _topHitsSongs,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🌟 UI Components
  // ==========================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Row(
        children: [
          // รูปโปรไฟล์กดได้
          GestureDetector(
            onTap: () =>
                _showModernSnackbar("เปิดหน้าโปรไฟล์ผู้ใช้", Icons.person),
            child: const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&q=80',
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ปุ่ม Filter แบบ AnimatedContainer
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF5500)
                            : Colors.grey[800]?.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white12,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // ปุ่มเมนูด้านขวา
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () => _showModernSnackbar(
                  "ไม่มีการแจ้งเตือนใหม่",
                  Icons.notifications_active,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () =>
                    _showModernSnackbar("ประวัติการฟังเพลง", Icons.history),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => _showModernSnackbar(
                  "เข้าสู่เมนูการตั้งค่า",
                  Icons.settings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 หน้าว่างสำหรับ Podcast
  Widget _buildPodcastEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.podcasts, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              "ฟีเจอร์พอดแคสต์กำลังมา!",
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "อดใจรออีกนิด เรากำลังเตรียมเนื้อหาดีๆ ให้คุณ",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // แบนเนอร์กดได้ (ใช้ InkWell ให้มีแสงกระเพื่อม)
  Widget _buildFeaturedBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5500).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // 🌟 กดแบนเนอร์แล้วเล่นเพลงใหม่ทันที
          onTap: () {
            if (_newReleaseSongs.isNotEmpty) _playSong(_newReleaseSongs[0]);
            // _showModernSnackbar(
            //   "กำลังเล่นอัลบั้มใหม่ล่าสุด",
            //   Icons.play_circle_fill,
            // );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NEW ALBUM",
                  style: TextStyle(
                    color: Color(0xFFFF5500),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Vibrations 2024",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "สตรีมได้แล้ววันนี้ • กดเพื่อฟังเลย",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // แถวศิลปินกดได้
  Widget _buildArtistsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "ศิลปินคนโปรดของคุณ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _artists.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                // 🌟 กดศิลปินแล้วแจ้งเตือน
                onTap: () {
                  // 🌟 สั่งให้เด้งไปหน้าจอประวัติ/เพลงของศิลปินคนนั้น
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArtistDetailScreen(artistData: _artists[index]),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: NetworkImage(
                          _artists[index]['image']!,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _artists[index]['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _recentSongs.length > 6 ? 6 : _recentSongs.length,
        itemBuilder: (context, index) {
          var s = _recentSongs[index];
          var provider = context.watch<MusicProvider>();
          bool isPlaying =
              provider.currentSong?['id'] == s['trackId'].toString();

          return Material(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _playSong(s),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          s['artworkUrl100'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, err) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        if (isPlaying)
                          Container(
                            width: 56,
                            height: 56,
                            color: Colors.black.withOpacity(0.6),
                            child: const Icon(
                              Icons.equalizer,
                              color: Color(0xFFFF5500),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['trackName'],
                      style: TextStyle(
                        color: isPlaying
                            ? const Color(0xFFFF5500)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList(String title, List<dynamic> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              var s = songs[index];
              var provider = context.watch<MusicProvider>();
              bool isPlaying =
                  provider.currentSong?['id'] == s['trackId'].toString();

              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _playSong(s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              s['artworkUrl100'].replaceAll(
                                '100x100bb',
                                '300x300bb',
                              ),
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, err) => Container(
                                width: 140,
                                height: 140,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                  size: 40,
                                ),
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                width: 140,
                                height: 140,
                                color: Colors.black.withOpacity(0.6),
                                child: const Icon(
                                  Icons.equalizer,
                                  color: Color(0xFFFF5500),
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['trackName'],
                                  style: TextStyle(
                                    color: isPlaying
                                        ? const Color(0xFFFF5500)
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s['artistName'],
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSongOptions(context, {
                              'id': s['trackId'].toString(),
                              'title': s['trackName'],
                              'artist': s['artistName'],
                              'image': s['artworkUrl100'],
                              'previewUrl': s['previewUrl'],
                            }),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
}
// ============================================================================
// 🌟 หน้าจอใหม่: โปรไฟล์ศิลปิน (Artist Profile Screen)
// ============================================================================
class ArtistDetailScreen extends StatefulWidget {
  final Map<String, String> artistData;
  const ArtistDetailScreen({super.key, required this.artistData});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtistSongs();
  }

  // 🌟 ดึงเพลงเฉพาะของศิลปินคนนี้จาก iTunes API
  Future<void> _fetchArtistSongs() async {
    try {
      final originalUrl = 'https://itunes.apple.com/search?term=${Uri.encodeComponent(widget.artistData['name']!)}&media=music&entity=song&limit=50&country=th';
      final proxyUrl = 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';

      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 15));
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

  void _showSongOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context, useRootNavigator: true, backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(song['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.music_note, color: Colors.white54))),
            title: Text(song['title'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
            subtitle: Text(song['artist'] ?? 'Unknown', style: const TextStyle(color: Colors.grey), maxLines: 1),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.white),
            title: const Text("เพิ่มลงในเพลย์ลิสต์", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(sheetContext);
              showModalBottomSheet(
                context: context, useRootNavigator: true, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (context) => AddToPlaylistSheet(song: song), 
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🌟 รูปปกศิลปิน (ยืดหดได้เวลาเลื่อนจอ)
                SliverAppBar(
                  expandedHeight: 350,
                  pinned: true,
                  backgroundColor: const Color(0xFF121212),
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                    title: Text(
                      widget.artistData['name']!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(widget.artistData['image']!, fit: BoxFit.cover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.4), const Color(0xFF121212)],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🌟 ปุ่ม Play ศิลปินคนนี้
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("เพลงยอดนิยม", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${_songs.length} เพลง", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                          ],
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFFF5500),
                          child: IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                            onPressed: () {
                              if (_songs.isNotEmpty) _playSong(_songs[0]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🌟 รายชื่อเพลงของศิลปิน
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var s = _songs[index];
                    var provider = context.watch<MusicProvider>();
                    bool isPlaying = false;
                    try {
                      if (provider.currentSong?['id'] == s['trackId'].toString()) isPlaying = true;
                    } catch (e) {}

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(s['artworkUrl100'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, err) => Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.music_note, color: Colors.white54))),
                            if (isPlaying) Container(width: 50, height: 50, color: Colors.black.withOpacity(0.6), child: const Icon(Icons.equalizer, color: Color(0xFFFF5500))),
                          ],
                        ),
                      ),
                      title: Text(
                        s['trackName'],
                        style: TextStyle(color: isPlaying ? const Color(0xFFFF5500) : Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(s['artistName'], style: TextStyle(color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () {
                          _showSongOptions(context, {'id': s['trackId'].toString(), 'title': s['trackName'], 'artist': s['artistName'], 'image': s['artworkUrl100'], 'previewUrl': s['previewUrl']});
                        },
                      ),
                      onTap: () => _playSong(s),
                    );
                  }, childCount: _songs.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}