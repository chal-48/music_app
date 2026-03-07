import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'music_provider.dart'; 
import 'add_to_playlist_sheet.dart'; 
import 'share_helper.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  // 🌟 1. สร้างฟังก์ชันโชว์เมนูจุดไข่ปลา (เด้งจากด้านล่าง)
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;
    const Color accentColor = Color(0xFFFF5500);

    if (song == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text("กำลังเล่น", style: TextStyle(color: Colors.white, fontSize: 14)),
        centerTitle: true,
        actions: [
          // 🌟 2. แก้ไขปุ่ม 3 จุดให้เรียกใช้ฟังก์ชัน _showSongOptions
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white), 
            onPressed: () => showShareMenu(context), // ตรงนี้แหละที่เคยเป็นค่าว่าง!
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Hero(
              tag: 'album_art_${song['trackId']}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song['image'] ?? song['artworkUrl100'] ?? '',
                  width: MediaQuery.of(context).size.width - 48,
                  height: MediaQuery.of(context).size.width - 48,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(color: Colors.grey[900], child: const Icon(Icons.music_note, color: Colors.white54, size: 100)),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song['title'] ?? song['trackName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(song['artist'] ?? song['artistName'] ?? 'Unknown', style: TextStyle(color: Colors.grey[400], fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true, 
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddToPlaylistSheet(song: song), 
                    );
                  },
                ),
              ],
            ),
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: Colors.grey[800],
                    thumbColor: accentColor,
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  ),
                  child: Slider(
                    value: provider.position.inSeconds.toDouble(),
                    max: provider.duration.inSeconds.toDouble() > 0 ? provider.duration.inSeconds.toDouble() : 1.0,
                    onChanged: (value) => provider.seek(Duration(seconds: value.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(provider.position), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      Text(_formatDuration(provider.duration), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            // 🌟 4. ปุ่มควมคุมเพลงที่เชื่อมต่อระบบเรียบร้อยแล้ว
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // สุ่มเพลง (Shuffle)
                IconButton(
                  icon: Icon(Icons.shuffle, color: provider.isShuffle ? accentColor : Colors.white54, size: 28), 
                  onPressed: () => provider.toggleShuffle(),
                ),
                
                // ก่อนหน้า (Previous)
                IconButton(
                  icon: Icon(Icons.skip_previous, color: (provider.hasPrevious || provider.isShuffle || provider.position.inSeconds > 3) ? Colors.white : Colors.white54, size: 40), 
                  onPressed: () => provider.playPrevious(),
                ),
                
                // เล่น/หยุด (Play/Pause)
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
                    onPressed: () => provider.togglePlay(),
                  ),
                ),
                
                // ถัดไป (Next)
                IconButton(
                  icon: Icon(Icons.skip_next, color: (provider.hasNext || provider.isShuffle) ? Colors.white : Colors.white54, size: 40), 
                  onPressed: () => provider.playNext(),
                ),
                
                // เล่นซ้ำ (Repeat)
                IconButton(
                  icon: Icon(Icons.repeat, color: provider.isRepeat ? accentColor : Colors.white54, size: 28), 
                  onPressed: () => provider.toggleRepeat(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}