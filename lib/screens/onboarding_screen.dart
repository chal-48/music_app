import 'package:flutter/material.dart';
import 'package:music_app/screens/auth_screen.dart'; // import หน้า AuthScreen
// import 'package:shared_preferences/shared_preferences.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _controller = PageController();

  // ข้อมูลที่จะแสดงในแต่ละหน้า
  final List<Map<String, String>> contents = [
    {
      "image": "assets/images/music.jpg", // ใส่ URL รูปจริงของคุณ
      "title": "Music for everyone",
      "desc": "Millions of songs. No credit card needed. Get all the music you love.",
    },
    {
      "image": "assets/images/radio.jpg",
      "title": "Listen offline",
      "desc": "Download your favorite tracks and enjoy music without internet connection.",
    },
    {
      "image": "assets/images/concert.jpg",
      "title": "Ad-free listening",
      "desc": "Enjoy nonstop music. No interruptions. Just you and your favorite tunes.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ไม่ต้องกำหนด backgroundColor ที่นี่ เพราะเราจะใช้ Container ไล่สีแทน
      body: Container(
        // 1. เพิ่ม Gradient Background เพื่อคุมธีม
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF14241B), // สีเขียวเข้มมากๆ (เกือบดำ) ด้านบน
              Colors.black,      // สีดำสนิทด้านล่าง
            ],
            stops: [0.0, 1.0], // ไล่สีจนสุดขอบล่าง
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 2. ส่วนรูปภาพและข้อความ (เลื่อนได้)
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: contents.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0), // ปรับ Padding ด้านข้าง
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // รูปภาพ (ปรับความสูงเป็น % ของจอ เพื่อกันล้น)
                          Container(
                            height: MediaQuery.of(context).size.height * 0.35, 
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1DB954).withOpacity(0.2), // เงาสีเขียวจางๆ
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                )
                              ],
                              image: DecorationImage(
                                image: NetworkImage(contents[index]["image"]!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // หัวข้อ
                          Text(
                            contents[index]["title"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // คำอธิบาย
                          Text(
                            contents[index]["desc"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 3. ส่วนจุดบอกตำแหน่งและปุ่ม (อยู่ด้านล่าง)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Dot Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        contents.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                    const Spacer(),
                    
                    // ปุ่ม Get Started / Next
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56, // ความสูงปุ่มมาตรฐาน
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_currentIndex == contents.length - 1) {
                              _completeOnboarding();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954), // สีเขียว Spotify
                            foregroundColor: Colors.black, // สีตัวหนังสือดำ
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            _currentIndex == contents.length - 1 ? "Get Started" : "Next",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างจุด (Dot)
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      height: 6,
      width: _currentIndex == index ? 24 : 6, // ยืดความกว้างถ้าเป็นหน้าปัจจุบัน
      decoration: BoxDecoration(
        color: _currentIndex == index ? const Color(0xFF1DB954) : Colors.grey[800],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  void _completeOnboarding() async {
    // เช็ค mounted ก่อนเปลี่ยนหน้า เพื่อป้องกัน error
    if (!mounted) return;
    
    // เปลี่ยนไปหน้า AuthScreen (Login/Signup)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }
}