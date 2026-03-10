import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart'; // ดึง ThemeProvider และ LanguageProvider

import 'music_provider.dart';
import 'package:music_app/screens/home_screen.dart';
import 'package:music_app/screens/search_screen.dart';
import 'package:music_app/screens/library_screen.dart';
import 'package:music_app/screens/full_player_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => rootPage);
      },
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      _navigatorKeys[_selectedIndex].currentState?.popUntil((route) => route.isFirst);
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 ดึงค่า ธีม และ ภาษา
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            _onItemTapped(0); 
          } else {
            Navigator.of(context).pop(); 
          }
        }
      },
      child: Scaffold(
        backgroundColor: t.bg, // 🌟 สีพื้นหลังตามธีม
        extendBody: false, 
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildTabNavigator(0, const HomeScreen()),
            _buildTabNavigator(1, const SearchScreen()),
            _buildTabNavigator(2, const LibraryPage()),
            _buildTabNavigator(3, const ProfilePage()),
          ],
        ),

        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            // ==========================================
            // 🎵 1. ส่วนของ Mini Player
            // ==========================================
            if (_selectedIndex != 3) 
              Consumer<MusicProvider>(
                builder: (context, provider, child) {
                  if (provider.currentSong == null) {
                    return const SizedBox.shrink();
                  }
                  
                  var song = provider.currentSong!;
                  String displayTitle = song['trackName'] ?? song['title'] ?? 'Unknown';
                  String displayArtist = song['artistName'] ?? song['artist'] ?? 'Unknown';
                  String displayImage = song['artworkUrl100'] ?? song['image'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FullPlayerScreen(),
                      );
                    },
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < 0) {
                        provider.playNext(); 
                      } else if (details.primaryVelocity! > 0) {
                        provider.playPrevious(); 
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 64, 
                      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4), 
                      decoration: BoxDecoration(
                        color: t.surfaceHigh, // 🌟 สีพื้นหลัง Mini Player ตามธีม
                        borderRadius: BorderRadius.circular(10), 
                        boxShadow: [
                          if (provider.isPlaying) 
                            BoxShadow(color: AppTheme.accentGlow, blurRadius: 15, spreadRadius: 1)
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                AnimatedScale(
                                  scale: provider.isPlaying ? 1.0 : 0.85,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  child: Hero( 
                                    tag: 'album_art_${song['trackId'] ?? song['id']}', 
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(displayImage, width: 46, height: 46, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(width:46, height:46, color:t.surface, child: Icon(Icons.music_note, color: t.iconMuted))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(displayTitle, style: TextStyle(color: provider.isPlaying ? AppTheme.accent : t.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(displayArtist, style: TextStyle(color: t.textSecond, fontWeight: FontWeight.w400, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.skip_previous_rounded, color: t.textSecond, size: 28),
                                  onPressed: () => provider.playPrevious(),
                                ),
                                const SizedBox(width: 4),
                                
                                IconButton(
                                  onPressed: () => provider.togglePlay(),
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                    child: Icon(
                                      provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                                      key: ValueKey<bool>(provider.isPlaying),
                                      color: t.textPrimary, // 🌟 สีไอคอนตามธีม
                                      size: 34,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.skip_next_rounded, color: t.textSecond, size: 28),
                                  onPressed: () => provider.playNext(),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              height: 2,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(color: t.border),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 900), 
                                curve: Curves.linear,
                                height: 2,
                                width: provider.duration.inSeconds > 0 
                                    ? (provider.position.inSeconds / provider.duration.inSeconds) * (MediaQuery.of(context).size.width - 16)
                                    : 0,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accent, 
                                  borderRadius: BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2))
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),

            // ==========================================
            // 📱 2. ส่วนของ Bottom Navigation Bar 
            // ==========================================
            Container(
              height: 75, 
              decoration: BoxDecoration(
                color: t.bg, // 🌟 สีพื้นหลัง Bottom Bar ตามธีม
                border: Border(top: BorderSide(color: t.border, width: 0.5)), 
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0, lang.t("Home"), t),
                  _buildNavItem(Icons.search_rounded, Icons.search_outlined, 1, lang.t("Search"), t),
                  _buildNavItem(Icons.library_music_rounded, Icons.library_music_outlined, 2, lang.t("Library"), t),
                  _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 3, lang.t("Profile"), t),
                ],
              ),
            ),
            
            Container(
              color: t.bg,
              height: MediaQuery.of(context).padding.bottom, 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index, String label, AppTheme t) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque, 
      child: SizedBox(
        width: 70, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(isSelected ? 6 : 0),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon, 
                color: isSelected ? AppTheme.accent : t.iconMuted, // 🌟 สีไอคอนตามธีม
                size: isSelected ? 26 : 26
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: 4, 
              width: isSelected ? 18 : 0, 
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          ],
        ),
      ),
    );
  }
}