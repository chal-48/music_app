import 'package:flutter/material.dart';
import 'package:music_app/screens/add_to_playlist_sheet.dart';
import 'package:music_app/screens/share_helper.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

import 'app_theme.dart';
import 'profile_screen.dart'; // ดึง ThemeProvider และ LanguageProvider

import 'music_provider.dart';
import 'add_to_playlist_sheet.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var song = context.select<MusicProvider, Map<String, dynamic>?>((p) => p.currentSong);

    // 🌟 ดึงค่า ธีม และ ภาษา
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    if (song == null) return const SizedBox.shrink();

    String title = song['trackName'] ?? song['title'] ?? 'Unknown Title';
    String artist = song['artistName'] ?? song['artist'] ?? 'Unknown Artist';
    String rawImage = song['artworkUrl100'] ?? song['image'] ?? '';
    String highResImage = rawImage.replaceAll('100x100bb', '600x600bb');

    return Scaffold(
      backgroundColor: t.bg, // 🌟 สีพื้นหลังตามธีม
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down, color: t.textPrimary, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang.t("Now Playing"), // 🌟 ใช้ระบบแปลภาษา
          style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.more_vert, color: t.textPrimary), onPressed: () {
            showShareMenu(context, song); // 🌟 ส่งเพลงไปให้ Share Menu ด้วย
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
                    width: size.width - 100,
                    height: size.width - 100,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: AppTheme.accentGlow, blurRadius: 50, spreadRadius: 5, offset: const Offset(0, 30))
                      ],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Hero(
                    tag: 'album_art_${song['trackId'] ?? song['id']}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        highResImage,
                        width: size.width - 60,
                        height: size.width - 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: size.width - 60, height: size.width - 60,
                          color: t.surfaceHigh,
                          child: Icon(Icons.music_note, color: t.iconMuted, size: 100),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.only(left: 30, right: 14), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextScroll(
                          "$title               ",
                          mode: TextScrollMode.endless,
                          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                          delayBefore: const Duration(seconds: 2),
                          pauseBetween: const Duration(seconds: 2),
                          style: TextStyle(color: t.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          style: TextStyle(color: t.textSecond, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: t.textPrimary, size: 32),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true, 
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (context) => AddToPlaylistSheet(song: song!), 
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Consumer<MusicProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: AppTheme.accent,
                          inactiveTrackColor: t.border, // 🌟 สี Track ที่ยังไม่เล่น
                          thumbColor: t.textPrimary, // 🌟 สีปุ่มเลื่อน
                        ),
                        child: Slider(
                          value: provider.duration.inSeconds > 0 
                              ? provider.position.inSeconds.toDouble() 
                              : 0.0,
                          min: 0.0,
                          max: provider.duration.inSeconds > 0 
                              ? provider.duration.inSeconds.toDouble() 
                              : 1.0,
                          onChanged: (value) {
                            provider.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatTime(provider.position), style: TextStyle(color: t.textSecond, fontSize: 12)),
                          Text(formatTime(provider.duration), style: TextStyle(color: t.textSecond, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.shuffle, color: provider.isShuffle ? AppTheme.accent : t.textSecond, size: 26),
                            onPressed: () => provider.toggleShuffle(),
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_previous, color: provider.hasPrevious ? t.textPrimary : t.iconMuted, size: 36),
                            onPressed: provider.hasPrevious ? () => provider.playPrevious() : null,
                          ),
                          GestureDetector(
                            onTap: () => provider.togglePlay(),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent),
                              child: Center(
                                child: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 38), // ปุ่ม Play สีขาวเสมอจะสวยกว่า
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next, color: provider.hasNext ? t.textPrimary : t.iconMuted, size: 36),
                            onPressed: provider.hasNext ? () => provider.playNext() : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.repeat, color: provider.isRepeat ? AppTheme.accent : t.textSecond, size: 26),
                            onPressed: () => provider.toggleRepeat(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}