import 'package:flutter/material.dart';

// 🌟 ฟังก์ชันหลักที่เราจะเรียกใช้จากไฟล์อื่นๆ
void showShareMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "แชร์",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ส่งต่อ context ทั้ง 2 ตัวเข้าไปในปุ่ม
              _buildShareIcon(
                context,
                sheetContext,
                Icons.facebook,
                "Facebook",
                Colors.blue,
              ),
              _buildShareIcon(
                context,
                sheetContext,
                Icons.camera_alt,
                "Instagram",
                Colors.purpleAccent,
              ),
              _buildShareIcon(
                context,
                sheetContext,
                Icons.link,
                "Copy Link",
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showDownloadComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        "ระบบดาวน์โหลดกำลังจะมาเร็วๆ นี้",
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: const Color(0xFF2C2C2C),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
    ),
  );
}

// 🌟 ฟังก์ชันสร้างปุ่ม (ใส่ _ นำหน้าไว้ เพราะเราใช้แค่ในไฟล์นี้ ไม่ต้องดึงไปไฟล์อื่น)
Widget _buildShareIcon(
  BuildContext mainContext,
  BuildContext sheetContext,
  IconData icon,
  String label,
  Color color,
) {
  return GestureDetector(
    onTap: () {
      // 1. ปิดหน้าต่างเมนูแชร์ (BottomSheet) ก่อน
      Navigator.pop(sheetContext);

      // 2. แสดงข้อความแจ้งเตือน
      showDownloadComingSoon(mainContext);

      // 3. เด้งออกจากหน้าหลัก (เช่น หน้า Playlist)
      // เช็ค Navigator.canPop ก่อน เพื่อป้องกัน Error เผื่อเอาไปใช้ในหน้าจอที่มันย้อนกลับไม่ได้แล้ว
      // if (Navigator.canPop(mainContext)) {
      //   Navigator.pop(mainContext);
      // }
    },
    child: Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );

  
}

