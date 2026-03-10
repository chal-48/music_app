import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListeningHistoryScreen extends StatefulWidget {
  const ListeningHistoryScreen({super.key});

  @override
  State<ListeningHistoryScreen> createState() => _ListeningHistoryScreenState();
}

class _ListeningHistoryScreenState extends State<ListeningHistoryScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color accentColor = const Color(0xFFFF5500);

  // 🌟 ฟังก์ชันแถมพิเศษ: เอาไว้กดเพิ่มข้อมูลจำลอง เพื่อทดสอบว่าฐานข้อมูลทำงานจริง
  Future<void> _addMockSong() async {
    if (user == null) return;
    
    // รายชื่อเพลงจำลอง
    final mockSongs = [
      {"title": "Shape of You", "artist": "Ed Sheeran"},
      {"title": "Blinding Lights", "artist": "The Weeknd"},
      {"title": "รักแรก (First Love)", "artist": "NONT TANONT"},
      {"title": "Kill Bill", "artist": "SZA"},
    ];
    
    // สุ่มเลือกมา 1 เพลง
    final randomSong = mockSongs..shuffle();
    final songToAdd = randomSong.first;

    // ส่งข้อมูลขึ้น Cloud Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('recently_played')
        .add({
      'title': songToAdd['title'],
      'artist': songToAdd['artist'],
      'playedAt': FieldValue.serverTimestamp(), // บันทึกเวลา ณ ปัจจุบัน
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('จำลองการฟังเพลง: ${songToAdd['title']}'), backgroundColor: accentColor),
    );
  }

  // 🌟 ฟังก์ชันลบประวัติการฟังทั้งหมด (เพิ่มให้ครบสูตรครับ)
  Future<void> _clearHistory() async {
    if (user == null) return;
    
    var snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('recently_played')
        .get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("Please log in first", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Listening History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // ปุ่มถังขยะสำหรับลบประวัติ
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () {
              _clearHistory();
            },
          ),
        ],
      ),
      
      // ปุ่มลอยมุมขวาล่าง สำหรับกดเทสเพิ่มเพลง
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMockSong,
        backgroundColor: accentColor,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text("Simulate Play", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      // 🌟 พระเอกของเรา StreamBuilder ดึงข้อมูลจากฐานข้อมูลแบบ Real-time
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('recently_played')
            .orderBy('playedAt', descending: true) // เรียงจากเวลาล่าสุด
            .snapshots(),
        builder: (context, snapshot) {
          // กรณีค้างหรือกำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          // กรณีไม่มีข้อมูล (หน้าว่าง)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  Text("No recent history", style: TextStyle(color: Colors.grey[500], fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Songs you play will appear here.", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ),
            );
          }

          // กรณีมีข้อมูล ดึงมาแสดงเป็น List
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // เว้นที่ให้ปุ่ม Floating
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String title = data['title'] ?? 'Unknown Title';
              String artist = data['artist'] ?? 'Unknown Artist';
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12)
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
                title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(artist, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                trailing: const Icon(Icons.more_vert, color: Colors.grey),
                onTap: () {
                  // สามารถทำฟังก์ชันกดเพื่อเล่นเพลงซ้ำได้
                },
              );
            },
          );
        },
      ),
    );
  }
}