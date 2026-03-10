import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:music_app/screens/auth_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'share_helper.dart';
import 'app_theme.dart';

// ============================================================================
// ThemeProvider
// ============================================================================
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

// ============================================================================
// 🌟 LanguageProvider (ระบบแปลภาษาจัดเต็ม)
// ============================================================================
class LanguageProvider extends ChangeNotifier {
  String _lang = 'en';
  String get lang => _lang;

  LanguageProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _lang = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
    notifyListeners();
  }

  // 🌟 พจนานุกรมคำแปล (ครอบคลุมทั้งแอป)
  String t(String text) {
    final Map<String, Map<String, String>> dictionary = {
      // Profile
      'Profile': {'en': 'Profile', 'th': 'โปรไฟล์', 'ja': 'プロフィール'},
      'Manage your account': {
        'en': 'Manage your account',
        'th': 'จัดการบัญชีของคุณ',
        'ja': 'アカウント管理',
      },
      'Edit Profile': {
        'en': 'Edit Profile',
        'th': 'แก้ไขโปรไฟล์',
        'ja': 'プロフィール編集',
      },
      'Playlists': {'en': 'Playlists', 'th': 'เพลย์ลิสต์', 'ja': 'プレイリスト'},
      'Followers': {'en': 'Followers', 'th': 'ผู้ติดตาม', 'ja': 'フォロワー'},
      'Following': {'en': 'Following', 'th': 'กำลังติดตาม', 'ja': 'フォロー中'},
      'Appearance': {'en': 'Appearance', 'th': 'การแสดงผล', 'ja': '外観'},
      'Theme': {'en': 'Theme', 'th': 'ธีม', 'ja': 'テーマ'},
      'Dark mode': {'en': 'Dark mode', 'th': 'โหมดมืด', 'ja': 'ダークモード'},
      'Light mode': {'en': 'Light mode', 'th': 'โหมดสว่าง', 'ja': 'ライトモード'},
      'Language': {'en': 'Language', 'th': 'ภาษา', 'ja': '言語'},
      'Data & Storage': {
        'en': 'Data & Storage',
        'th': 'ข้อมูล & พื้นที่จัดเก็บ',
        'ja': 'データとストレージ',
      },
      'Data Saver': {
        'en': 'Data Saver',
        'th': 'ประหยัดอินเทอร์เน็ต',
        'ja': 'データセーバー',
      },
      'Lower quality on cellular data': {
        'en': 'Lower quality on cellular data',
        'th': 'ลดคุณภาพเมื่อใช้เน็ตมือถือ',
        'ja': 'モバイル通信時の音質を下げる',
      },
      'Clear Cache': {'en': 'Clear Cache', 'th': 'ล้างแคช', 'ja': 'キャッシュを消去'},
      'Free up storage space': {
        'en': 'Free up storage space',
        'th': 'เพิ่มพื้นที่ว่าง',
        'ja': '空き容量を増やす',
      },
      'Notifications': {
        'en': 'Notifications',
        'th': 'การแจ้งเตือน',
        'ja': '通知',
      },
      'Push Notifications': {
        'en': 'Push Notifications',
        'th': 'การแจ้งเตือนแบบพุช',
        'ja': 'プッシュ通知',
      },
      'New releases & recommendations': {
        'en': 'New releases & recommendations',
        'th': 'เพลงใหม่ & สิ่งที่แนะนำ',
        'ja': '新曲とおすすめ',
      },
      'About': {'en': 'About', 'th': 'เกี่ยวกับ', 'ja': 'について'},
      'Privacy Policy': {
        'en': 'Privacy Policy',
        'th': 'นโยบายความเป็นส่วนตัว',
        'ja': 'プライバシーポリシー',
      },
      'Help & Support': {
        'en': 'Help & Support',
        'th': 'ช่วยเหลือ & สนับสนุน',
        'ja': 'ヘルプとサポート',
      },
      'Version': {'en': 'Version', 'th': 'เวอร์ชัน', 'ja': 'バージョン'},
      'Log out': {'en': 'Log out', 'th': 'ออกจากระบบ', 'ja': 'ログアウト'},

      // Library
      'Your Library': {
        'en': 'Your Library',
        'th': 'คลังเพลงของคุณ',
        'ja': 'マイライブラリ',
      },
      'All your playlists in one place 🎶': {
        'en': 'All your playlists in one place 🎶',
        'th': 'รวมทุกเพลย์ลิสต์ไว้ที่เดียว 🎶',
        'ja': 'すべてのプレイリストを1か所に 🎶',
      },
      'Liked Songs': {
        'en': 'Liked Songs',
        'th': 'เพลงที่ถูกใจ',
        'ja': 'お気に入りの曲',
      },
      'Your favorite tracks': {
        'en': 'Your favorite tracks',
        'th': 'แทร็กโปรดของคุณ',
        'ja': 'お気に入りのトラック',
      },
      'No playlists yet': {
        'en': 'No playlists yet',
        'th': 'ยังไม่มีเพลย์ลิสต์',
        'ja': 'プレイリストがありません',
      },
      'Tap + to create your first playlist': {
        'en': 'Tap + to create your first playlist',
        'th': 'แตะ + เพื่อสร้างเพลย์ลิสต์แรกของคุณ',
        'ja': '+ をタップして最初のプレイリストを作成',
      },

      // Search
      'Search': {'en': 'Search', 'th': 'ค้นหา', 'ja': '検索'},
      'Find your next favorite song 🎵': {
        'en': 'Find your next favorite song 🎵',
        'th': 'ค้นหาเพลงโปรดเพลงถัดไปของคุณ 🎵',
        'ja': '次のお気に入りの曲を見つける 🎵',
      },
      'Artists, songs, or podcasts...': {
        'en': 'Artists, songs, or podcasts...',
        'th': 'ศิลปิน เพลง หรือพอดแคสต์...',
        'ja': 'アーティスト、曲、ポッドキャスト...',
      },
      'Browse Categories': {
        'en': 'Browse Categories',
        'th': 'เลือกดูตามหมวดหมู่',
        'ja': 'カテゴリーを見る',
      },
      'genres': {'en': 'genres', 'th': 'แนวเพลง', 'ja': 'ジャンル'},
      'No results found': {
        'en': 'No results found',
        'th': 'ไม่พบผลลัพธ์',
        'ja': '結果が見つかりません',
      },

      //Edit Profile
      'Display Name': {'en': 'Display Name', 'th': 'ชื่อที่แสดง', 'ja': '表示名'},
      'New Password': {
        'en': 'New Password',
        'th': 'รหัสผ่านใหม่',
        'ja': '新しいパスワード',
      },
      'Leave blank to keep current': {
        'en': 'Leave blank to keep current',
        'th': 'เว้นว่างไว้หากไม่ต้องการเปลี่ยน',
        'ja': '変更しない場合は空白のままにしてください',
      },
      'Save': {'en': 'Save', 'th': 'บันทึก', 'ja': '保存'},

      //Main Wrapper & Player
      'Now Playing': {'en': 'Now Playing', 'th': 'กำลังเล่น', 'ja': '再生中'},
      'Save to': {'en': 'Save to', 'th': 'บันทึกใน', 'ja': '保存先'},
      'New Playlist': {
        'en': 'New Playlist',
        'th': 'เพลย์ลิสต์ใหม่',
        'ja': '新しいプレイリスト',
      },
      'Playlist name...': {
        'en': 'Playlist name...',
        'th': 'ตั้งชื่อเพลย์ลิสต์...',
        'ja': 'プレイリスト名...',
      },
      'Cancel': {'en': 'Cancel', 'th': 'ยกเลิก', 'ja': 'キャンセル'},
      'Create': {'en': 'Create', 'th': 'สร้าง', 'ja': '作成'},
      'Liked Songs': {
        'en': 'Liked Songs',
        'th': 'เพลงที่ถูกใจ',
        'ja': 'お気に入りの曲',
      },
      'Empty': {'en': 'Empty', 'th': 'ว่างเปล่า', 'ja': '空'},
      'tracks': {'en': 'tracks', 'th': 'แทร็ก', 'ja': '曲'},
      'Share': {'en': 'Share', 'th': 'แชร์', 'ja': '共有'},
      'Share song': {'en': 'Share song', 'th': 'แชร์เพลง', 'ja': '曲を共有'},
      'Copy Link': {'en': 'Copy Link', 'th': 'คัดลอกลิงก์', 'ja': 'リンクをコピー'},
      'Download system coming soon': {
        'en': 'Download system coming soon',
        'th': 'ระบบดาวน์โหลดกำลังจะมาเร็วๆ นี้',
        'ja': 'ダウンロードシステムは間もなく登場します',
      },
      'Home': {'en': 'Home', 'th': 'หน้าแรก', 'ja': 'ホーム'},
      'Library': {'en': 'Library', 'th': 'คลังเพลง', 'ja': 'ライブラリ'},

      //Create/Edit Playlist
      'Create Playlist': {
        'en': 'Create Playlist',
        'th': 'สร้างเพลย์ลิสต์',
        'ja': 'プレイリストを作成',
      },
      'Edit Playlist': {
        'en': 'Edit Playlist',
        'th': 'แก้ไขเพลย์ลิสต์',
        'ja': 'プレイリストを編集',
      },
      'Playlist Name': {
        'en': 'Playlist Name',
        'th': 'ชื่อเพลย์ลิสต์',
        'ja': 'プレイリスト名',
      },
      'Public': {'en': 'Public', 'th': 'สาธารณะ', 'ja': '公開'},
      'Add Cover': {'en': 'Add Cover', 'th': 'เพิ่มปก', 'ja': 'カバーを追加'},
      'Change Cover': {'en': 'Change Cover', 'th': 'เปลี่ยนปก', 'ja': 'カバーを変更'},
      'Cancel': {'en': 'Cancel', 'th': 'ยกเลิก', 'ja': 'キャンセル'},
      'Create': {'en': 'Create', 'th': 'สร้าง', 'ja': '作成'},
      'Save': {'en': 'Save', 'th': 'บันทึก', 'ja': '保存'},
      'Sort': {'en': 'Sort', 'th': 'จัดเรียง', 'ja': '並べ替え'},
      'Sort A-Z': {'en': 'Sort A-Z', 'th': 'เรียง A-Z', 'ja': 'A-Z順'},
      'Sort Z-A': {'en': 'Sort Z-A', 'th': 'เรียง Z-A', 'ja': 'Z-A順'},
      'Add': {'en': 'Add', 'th': 'เพิ่ม', 'ja': '追加'},
      'Edit': {'en': 'Edit', 'th': 'แก้ไข', 'ja': '編集'},
      "Let's find some songs": {
        'en': "Let's find some songs",
        'th': 'มาค้นหาเพลงกัน',
        'ja': '曲を探しましょう',
      },
      'Share Playlist': {
        'en': 'Share Playlist',
        'th': 'แชร์เพลย์ลิสต์',
        'ja': 'プレイリストを共有',
      },
      'Delete Playlist': {
        'en': 'Delete Playlist',
        'th': 'ลบเพลย์ลิสต์',
        'ja': 'プレイリストを削除',
      },
      'Remove from Playlist': {
        'en': 'Remove from Playlist',
        'th': 'ลบออกจากเพลย์ลิสต์',
        'ja': 'プレイリストから削除',
      },

      // หมวดหมู่เพลง (Categories)
      'Top Hits': {'en': 'Top Hits', 'th': 'ฮิตติดชาร์ต', 'ja': 'トップヒット'},
      'Thai Pop': {'en': 'Thai Pop', 'th': 'ไทยป็อป', 'ja': 'タイポップ'},
      'Luk Thung': {'en': 'Luk Thung', 'th': 'ลูกทุ่ง', 'ja': 'ルクトゥン (タイ演歌)'},
      'K-Pop': {'en': 'K-Pop', 'th': 'เคป็อป', 'ja': 'K-POP'},
      'Global Hits': {
        'en': 'Global Hits',
        'th': 'ฮิตระดับโลก',
        'ja': 'グローバルヒット',
      },
      'Rock': {'en': 'Rock', 'th': 'ร็อก', 'ja': 'ロック'},
      'Indie': {'en': 'Indie', 'th': 'อินดี้', 'ja': 'インディー'},
      'Acoustic Chill': {
        'en': 'Acoustic Chill',
        'th': 'อะคูสติกชิลล์',
        'ja': 'アコースティックチル',
      },

      // สำหรับช่องค้นหาในหน้า Search
      'Artists, songs, or podcasts...': {
        'en': 'Artists, songs, or podcasts...',
        'th': 'ศิลปิน เพลง หรือพอดแคสต์...',
        'ja': 'アーティスト、曲、ポッドキャスト...',
      },

      // สำหรับช่องค้นหาเวลาจะเพิ่มเพลงเข้าเพลย์ลิสต์
      'Type song or artist...': {
        'en': 'Type song or artist...',
        'th': 'พิมพ์ชื่อเพลง หรือ ศิลปิน...',
        'ja': '曲名やアーティストを入力...',
      },

      // ==========================================
      // หมวดหน้า Home (หน้าแรก)
      // ==========================================
      // คำทักทาย
      'Good Morning': {
        'en': 'Good Morning',
        'th': 'สวัสดียามเช้า',
        'ja': 'おはようございます',
      },
      'Good Afternoon': {
        'en': 'Good Afternoon',
        'th': 'สวัสดียามบ่าย',
        'ja': 'こんにちは',
      },
      'Good Evening': {
        'en': 'Good Evening',
        'th': 'สวัสดียามเย็น',
        'ja': 'こんばんは',
      },
      'Good Night': {'en': 'Good Night', 'th': 'ราตรีสวัสดิ์', 'ja': 'おやすみなさい'},

      // คำโปรย
      'Ready for some music? 🎧': {
        'en': 'Ready for some music? 🎧',
        'th': 'พร้อมฟังเพลงหรือยัง? 🎧',
        'ja': '音楽を聴く準備はできましたか？ 🎧',
      },
      'Keep the music playing 🎵': {
        'en': 'Keep the music playing 🎵',
        'th': 'ให้เสียงเพลงบรรเลงต่อไป 🎵',
        'ja': '音楽を鳴らし続けよう 🎵',
      },
      'Relax with some tunes 🌆': {
        'en': 'Relax with some tunes 🌆',
        'th': 'ผ่อนคลายไปกับเสียงเพลง 🌆',
        'ja': '音楽でリラックス 🌆',
      },
      'Enjoy calm music 🌙': {
        'en': 'Enjoy calm music 🌙',
        'th': 'เพลิดเพลินกับเพลงฟังสบาย 🌙',
        'ja': '穏やかな音楽を楽しんで 🌙',
      },

      // การแจ้งเตือน
      'No notifications': {
        'en': 'No notifications',
        'th': 'ไม่มีการแจ้งเตือน',
        'ja': '通知はありません',
      },

      // หัวข้อต่างๆ
      'Your Favorite Artists': {
        'en': 'Your Favorite Artists',
        'th': 'ศิลปินคนโปรดของคุณ',
        'ja': 'お気に入りのアーティスト',
      },
      'Artist': {'en': 'Artist', 'th': 'ศิลปิน', 'ja': 'アーティスト'},
      'Made For You': {
        'en': 'Made For You',
        'th': 'จัดมาเพื่อคุณ',
        'ja': 'あなたのために',
      },
      'Top Hits Thailand': {
        'en': 'Top Hits Thailand',
        'th': 'ฮิตติดชาร์ตไทย',
        'ja': 'タイのトップヒット',
      },

      // ==========================================
      // หมวดหน้า Artist Detail (โปรไฟล์ศิลปิน)
      // ==========================================
      'Popular Songs': {
        'en': 'Popular Songs',
        'th': 'เพลงยอดนิยม',
        'ja': '人気の曲',
      },

      // (คำว่า 'tracks' เราได้เพิ่มไปแล้วในรอบก่อนหน้านี้ครับ แต่ถ้ายังไม่มีก็เติมบรรทัดล่างนี้ได้เลย)
      // 'tracks': {'en': 'tracks', 'th': 'แทร็ก', 'ja': '曲'},
      'Search': {'en': 'Search', 'th': 'ค้นหา', 'ja': '検索'},
      'Artists, songs, or podcasts...': {
        'en': 'Artists, songs, or podcasts...',
        'th': 'ศิลปิน เพลง หรือพอดแคสต์...',
        'ja': 'アーティスト、曲、ポッドキャスト...',
      },
      'Browse all': {
        'en': 'Browse all',
        'th': 'เลือกดูทั้งหมด',
        'ja': 'すべてを閲覧',
      },

      // ==========================================
      // หมวดหน้า Profile / Edit Profile
      // ==========================================
      'Edit Profile': {
        'en': 'Edit Profile',
        'th': 'แก้ไขโปรไฟล์',
        'ja': 'プロフィールを編集',
      },
      'Display Name': {'en': 'Display Name', 'th': 'ชื่อที่แสดง', 'ja': '表示名'},
      'New Password': {
        'en': 'New Password',
        'th': 'รหัสผ่านใหม่',
        'ja': '新しいパスワード',
      },
      'Leave blank to keep current': {
        'en': 'Leave blank to keep current',
        'th': 'เว้นว่างไว้หากไม่ต้องการเปลี่ยน',
        'ja': '変更しない場合は空白のままにしてください',
      },
      'Save': {'en': 'Save', 'th': 'บันทึก', 'ja': '保存'},

      // แถมคำอื่นๆ ในหน้า Profile ให้ด้วยครับ เผื่อคุณต้องใช้
      'Settings': {'en': 'Settings', 'th': 'การตั้งค่า', 'ja': '設定'},
      'Language': {'en': 'Language', 'th': 'ภาษา', 'ja': '言語'},
      'Dark Mode': {'en': 'Dark Mode', 'th': 'โหมดมืด', 'ja': 'ダークモード'},
      'Log Out': {'en': 'Log Out', 'th': 'ออกจากระบบ', 'ja': 'ログアウト'},

      // ==========================================
      // หน้าค้นหาเพลงเพื่อเพิ่มเข้าเพลย์ลิสต์ (Add Song Sheet)
      // ==========================================
      'Search songs to add': {
        'en': 'Search songs to add',
        'th': 'ค้นหาเพลงเพื่อเพิ่ม',
        'ja': '追加する曲を検索',
      },
      'Type song or artist...': {
        'en': 'Type song or artist...',
        'th': 'พิมพ์ชื่อเพลง หรือ ศิลปิน...',
        'ja': '曲名やアーティストを入力...',
      },
      'Recommended for you': {
        'en': 'Recommended for you',
        'th': 'เพลงแนะนำสำหรับคุณ',
        'ja': 'おすすめの曲',
      },
      'Search Results': {
        'en': 'Search Results',
        'th': 'ผลการค้นหา',
        'ja': '検索結果',
      },
      'No songs found': {
        'en': 'No songs found',
        'th': 'ไม่พบเพลงที่ค้นหา',
        'ja': '曲が見つかりません',
      },

      'Are you sure you want to log out?': {
        'en': 'Are you sure you want to log out?',
        'th': 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',
        'ja': '本当にログアウトしますか？',
      },

      'More': {'en': 'More', 'th': 'เพิ่มเติม', 'ja': 'もっと'},

      // ==========================================
      // เมนูตัวเลือกเพลง (Song Options) และ แชร์ (Share)
      // ==========================================
      'Share Song': {'en': 'Share Song', 'th': 'แชร์เพลง', 'ja': '曲を共有'},
      'Add to Playlist': {
        'en': 'Add to Playlist',
        'th': 'เพิ่มลงเพลย์ลิสต์',
        'ja': 'プレイリストに追加',
      },
      'Share': {'en': 'Share', 'th': 'แชร์', 'ja': '共有'},
      'Copy Link': {'en': 'Copy Link', 'th': 'คัดลอกลิงก์', 'ja': 'リンクをコピー'},
      'Download system coming soon': {
        'en': 'Download system coming soon',
        'th': 'ระบบดาวน์โหลดกำลังจะมาเร็วๆ นี้',
        'ja': 'ダウンロード機能はまもなく追加されます',
      },

      'Download system coming soon': {'en': 'Download system coming soon', 'th': 'ระบบดาวน์โหลดกำลังจะมาเร็วๆ นี้', 'ja': 'ダウンロード機能はまもなく追加されます'},
    };
    return dictionary[text]?[_lang] ?? text;
  }
}

