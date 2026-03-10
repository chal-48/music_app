import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'profile_screen.dart'; // ดึง ThemeProvider และ LanguageProvider

void showShareMenu(BuildContext context, [Map<String, dynamic>? song]) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent, 
    isScrollControlled: true,
    builder: (sheetContext) {
      // 🌟 ดึงค่า ธีม และ ภาษา
      final isDark = sheetContext.watch<ThemeProvider>().isDarkMode;
      final t = AppTheme(isDark: isDark);
      final lang = sheetContext.watch<LanguageProvider>();

      return Container(
        decoration: BoxDecoration(
          color: t.sheetBg, // 🌟 สีพื้นหลังตามธีม
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(bottom: 30), // เพิ่มระยะขอบล่างให้สวยงาม
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // ขีดเส้นลาก (Drag Handle)
            Container(
              width: 40, 
              height: 4, 
              decoration: BoxDecoration(
                color: t.border, 
                borderRadius: BorderRadius.circular(2)
              )
            ),
            const SizedBox(height: 24),

            // 🌟 ถ้าระบุเพลงมา ให้โชว์หน้าปกเพลงและชื่อเพลงสวยๆ ด้านบน
            if (song != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: t.surfaceHigh, child: Icon(Icons.music_note, color: t.iconMuted)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song['title'] ?? 'Unknown',
                            style: TextStyle(color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song['artist'] ?? 'Unknown',
                            style: TextStyle(color: t.textSecond, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: t.divider, height: 1),
              const SizedBox(height: 20),
            ] else ...[
              // ถ้าไม่มีเพลงส่งมา โชว์แค่หัวข้อ Share
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  lang.t("Share"),
                  style: TextStyle(color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 🌟 ปุ่มแชร์แบบพรีเมียม (ดีไซน์วงกลม)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPremiumShareIcon(context, sheetContext, Icons.facebook, "Facebook", const Color(0xFF1877F2), t),
                  _buildPremiumShareIcon(context, sheetContext, Icons.camera_alt, "Instagram", const Color(0xFFE1306C), t),
                  _buildPremiumShareIcon(context, sheetContext, Icons.link_rounded, lang.t("Copy Link"), t.textPrimary, t),
                  _buildPremiumShareIcon(context, sheetContext, Icons.more_horiz_rounded, lang.t("More"), t.textPrimary, t),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }
  );
}

// ==========================================
// แจ้งเตือน (ระดับความสูงเดียวกับ Mini Player)
// ==========================================
// ==========================================
// แจ้งเตือน (ลอยอยู่เหนือ Mini Player พอดีเป๊ะ)
// ==========================================
void showDownloadComingSoon(BuildContext context) {
  final isDark = context.read<ThemeProvider>().isDarkMode;
  final t = AppTheme(isDark: isDark);
  final lang = context.read<LanguageProvider>();

  // เคลียร์การแจ้งเตือนเก่าออกก่อน จะได้ไม่เด้งซ้อนกัน
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lang.t("Download system coming soon"),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF333333), // สีเทาเข้มพรีเมียม
      behavior: SnackBarBehavior.floating, // ลอยตัวอิสระ
      duration: const Duration(seconds: 2),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      
      // 🌟 แก้ตรงนี้: เปลี่ยน margin ให้เหลือแค่ขอบซ้าย/ขวา/ล่างนิดเดียว 
      // มันจะตกลงมาวางพักอยู่บนกรอบของ Mini Player พอดีเป๊ะ ไม่ลอยโด่งแล้วครับ
      margin: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
    ),
  );
}
// ==========================================
// วิดเจ็ตปุ่มแชร์ทรงกลม
// ==========================================
Widget _buildPremiumShareIcon(
  BuildContext mainContext,
  BuildContext sheetContext,
  IconData icon,
  String label,
  Color iconColor,
  AppTheme t, 
) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(sheetContext);
      showDownloadComingSoon(mainContext); // 🌟 ทำงานเหมือนเดิมเป๊ะ (โชว์ Snackbar)
    },
    behavior: HitTestBehavior.opaque,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: t.surfaceHigh, // พื้นหลังวงกลมสีตามธีม
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: t.textSecond, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}