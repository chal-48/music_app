import 'dart:math'; 
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

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isRepeat) {
        seek(Duration.zero);
        _audioPlayer.resume();
        _isPlaying = true;
        notifyListeners();
      } else if (hasNext || _isShuffle) {
        playNext(); 
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        notifyListeners();
      }
    });
  }

  Future<void> playPlaylist(List<dynamic> playlist, int startIndex) async {
    if (playlist.isEmpty || startIndex < 0 || startIndex >= playlist.length) return;
    _currentPlaylist = playlist;
    _currentIndex = startIndex;
    await playSong(_currentPlaylist[_currentIndex]);
  }

  Future<void> playSong(Map<String, dynamic> song) async {
    String url = song['previewUrl'] ?? "";
    
    // 🌟 แก้บัค: ถ้าเพลงไม่มีพรีวิว ให้ทำการข้ามเพลงอัตโนมัติ
    if (url.isEmpty) {
      print("🚨 ข้ามเพลง: ${song['title'] ?? 'Unknown'} (ไม่มีตัวอย่างเสียง)");
      
      // หน่วงเวลาเล็กน้อยเพื่อไม่ให้แอปข้ามเพลงรัวเกินไปถ้าติดกันหลายเพลง
      await Future.delayed(const Duration(milliseconds: 500)); 
      
      if (hasNext || _isShuffle) {
        await playNext();
      } else {
        _isPlaying = false;
        notifyListeners();
      }
      return; 
    }

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

  Future<void> playNext() async {
    if (_currentPlaylist.isEmpty) return;
    
    if (_isShuffle) {
      _currentIndex = Random().nextInt(_currentPlaylist.length);
      await playSong(_currentPlaylist[_currentIndex]);
    } else if (hasNext) {
      _currentIndex++;
      await playSong(_currentPlaylist[_currentIndex]);
    }
  }

  Future<void> playPrevious() async {
    if (_currentPlaylist.isEmpty) return;

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
      seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

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