// ============================================================================
// ProfilePage
// ============================================================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDataSaverEnabled = false;
  bool _isNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDataSaverEnabled = prefs.getBool('dataSaver') ?? false;
      _isNotificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'dataSaver') _isDataSaverEnabled = value;
      if (key == 'notifications') _isNotificationsEnabled = value;
    });
  }

  Future<void> _signOut(AppTheme t, LanguageProvider lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.t("Log out"), style: t.headline(18)),
        content: Text(
          lang.t("Are you sure you want to log out?"),
          style: t.secondary(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: t.secondary(15)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              lang.t("Log out"),
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
    }
  }

  void _showLanguageDialog(AppTheme t, LanguageProvider langProvider) {
    final Map<String, String> langs = {
      "English": "en",
      "ภาษาไทย": "th",
      "日本語": "ja",
    };

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(langProvider.t("Language"), style: t.headline(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.entries
              .map(
                (entry) => ListTile(
                  title: Text(entry.key, style: t.body(15)),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    langProvider.setLanguage(entry.value);

                    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    //   content: Text("Language set to ${entry.key}",
                    //     style: GoogleFonts.inter(color: Colors.white)),
                    //   backgroundColor: AppTheme.accent,
                    //   behavior: SnackBarBehavior.floating,
                    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //   margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    // ));
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final themeProvider = context.read<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.t("Profile"), style: t.headline(24)),
              Text(lang.t("Manage your account"), style: t.secondary(13)),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGlow,
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: t.surfaceHigh,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(Icons.person, size: 44, color: t.textHint)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? "Guest",
                          style: t.headline(20),
                        ),
                        const SizedBox(height: 3),
                        Text(user?.email ?? "No email", style: t.secondary(13)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: user != null
                                  ? FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('playlists')
                                        .snapshots()
                                  : const Stream.empty(),
                              builder: (context, snap) => _stat(
                                t,
                                (snap.data?.docs.length ?? 0).toString(),
                                lang.t("Playlists"),
                              ),
                            ),
                            _statDivider(t),
                            _stat(t, "0", lang.t("Followers")),
                            _statDivider(t),
                            _stat(t, "0", lang.t("Following")),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => setState(() {})),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: t.border),
                  ),
                  child: Center(
                    child: Text(lang.t("Edit Profile"), style: t.headline(15)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Appearance
              _sectionHeader(t, lang.t("Appearance")),
              _menuItem(
                t,
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: lang.t("Theme"),
                subtitle: isDark ? lang.t("Dark mode") : lang.t("Light mode"),
                trailing: _themeToggle(isDark, themeProvider),
              ),
              _menuItem(
                t,
                icon: Icons.language_rounded,
                title: lang.t("Language"),
                subtitle: lang.lang.toUpperCase(),
                onTap: () => _showLanguageDialog(t, lang),
              ),
              const SizedBox(height: 20),

              // Data & Storage
              _sectionHeader(t, lang.t("Data & Storage")),
              _menuItem(
                t,
                icon: Icons.data_usage_rounded,
                title: lang.t("Data Saver"),
                subtitle: lang.t("Lower quality on cellular data"),
                trailing: Switch(
                  value: _isDataSaverEnabled,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => _toggle('dataSaver', v),
                ),
              ),
              _menuItem(
                t,
                icon: Icons.cleaning_services_rounded,
                title: lang.t("Clear Cache"),
                subtitle: lang.t("Free up storage space"),
                // 🌟 ใช้ onTap ของ _menuItem ได้เลย ไม่ต้องใส่ GestureDetector
                onTap: () {
                  // โชว์แจ้งเตือน (ดึงฟังก์ชันมาจาก share_helper.dart)
                  showDownloadComingSoon(context);
                },
              ),
              const SizedBox(height: 20),

              // Notifications
              _sectionHeader(t, lang.t("Notifications")),
              _menuItem(
                t,
                icon: Icons.notifications_outlined,
                title: lang.t("Push Notifications"),
                subtitle: lang.t("New releases & recommendations"),
                trailing: Switch(
                  value: _isNotificationsEnabled,
                  activeColor: AppTheme.accent,
                  onChanged: (v) => _toggle('notifications', v),
                ),
              ),
              const SizedBox(height: 20),

              // About
              _sectionHeader(t, lang.t("About")),
              _menuItem(
                t,
                icon: Icons.privacy_tip_outlined,
                title: lang.t("Privacy Policy"),
                onTap: () {showDownloadComingSoon(context);},
              ),
              _menuItem(
                t,
                icon: Icons.help_outline_rounded,
                title: lang.t("Help & Support"),
                onTap: () {showDownloadComingSoon(context);},
              ),
              _menuItem(
                t,
                icon: Icons.info_outline_rounded,
                title: lang.t("Version"),
                trailingText: "1.0.0",
              ),
              const SizedBox(height: 36),

              // Log out
              GestureDetector(
                onTap: () => _signOut(t, lang),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.t("Log out"),
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(AppTheme t, String count, String label) => Column(
    children: [
      Text(count, style: t.headline(15)),
      const SizedBox(height: 2),
      Text(label, style: t.hint(11)),
    ],
  );

  Widget _statDivider(AppTheme t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Container(width: 1, height: 22, color: t.divider),
  );

  Widget _sectionHeader(AppTheme t, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: GoogleFonts.inter(
        color: t.textHint,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _themeToggle(bool isDark, ThemeProvider provider) => GestureDetector(
    onTap: provider.toggleTheme,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 52,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.accent : Colors.grey[300],
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(3),
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            size: 13,
            color: isDark ? AppTheme.accent : Colors.orange,
          ),
        ),
      ),
    ),
  );

  Widget _menuItem(
    AppTheme t, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Widget? trailing,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: t.textPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.body(15).copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.hint(12)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
          if (trailingText != null) ...[
            Text(trailingText, style: t.hint(13)),
            const SizedBox(width: 4),
          ],
          if (onTap != null && trailing == null)
            Icon(Icons.chevron_right_rounded, color: t.textHint, size: 20),
        ],
      ),
    ),
  );
}

