import 'dart:math'; // 🌟 เพิ่มสำหรับฟังก์ชันสุ่มเพลง
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  List<dynamic> _currentPlaylist = [];
  int _currentIndex = 0;

  // 🌟 เพิ่มสถานะสำหรับ สุ่มเพลง และ เล่นซ้ำ
  bool _isShuffle = false;
  bool _isRepeat = false;

  Map<String, dynamic>? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;

  bool get hasNext => _currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length - 1;
  bool get hasPrevious => _currentPlaylist.isNotEmpty && _currentIndex > 0;

  MusicProvider() {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    // 🌟 ดักจับตอนเพลงเล่นจบ
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRepeat) {
        // ถ้าเปิดเล่นวนซ้ำ ให้กลับไปเริ่มวิที่ 0 แล้วเล่นต่อ
        seek(Duration.zero);
        _audioPlayer.resume();
        _isPlaying = true;
        notifyListeners();
      } else if (hasNext || _isShuffle) {
        // ถ้ามีเพลงถัดไป หรือเปิดสุ่มเพลง ให้เล่นเพลงต่อไป
        playNext(); 
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        notifyListeners();
      }
    });
  }

  // ==========================================
  // 🎵 ฟังก์ชันหลักของเครื่องเล่นเพลง
  // ==========================================

  Future<void> playPlaylist(List<dynamic> playlist, int startIndex) async {
    if (playlist.isEmpty || startIndex < 0 || startIndex >= playlist.length) return;
    _currentPlaylist = playlist;
    _currentIndex = startIndex;
    await playSong(_currentPlaylist[_currentIndex]);
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    String url = song['previewUrl'] ?? "";
    if (url.isEmpty) return; 

    _currentSong = song;
    _isPlaying = true;
    notifyListeners();
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> togglePlay() async {
    if (_currentSong == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    } else {
      await _audioPlayer.resume();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // 🌟 เล่นเพลงถัดไป (Next)
  Future<void> playNext() async {
    if (_currentPlaylist.isEmpty) return;
    
    if (_isShuffle) {
      // ถ้าเปิดสุ่ม ให้สุ่ม Index ใหม่
      _currentIndex = Random().nextInt(_currentPlaylist.length);
      await playSong(_currentPlaylist[_currentIndex]);
    } else if (hasNext) {
      // ถ้าไม่ได้สุ่ม ให้เล่นเพลงถัดไปตามลำดับ
      _currentIndex++;
      await playSong(_currentPlaylist[_currentIndex]);
    }
  }

  // 🌟 เล่นเพลงก่อนหน้า (Previous)
  Future<void> playPrevious() async {
    if (_currentPlaylist.isEmpty) return;

    // ถ้ากดปุ่มย้อนกลับตอนที่เพลงเล่นไปแล้วเกิน 3 วินาที ให้เริ่มเพลงเดิมใหม่
    if (_position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (_isShuffle) {
      _currentIndex = Random().nextInt(_currentPlaylist.length);
      await playSong(_currentPlaylist[_currentIndex]);
    } else if (hasPrevious) {
      _currentIndex--;
      await playSong(_currentPlaylist[_currentIndex]);
    } else {
      seek(Duration.zero); // ถ้าเป็นเพลงแรกสุด ให้เริ่มใหม่
    }
  }

  // 🌟 เปิด/ปิด โหมดสุ่มเพลง
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // 🌟 เปิด/ปิด โหมดเล่นวนซ้ำ
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}