// import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String songUrl;
  final String category;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.songUrl,
    required this.category,
  });

  // ฟังก์ชันแปลงจาก Firestore Document เป็น Object ของเรา
  // factory Song.fromSnapshot(DocumentSnapshot doc) {
  //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //   return Song(
  //     id: doc.id,
  //     title: data['title'] ?? '',
  //     artist: data['artist'] ?? '',
  //     albumArtUrl: data['albumArtUrl'] ?? '', // รูป Default ถ้าไม่มี
  //     songUrl: data['songUrl'] ?? '',
  //     category: data['category'] ?? 'Pop',
  //   );
  // }
}