// ============================================================================
// EditProfileScreen (มาครบตามที่คุณเขียนไว้)
// ============================================================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      if (_imageBytes != null) {
        const key = '4636b4781d7e416b8c83bc9799a56dd3';
        final res = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {'key': key, 'image': base64Encode(_imageBytes!)},
        );
        if (res.statusCode == 200) {
          await user!.updatePhotoURL(
            jsonDecode(res.body)['data']['display_url'],
          );
        }
      }
      if (_nameController.text.isNotEmpty &&
          _nameController.text != user?.displayName) {
        await user?.updateDisplayName(_nameController.text.trim());
      }
      if (_passwordController.text.isNotEmpty) {
        await user?.updatePassword(_passwordController.text);
      }
      await user?.reload();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Error'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final t = AppTheme(isDark: isDark);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.t("Edit Profile"), style: t.headline(18)),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.accent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    lang.t("Save"),
                    style: GoogleFonts.inter(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent, width: 2),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accentGlow, blurRadius: 16),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: t.surface,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!) as ImageProvider
                            : (user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null),
                        child: (_imageBytes == null && user?.photoURL == null)
                            ? Icon(Icons.person, size: 52, color: t.textHint)
                            : null,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.bg, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: _nameController,
              style: t.body(16),
              // 🌟 1. ใส่ lang.t() ครอบคำว่า Display Name
              decoration: t.textFieldDecoration(
                lang.t("Display Name"),
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: t.body(16),
              // 🌟 2. ใส่ lang.t() ครอบคำว่า New Password
              decoration: t
                  .textFieldDecoration(
                    lang.t("New Password"),
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: t.textHint,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  )
                  .copyWith(
                    hintText: "Leave blank to keep current",
                    hintStyle: t.hint(13),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
