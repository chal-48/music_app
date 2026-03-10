import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart'; // import หน้า AuthScreen
import 'app_theme.dart'; // 🌟 import ธีมของคุณเพื่อดึงสีส้มมาใช้

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final PageController _controller = PageController();

  // 🌟 ใช้รูปภาพจากอินเทอร์เน็ตที่สวยงามและเข้ากับธีมดนตรี
  final List<Map<String, String>> contents = [
    {
      "image": "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=800&q=80", 
      "title": "Music for everyone",
      "desc": "Millions of songs. No credit card needed. Get all the music you love.",
    },
    {
      "image": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80",
      "title": "Listen offline",
      "desc": "Download your favorite tracks and enjoy music without internet connection.",
      },
    {
      "image": "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&q=80",
      "title": "Ad-free listening",
      "desc": "Enjoy nonstop music. No interruptions. Just you and your favorite tunes.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🌟 1. เปลี่ยน Gradient Background เป็นโทนดำ-ส้ม ให้เข้ากับแอป
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B1100), // สีส้มเข้มมากๆ (เกือบดำ) ด้านบน
              Colors.black,      // สีดำสนิทด้านล่าง
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // รูปภาพ
                          Container(
                            height: MediaQuery.of(context).size.height * 0.35,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3), // 🌟 เงาสีส้มเรืองแสง
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
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

              // ส่วนจุดบอกตำแหน่งและปุ่ม
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
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // 🌟 2. แก้โลจิกให้กด Next เพื่อเลื่อนหน้าได้
                            if (_currentIndex == contents.length - 1) {
                              _completeOnboarding(); // ถ้าหน้าสุดท้ายให้เข้าแอป
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ); // ถ้าไม่ใช่ ให้เลื่อนไปหน้าถัดไป
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent, // 🌟 ใช้สีส้มหลักของแอป
                            foregroundColor: Colors.white,    // 🌟 เปลี่ยนสีข้อความเป็นสีขาวให้เด่นขึ้น
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                            shadowColor: AppTheme.accent.withOpacity(0.5), // เงาปุ่มสีส้ม
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
      width: _currentIndex == index ? 24 : 6,
      decoration: BoxDecoration(
        color: _currentIndex == index ? AppTheme.accent : Colors.grey[800], // 🌟 จุดสีส้ม
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // ฟังก์ชันเมื่อกด Get Started จบ Onboarding
  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false); // บันทึกว่าดูจบแล้ว

    if (!mounted) return;

    // เปลี่ยนไปหน้า AuthScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }
}