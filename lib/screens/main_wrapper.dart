import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'music_provider.dart';
import 'package:music_app/screens/home_screen.dart';
import 'package:music_app/screens/search_screen.dart';
import 'package:music_app/screens/library_screen.dart';
import 'package:music_app/screens/profile_screen.dart';
import 'package:music_app/screens/full_player_screen.dart';
import 'search_screen.dart'; // 🌟 นำเข้าหน้า Search
// (คุณน่าจะมี import หน้า Home หรือ Library อยู่แถวๆ นี้ด้วย)
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // 🌟 1. สร้างกุญแจ (GlobalKey) 4 ดอก สำหรับ 4 แท็บ 
  // เพื่อให้แต่ละแท็บมีหน่วยความจำหน้าจอของตัวเอง
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // 🌟 2. เปลี่ยนจากการเรียกหน้าตรงๆ เป็นฟังก์ชันสร้าง TabNavigator
  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => rootPage);
      },
    );
  }

  // 🌟 3. ฟังก์ชันสลับแท็บ ที่ฉลาดขึ้น
  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // ถ้ากดแท็บเดิมซ้ำ ให้เด้งกลับไปหน้าแรกสุดของแท็บนั้น
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      // 🌟 เพิ่มบรรทัดนี้: สั่งให้แท็บที่กำลังจะ "ออก" ย้อนกลับไปหน้าแรกสุด (ล้างสถานะที่ค้างไว้)
      _navigatorKeys[_selectedIndex].currentState?.popUntil((route) => route.isFirst);

      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFF5500); 

    // 🌟 4. ใช้ PopScope ครอบไว้ เพื่อให้ปุ่ม Back ของมือถือ(Android) ย้อนกลับในแท็บก่อนปิดแอป
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            _onItemTapped(0); // เด้งกลับหน้า Home ก่อน
          } else {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop(); // ออกจากแอป
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true, 
        body: Stack(
          children: [
            // --- 🌟 พื้นที่แสดงผลของแต่ละแท็บ (ไม่ทับ Bottom Bar แล้ว!) ---
            IndexedStack(
              index: _selectedIndex,
              children: [
                _buildTabNavigator(0, const HomeScreen()),
                _buildTabNavigator(1, const SearchScreen()),
                _buildTabNavigator(2, const LibraryPage()),
                _buildTabNavigator(3, const ProfilePage()),
              ],
            ),

            

            // --- Mini Player (ลอยทับทุกหน้าจอ) ---
            if (_selectedIndex != 3)
            // --- Mini Player (ลอยทับทุกหน้าจอ) ---
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Consumer<MusicProvider>(
                builder: (context, provider, child) {
                  if (provider.currentSong == null || _selectedIndex == 3) {
                    return const SizedBox.shrink();
                  }
                  
                  var song = provider.currentSong!;
                  
                  // 🌟 ไฮไลท์การแก้: เช็คทั้ง 2 แบบ (ของ iTunes และ ของ Firestore)
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
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Hero( 
                                  tag: 'album_art_${song['trackId'] ?? song['id']}', // 🌟 ดักเผื่อ id ด้วย
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                                    clipBehavior: Clip.hardEdge,
                                    // 🌟 ใช้ตัวแปร displayImage ที่ดักไว้แล้ว
                                    child: Image.network(displayImage, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(width:50, height:50, color:Colors.grey[800], child: const Icon(Icons.music_note, color: Colors.white54))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 🌟 ใช้ตัวแปร displayTitle และ displayArtist ที่ดักไว้แล้ว
                                      Text(displayTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(displayArtist, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w300, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow_rounded, color: accentColor, size: 30),
                                  onPressed: () => provider.togglePlay(),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0,
                            child: Container(
                              height: 2,
                              width: provider.duration.inSeconds > 0 
                                  ? (provider.position.inSeconds / provider.duration.inSeconds) * (MediaQuery.of(context).size.width - 32)
                                  : 0,
                              color: accentColor,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Glassmorphism Navigation Bar ---
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 80,
                    color: Colors.black.withOpacity(0.6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home_rounded, 0),
                        _buildNavItem(Icons.search_rounded, 1),
                        _buildNavItem(Icons.library_music_rounded, 2),
                        _buildNavItem(Icons.person_rounded, 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index), // 🌟 เรียกใช้ฟังก์ชันที่ฉลาดขึ้น
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected 
          ? BoxDecoration(color: const Color(0xFFFF5500).withOpacity(0.2), shape: BoxShape.circle)
          : null,
        child: Icon(icon, color: isSelected ? const Color(0xFFFF5500) : Colors.grey[600], size: 28),
      ),
    );
  }
}