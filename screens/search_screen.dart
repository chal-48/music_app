import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart';
import 'share_helper.dart';
import 'music_provider.dart';
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

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Top Hits', 'query': 'top hits', 'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80'},
    {'title': 'Thai Pop', 'query': 'thai pop', 'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80'},
    {'title': 'Luk Thung', 'query': 'มนต์แคน', 'image': 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=500&q=80'},
    {'title': 'K-Pop', 'query': 'korean pop', 'image': 'https://images.unsplash.com/photo-1611002214172-792c1f90b59a?w=500&q=80'},
    {'title': 'Global Hits', 'query': 'billboard hot 100', 'image': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=500&q=80'},
    {'title': 'Rock', 'query': 'rock music', 'image': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=500&q=80'},
    {'title': 'Indie', 'query': 'indie pop', 'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80'},
    {'title': 'Acoustic Chill', 'query': 'acoustic chill', 'image': 'https://images.unsplash.com/photo-1460723237483-7a6dc9d0b212?w=500&q=80'},
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
      final originalUrl = 'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=50&country=th';
      final proxyUrl = 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';
      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 15));
      
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
          if (titleA == q || artistA == q) scoreA = 3;
          else if (titleA.startsWith(q) || artistA.startsWith(q)) scoreA = 2;
          else if (titleA.contains(q) || artistA.contains(q)) scoreA = 1;
          if (titleB == q || artistB == q) scoreB = 3;
          else if (titleB.startsWith(q) || artistB.startsWith(q)) scoreB = 2;
          else if (titleB.contains(q) || artistB.contains(q)) scoreB = 1;
          return scoreB.compareTo(scoreA);
        });
        
        if (mounted) setState(() { _searchResults = fetchedResults; _isSearching = false; });
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();
    bool isShowingCategories = _searchController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                lang.t("Search"),
                style: GoogleFonts.inter(color: t.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: t.textPrimary),
                decoration: InputDecoration(
                  hintText: lang.t("Artists, songs, or podcasts..."),
                  hintStyle: GoogleFonts.inter(color: t.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accent),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty && !_isSearching)
                        IconButton(
                          icon: Icon(Icons.clear_rounded, color: t.iconMuted),
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
                  fillColor: t.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: isShowingCategories ? _buildCategoriesGrid(t, lang) : _buildSearchResults(t, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(AppTheme t, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lang.t("Browse Categories"), style: GoogleFonts.inter(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${_categories.length} ${lang.t("genres")}", style: GoogleFonts.inter(color: t.textHint, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              var cat = _categories[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailScreen(categoryData: cat))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(cat['image'], fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: t.surfaceHigh)),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.75)]))),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            lang.t(cat['title']), // 🌟 แปลภาษาและจัดกึ่งกลาง
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2))]),
                            textAlign: TextAlign.center,
                          ),
                        ),
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

  Widget _buildSearchResults(AppTheme t, LanguageProvider lang) {
    if (_searchResults.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: t.iconMuted, size: 48),
            const SizedBox(height: 12),
            Text(lang.t("No results found"), style: GoogleFonts.inter(color: t.textHint, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var s = _searchResults[index];
        var provider = context.watch<MusicProvider>();
        bool isPlaying = false;
        try { if (provider.currentSong?['id'] == s['trackId'].toString()) isPlaying = true; } catch (e) {}
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(s['artworkUrl100'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, err) => Container(width: 50, height: 50, color: t.surfaceHigh, child: Icon(Icons.music_note, color: t.iconMuted))),
                if (isPlaying) Container(width: 50, height: 50, color: Colors.black.withOpacity(0.6), child: const Icon(Icons.equalizer, color: AppTheme.accent)),
              ],
            ),
          ),
          title: Text(s['trackName'], style: GoogleFonts.inter(color: isPlaying ? AppTheme.accent : t.textPrimary, fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(s['artistName'], style: GoogleFonts.inter(color: t.textSecond, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(icon: Icon(Icons.more_vert, color: t.iconMuted), onPressed: () => _showSongOptions(context, {'id': s['trackId'].toString(), 'title': s['trackName'], 'artist': s['artistName'], 'image': s['artworkUrl100'], 'previewUrl': s['previewUrl']}, t, lang)),
          onTap: () => Provider.of<MusicProvider>(context, listen: false).playSong({'id': s['trackId'].toString(), 'title': s['trackName'], 'artist': s['artistName'], 'image': s['artworkUrl100'], 'previewUrl': s['previewUrl']}),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, Map<String, dynamic> song, AppTheme t, LanguageProvider lang) {
    showModalBottomSheet(
      context: context, useRootNavigator: true, backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(song['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.music_note, color: t.iconMuted))),
            title: Text(song['title'] ?? 'Unknown', style: GoogleFonts.inter(color: t.textPrimary, fontWeight: FontWeight.bold), maxLines: 1),
            subtitle: Text(song['artist'] ?? 'Unknown', style: GoogleFonts.inter(color: t.textSecond), maxLines: 1),
          ),
          Divider(color: t.divider),
          ListTile(
            leading: Icon(Icons.share_outlined, color: t.textPrimary),
            title: Text(lang.t("Share Song"), style: GoogleFonts.inter(color: t.textPrimary)),
            onTap: () { Navigator.pop(sheetContext); showShareMenu(context, song); },
          ),
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: t.textPrimary),
            title: Text(lang.t("Add to Playlist"), style: GoogleFonts.inter(color: t.textPrimary)),
            onTap: () {
              Navigator.pop(sheetContext);
              showModalBottomSheet(context: context, useRootNavigator: true, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AddToPlaylistSheet(song: song));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// Category Detail Screen
// ============================================================================
class CategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> categoryData;
  const CategoryDetailScreen({super.key, required this.categoryData});
  @override State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override void initState() { super.initState(); _fetchCategorySongs(); }

  Future<void> _fetchCategorySongs() async {
    try {
      final originalUrl = 'https://itunes.apple.com/search?term=${Uri.encodeComponent(widget.categoryData['query'])}&media=music&entity=song&limit=50&country=th';
      final proxyUrl = 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}';
      final response = await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && mounted) setState(() { _songs = json.decode(utf8.decode(response.bodyBytes))['results']; _isLoading = false; });
      else if (mounted) setState(() => _isLoading = false);
    } catch (e) { if (mounted) setState(() => _isLoading = false); }
  }

  void _playSong(Map<String, dynamic> songInfo) {
    Provider.of<MusicProvider>(context, listen: false).playSong({
      'id': songInfo['trackId'].toString(), 'title': songInfo['trackName'], 'artist': songInfo['artistName'], 'image': songInfo['artworkUrl100'], 'previewUrl': songInfo['previewUrl'],
    });
  }

  @override Widget build(BuildContext context) {
    final t = AppTheme(isDark: context.watch<ThemeProvider>().isDarkMode);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accent)) : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280, pinned: true, backgroundColor: t.bg, elevation: 0, iconTheme: IconThemeData(color: t.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: Text(lang.t(widget.categoryData['title']), style: GoogleFonts.inter(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(widget.categoryData['image'], fit: BoxFit.cover),
                  DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, t.bg], stops: const [0.4, 1.0]))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.t(widget.categoryData['title']), style: GoogleFonts.inter(color: t.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${_songs.length} ${lang.t("tracks")}", style: GoogleFonts.inter(color: t.textSecond, fontSize: 13)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () { if (_songs.isNotEmpty) _playSong(_songs[0]); },
                    child: Container(width: 56, height: 56, decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4))]), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32)),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              var s = _songs[index];
              bool isPlaying = false;
              try { if (context.watch<MusicProvider>().currentSong?['id'] == s['trackId'].toString()) isPlaying = true; } catch (e) {}
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(s['artworkUrl100'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, err) => Container(width: 50, height: 50, color: t.surfaceHigh, child: Icon(Icons.music_note, color: t.iconMuted))),
                      if (isPlaying) Container(width: 50, height: 50, color: Colors.black.withOpacity(0.6), child: const Icon(Icons.equalizer, color: AppTheme.accent)),
                    ],
                  ),
                ),
                title: Text(s['trackName'], style: GoogleFonts.inter(color: isPlaying ? AppTheme.accent : t.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(s['artistName'], style: GoogleFonts.inter(color: t.textSecond, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(icon: Icon(Icons.more_vert, color: t.iconMuted), onPressed: () => _showSongOptions(context, {'id': s['trackId'].toString(), 'title': s['trackName'], 'artist': s['artistName'], 'image': s['artworkUrl100'], 'previewUrl': s['previewUrl']}, t, lang)),
                onTap: () => _playSong(s),
              );
            }, childCount: _songs.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, Map<String, dynamic> song, AppTheme t, LanguageProvider lang) {
    showModalBottomSheet(
      context: context, useRootNavigator: true, backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(song['image'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.music_note, color: t.iconMuted))),
            title: Text(song['title'] ?? 'Unknown', style: GoogleFonts.inter(color: t.textPrimary, fontWeight: FontWeight.bold), maxLines: 1),
            subtitle: Text(song['artist'] ?? 'Unknown', style: GoogleFonts.inter(color: t.textSecond), maxLines: 1),
          ),
          Divider(color: t.divider),
          ListTile(
            leading: Icon(Icons.share_outlined, color: t.textPrimary),
            title: Text(lang.t("Share Song"), style: GoogleFonts.inter(color: t.textPrimary)),
            onTap: () { Navigator.pop(sheetContext); showShareMenu(context, song); },
          ),
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: t.textPrimary),
            title: Text(lang.t("Add to Playlist"), style: GoogleFonts.inter(color: t.textPrimary)),
            onTap: () {
              Navigator.pop(sheetContext);
              showModalBottomSheet(context: context, useRootNavigator: true, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => AddToPlaylistSheet(song: song));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}