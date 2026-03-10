import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart'; // 🌟 ดึงค่า Theme มาใช้
import 'profile_screen.dart'; // 🌟 ดึง LanguageProvider และ ThemeProvider มาใช้
import 'music_provider.dart';
import 'add_to_playlist_sheet.dart';
import 'app_font.dart';
import 'share_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _recentSongs = [];
  List<dynamic> _recommendedSongs = [];
  List<dynamic> _topHitsSongs = [];
  List<dynamic> _newReleaseSongs = [];

  bool _isLoading = true;

  final List<String> _artistNames = [
    'Three Man Down',
    'Tilly Birds',
    'Bowkylion',
    'Polycat',
    'Nont Tanont',
  ];

  List<Map<String, String>> _artists = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // 🌟 ใช้ LanguageProvider เพื่อแปลภาษาคำทักทาย
 String _getGreeting(LanguageProvider lang) {
    var hour = DateTime.now().hour;
    if (hour < 12) return lang.t('Good Morning');
    if (hour < 17) return lang.t('Good Afternoon');
    if (hour < 20) return lang.t('Good Evening');
    return lang.t('Good Night');
  }

  String _getSubGreeting(LanguageProvider lang) {
    var hour = DateTime.now().hour;
    if (hour < 12) return lang.t('Ready for some music? 🎧');
    if (hour < 17) return lang.t('Keep the music playing 🎵');
    if (hour < 20) return lang.t('Relax with some tunes 🌆');
    return lang.t('Enjoy calm music 🌙');
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchCategory('thai pop', (data) => _recentSongs = data),
      _fetchCategory('acoustic chill', (data) => _recommendedSongs = data),
      _fetchCategory('top hits thailand', (data) => _topHitsSongs = data),
      _fetchCategory('new release 2024', (data) => _newReleaseSongs = data),
      _fetchArtistImages(),
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

  Future<void> _fetchArtistImages() async {
    List<Map<String, String>> fetchedArtists = [];

    for (String name in _artistNames) {
      try {
        final originalUrl =
            'https://itunes.apple.com/search?term=${Uri.encodeComponent(name)}&media=music&entity=song&limit=1&country=th';
        final proxyUrl =
            'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';

        final response = await http
            .get(Uri.parse(proxyUrl))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          var results = json.decode(utf8.decode(response.bodyBytes))['results'];
          if (results.isNotEmpty) {
            String imageUrl = results[0]['artworkUrl100'].toString().replaceAll(
              '100x100bb',
              '600x600bb',
            );
            fetchedArtists.add({'name': name, 'image': imageUrl});
          }
        }
      } catch (e) {
        print("Error fetching artist $name: $e");
      }
    }

    if (mounted) {
      setState(() {
        _artists = fetchedArtists;
      });
    }
  }

  void _playSong(Map<String, dynamic> songInfo, List<dynamic> sourceList) {
    var provider = Provider.of<MusicProvider>(context, listen: false);

    List<Map<String, dynamic>> playlist = sourceList
        .map(
          (s) => {
            'id': s['trackId'].toString(),
            'title': s['trackName'],
            'artist': s['artistName'],
            'image': s['artworkUrl100'],
            'previewUrl': s['previewUrl'],
          },
        )
        .toList();

    int startIndex = playlist.indexWhere(
      (s) => s['id'] == songInfo['trackId'].toString(),
    );
    provider.playPlaylist(playlist, startIndex != -1 ? startIndex : 0);
  }

  void _showSongOptions(
    BuildContext context,
    Map<String, dynamic> song,
    AppTheme t,
    LanguageProvider lang,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: t.surface, // 🌟 สีเมนูตามธีม
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
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song['image'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Icon(Icons.music_note, color: t.textHint),
              ),
            ),
            title: Text(
              song['title'] ?? 'Unknown',
              style: GoogleFonts.poppins(
                color: t.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            subtitle: Text(
              song['artist'] ?? 'Unknown',
              style: GoogleFonts.poppins(color: t.textSecond),
              maxLines: 1,
            ),
          ),
          Divider(color: t.divider),
          ListTile(
            leading: Icon(Icons.share_outlined, color: t.textPrimary),
            title: Text(
              lang.t("Share Song"),
              style: TextStyle(color: t.textPrimary),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              showShareMenu(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: t.textPrimary),
            title: Text(
              lang.t("Add to Playlist"),
              style: TextStyle(color: t.textPrimary),
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
    // 🌟 ดึงค่า ธีม และ ภาษา ของแอปมาใช้งาน
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: t.bg, // 🌟 พื้นหลังเปลี่ยนตามธีม
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(t, lang),
                    const SizedBox(height: 24),
                    _buildFeaturedBanner(),
                    const SizedBox(height: 24),
                    if (_recentSongs.isNotEmpty) ...[
                      _buildRecentGrid(t),
                      const SizedBox(height: 32),
                    ],
                    _buildArtistsList(t, lang),
                    const SizedBox(height: 32),
                    if (_recommendedSongs.isNotEmpty) ...[
                      _buildHorizontalList(
                        "Made For You",
                        _recommendedSongs,
                        t,
                        lang,
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (_topHitsSongs.isNotEmpty) ...[
                      _buildHorizontalList(
                        "Top Hits Thailand",
                        _topHitsSongs,
                        t,
                        lang,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // UI Components
  // ==========================================================

  Widget _buildTopBar(AppTheme t, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(lang), // 👈 ดึงคำทักทายมาแสดง
                style: GoogleFonts.inter(
                  color: t.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getSubGreeting(lang), // 👈 ดึงคำโปรยมาแสดง
                style: GoogleFonts.inter(
                  color: t.textSecond,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 🌟 PopupMenuButton โทนสีตาม Theme
          PopupMenuButton(
            offset: const Offset(0, 50),
            color: t.surfaceHigh, // 🌟 สีพื้นหลังกล่องเมนู
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lang.t("Notifications"),
                          style: GoogleFonts.inter(
                            color: t.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: t.divider, height: 1),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          color: t.iconMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.t("No notifications"),
                          style: GoogleFonts.inter(
                            color: t.textHint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: t.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_newReleaseSongs.isNotEmpty)
              _playSong(_newReleaseSongs[0], _newReleaseSongs);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NEW ALBUM",
                  style: GoogleFonts.inter(
                    color: AppTheme.accent,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Vibrations 2024",
                  style: AppFont.title(color: Colors.white),
                ), // ในแบนเนอร์ใช้สีขาวเสมอ
                const SizedBox(height: 4),
                Text(
                  "Stream now • Tap to play",
                  style: AppFont.subtitle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsList(AppTheme t, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t("Your Favorite Artists"),
                style: AppFont.title(color: t.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _artists.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArtistDetailScreen(artistData: _artists[index]),
                    ),
                  );
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _artists[index]['image']!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.person,
                              color: t.iconMuted,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _artists[index]['name']!,
                        style: GoogleFonts.inter(
                          color: t.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.t("Artist"),
                        style: GoogleFonts.inter(
                          color: t.textHint,
                          fontSize: 11,
                        ),
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

  Widget _buildRecentGrid(AppTheme t) {
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
            color: t.surface, // 🌟 พื้นหลังการ์ดตามธีม
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _playSong(s, _recentSongs),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
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
                            color: t.surfaceHigh,
                            child: Icon(Icons.music_note, color: t.iconMuted),
                          ),
                        ),
                        if (isPlaying)
                          Container(
                            width: 56,
                            height: 56,
                            color: Colors.black.withOpacity(0.6),
                            child: const Icon(
                              Icons.equalizer,
                              color: AppTheme.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['trackName'],
                      style: GoogleFonts.inter(
                        color: isPlaying ? AppTheme.accent : t.textPrimary,
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

  Widget _buildHorizontalList(
    String title,
    List<dynamic> songs,
    AppTheme t,
    LanguageProvider lang,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.t(title), style: AppFont.title(color: t.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              var s = songs[index];
              var provider = context.watch<MusicProvider>();
              bool isPlaying =
                  provider.currentSong?['id'] == s['trackId'].toString();

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _playSong(s, songs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                                color: t.surface,
                                child: Icon(
                                  Icons.music_note,
                                  color: t.iconMuted,
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
                                  color: AppTheme.accent,
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
                                  style: GoogleFonts.inter(
                                    color: isPlaying
                                        ? AppTheme.accent
                                        : t.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s['artistName'],
                                  style: AppFont.subtitle(color: t.textSecond),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSongOptions(
                              context,
                              {
                                'id': s['trackId'].toString(),
                                'title': s['trackName'],
                                'artist': s['artistName'],
                                'image': s['artworkUrl100'],
                                'previewUrl': s['previewUrl'],
                              },
                              t,
                              lang,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Icon(
                                Icons.more_vert,
                                color: t.textHint,
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
// หน้าจอโปรไฟล์ศิลปิน (Artist Profile Screen)
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

  Future<void> _fetchArtistSongs() async {
    try {
      final originalUrl =
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(widget.artistData['name']!)}&media=music&entity=song&limit=50&country=th';
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

    List<Map<String, dynamic>> playlist = _songs
        .map(
          (s) => {
            'id': s['trackId'].toString(),
            'title': s['trackName'],
            'artist': s['artistName'],
            'image': s['artworkUrl100'],
            'previewUrl': s['previewUrl'],
          },
        )
        .toList();

    int startIndex = playlist.indexWhere(
      (s) => s['id'] == songInfo['trackId'].toString(),
    );
    provider.playPlaylist(playlist, startIndex != -1 ? startIndex : 0);
  }

  void _showSongOptions(
    BuildContext context,
    Map<String, dynamic> song,
    AppTheme t,
    LanguageProvider lang,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: t.surface,
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
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song['image'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Icon(Icons.music_note, color: t.textHint),
              ),
            ),
            title: Text(
              song['title'] ?? 'Unknown',
              style: AppFont.title(color: t.textPrimary),
              maxLines: 1,
            ),
            subtitle: Text(
              song['artist'] ?? 'Unknown',
              style: AppFont.subtitle(color: t.textSecond),
              maxLines: 1,
            ),
          ),
          Divider(color: t.divider),
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: t.textPrimary),
            title: Text(
              lang.t("Add to Playlist"),
              style: AppFont.title(color: t.textPrimary),
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
    // 🌟 ดึงค่า ธีม และ ภาษามาใช้งานในหน้านี้ด้วย
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 350,
                  pinned: true,
                  backgroundColor: t.bg,
                  elevation: 0,
                  iconTheme: IconThemeData(color: t.textPrimary),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
                    title: Text(
                      widget.artistData['name']!,
                      style: AppFont.title(color: t.textPrimary),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.artistData['image']!,
                          fit: BoxFit.cover,
                        ),
                        // 🌟 gradient ให้กลืนไปกับสีพื้นหลังของธีม
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, t.bg],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t("Popular Songs"),
                              style: AppFont.title(color: t.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_songs.length} ${lang.t("tracks")}", // 🌟 แปลคำว่า tracks และต่อด้วยตัวเลข
                              style: AppFont.subtitle(
                                color: t.textSecond,
                                size: 12,
                              ), // 🌟 เปลี่ยน fontSize เป็น size
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_songs.isNotEmpty) _playSong(_songs[0]);
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
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
                          s['trackId'].toString())
                        isPlaying = true;
                    } catch (e) {}

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              s['artworkUrl100'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, err) => Container(
                                width: 50,
                                height: 50,
                                color: t.surface,
                                child: Icon(
                                  Icons.music_note,
                                  color: t.iconMuted,
                                ),
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.black.withOpacity(0.6),
                                child: const Icon(
                                  Icons.equalizer,
                                  color: AppTheme.accent,
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(
                        s['trackName'],
                        style: AppFont.subtitle(
                          color: isPlaying ? AppTheme.accent : t.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        s['artistName'],
                        style: AppFont.subtitle(color: t.textSecond),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert, color: t.textHint),
                        onPressed: () {
                          _showSongOptions(
                            context,
                            {
                              'id': s['trackId'].toString(),
                              'title': s['trackName'],
                              'artist': s['artistName'],
                              'image': s['artworkUrl100'],
                              'previewUrl': s['previewUrl'],
                            },
                            t,
                            lang,
                          );
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
