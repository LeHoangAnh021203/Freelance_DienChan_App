import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MultiDemoApp());
}

/// Shared unread count so chuông home luôn khớp màn Thông báo.
final ValueNotifier<int> notificationUnreadCount = ValueNotifier<int>(3);

/// Ảnh gương mặt người dùng để phủ bản đồ huyệt.
final ValueNotifier<Uint8List?> userFacePhotoBytes = ValueNotifier<Uint8List?>(
  null,
);

class MultiDemoApp extends StatelessWidget {
  const MultiDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sổ tay điện tử Diện Chẩn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: finflowPreset.scheme,
        scaffoldBackgroundColor: finflowPreset.background,
      ),
      home: const DemoShell(preset: finflowPreset),
    );
  }
}

class DemoPreset {
  const DemoPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.scheme,
    required this.cardGradient,
    required this.background,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final ColorScheme scheme;
  final List<Color> cardGradient;
  final Color background;
}

const finflowPreset = DemoPreset(
  id: 'finflow',
  title: 'Sổ tay điện tử Diện Chẩn',
  subtitle: 'Hiện đại, nổi khối, năng động',
  description: 'Ưu tiên cảm giác cao cấp và trực quan cho người dùng mới.',
  scheme: ColorScheme.light(
    primary: Color(0xFFB55238),
    secondary: Color(0xFFD4A054),
    surface: Color(0xFFFFFBF6),
    onSurface: Color(0xFF2C1A12),
  ),
  cardGradient: [Color(0xFFB55238), Color(0xFFE07B50)],
  background: Color(0xFFF6EFE6),
);

/// Giữ lại Mẫu B/C trong code phòng khi cần tham chiếu; app chạy mặc định Mẫu A.
const demoPresets = [
  finflowPreset,
  DemoPreset(
    id: 'clinical',
    title: 'Mẫu B - Tối giản lâm sàng',
    subtitle: 'Sạch, rõ, thiên về y khoa',
    description: 'Tối ưu đọc nội dung chuyên môn và thao tác nhanh.',
    scheme: ColorScheme.light(
      primary: Color(0xFF135B89),
      secondary: Color(0xFF39A1ED),
      surface: Colors.white,
      onSurface: Color(0xFF0D1D2A),
    ),
    cardGradient: [Color(0xFF135B89), Color(0xFF2A86BD)],
    background: Color(0xFFF5F9FC),
  ),
  DemoPreset(
    id: 'night',
    title: 'Mẫu C - Tối cao cấp',
    subtitle: 'Sang trọng, tập trung ban đêm',
    description: 'Phù hợp nhóm người dùng hay dùng ứng dụng buổi tối.',
    scheme: ColorScheme.dark(
      primary: Color(0xFFA4D46E),
      secondary: Color(0xFF7BB8FF),
      surface: Color(0xFF151D1A),
      onSurface: Color(0xFFE8F2ED),
    ),
    cardGradient: [Color(0xFF1E2C24), Color(0xFF2D4034)],
    background: Color(0xFF0E1311),
  ),
];

class DemoShell extends StatefulWidget {
  const DemoShell({required this.preset, super.key});

  final DemoPreset preset;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final isDark = preset.scheme.brightness == Brightness.dark;
    final isFinflow = preset.id == 'finflow';
    final isNestfind = preset.id == 'clinical';

    final pages = [HomeTab(preset: preset), ProfileTab(preset: preset)];
    final safeTab = tab.clamp(0, pages.length - 1);

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: preset.scheme.brightness,
        colorScheme: preset.scheme,
        scaffoldBackgroundColor: preset.background,
      ),
      child: Scaffold(
        appBar: isFinflow || isNestfind
            ? null
            : AppBar(
                title: Text(preset.title),
                backgroundColor: isDark
                    ? const Color(0xFF151D1A)
                    : Colors.white,
              ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: pages[safeTab],
        ),
        bottomNavigationBar: isFinflow
            ? _FinflowBottomBar(
                selectedIndex: safeTab,
                onTap: (value) => setState(() => tab = value),
              )
            : isNestfind
            ? _NestBottomBar(
                selectedIndex: tab,
                onTap: (value) => setState(() => tab = value),
              )
            : NavigationBar(
                selectedIndex: tab,
                indicatorColor: preset.scheme.primary.withValues(alpha: 0.18),
                onDestinationSelected: (value) => setState(() => tab = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Cá nhân',
                  ),
                ],
              ),
      ),
    );
  }
}

class _FinflowBottomBar extends StatelessWidget {
  const _FinflowBottomBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  void _openCamera(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return _FaceCaptureSheet(parentContext: context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _FinflowNavItem(
                icon: Icons.home_outlined,
                label: 'Trang chủ',
                active: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _FinflowNavItem(
                icon: Icons.photo_camera_outlined,
                label: 'Chụp ảnh',
                active: false,
                onTap: () => _openCamera(context),
              ),
            ),
            Expanded(
              child: _FinflowNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Hồ sơ',
                active: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceCaptureSheet extends StatelessWidget {
  const _FaceCaptureSheet({required this.parentContext});

  final BuildContext parentContext;

  Future<void> _pick(BuildContext sheetContext, ImageSource source) async {
    Navigator.pop(sheetContext);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      userFacePhotoBytes.value = bytes;
      if (!parentContext.mounted) return;
      await Navigator.of(parentContext).push(
        MaterialPageRoute(
          builder: (_) => _LegacyModulePage(
            module: dienChanModules.first,
            startWithAllPoints: true,
          ),
        ),
      );
    } catch (_) {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Không mở được camera/thư viện. Thử chọn ảnh từ thư viện.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chụp gương mặt',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lấy ảnh mặt thật để phủ lưới và bản đồ huyệt trực quan hơn.',
              style: TextStyle(color: Color(0xFF6E776F)),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: const Color(0xFFF6FAF4),
              leading: const Icon(Icons.photo_camera_front_rounded),
              title: const Text('Chụp selfie'),
              subtitle: const Text('Dùng camera trước để lấy gương mặt'),
              onTap: () => _pick(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: const Color(0xFFF6FAF4),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn ảnh có sẵn'),
              subtitle: const Text('Lấy ảnh mặt từ thư viện'),
              onTap: () => _pick(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrCommunitySheet extends StatelessWidget {
  const _QrCommunitySheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quét mã QR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dùng để thêm bạn bè hoặc tham gia cộng đồng Diện Chẩn.',
              style: TextStyle(color: Color(0xFF6E776F)),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: const Color(0xFFF6FAF4),
              leading: const Icon(Icons.person_add_alt_1_rounded),
              title: const Text('Quét để thêm bạn bè'),
              subtitle: const Text('Kết nối nhanh bằng mã cá nhân'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Đã chọn: Quét để thêm bạn bè')),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: const Color(0xFFF6FAF4),
              leading: const Icon(Icons.groups_2_outlined),
              title: const Text('Quét để tham gia cộng đồng'),
              subtitle: const Text('Vào nhóm chia sẻ theo mã mời'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Đã chọn: Quét để tham gia cộng đồng'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FinflowNavItem extends StatelessWidget {
  const _FinflowNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 19),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? const Color(0xFF8C3D28) : const Color(0xFFA08978),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? const Color(0xFF8C3D28)
                    : const Color(0xFFA08978),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({required this.preset, super.key});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    if (preset.id == 'finflow') {
      return const _FinflowHomeTab();
    }
    if (preset.id == 'clinical') {
      return const _NestfindHomeTab();
    }
    if (preset.id == 'night') {
      return const _NightHomeTab();
    }

    return ListView(
      key: ValueKey('${preset.id}-home'),
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(preset: preset),
        const SizedBox(height: 12),
        _SectionTitle('Tổng quan nhanh'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                'Huyệt',
                '64',
                Icons.face_retouching_natural,
                preset,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                'Phác đồ',
                '12',
                Icons.medication_outlined,
                preset,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _StatCard('Nhắc giờ', '3', Icons.alarm, preset)),
          ],
        ),
        const SizedBox(height: 12),
        _SectionTitle('9 màn hình trong sản phẩm'),
        const SizedBox(height: 10),
        ...[
          'Trang chủ',
          'Tra cứu',
          'Đồ hình tương tác',
          'Chi tiết huyệt',
          'Phác đồ theo bệnh',
          'Chi tiết phác đồ',
          'Bệnh án & nhật ký',
          'Kết nối',
          'Cá nhân / cài đặt',
        ].map((e) => _SimpleListTile(title: e, preset: preset)),
      ],
    );
  }
}

class LookupTab extends StatelessWidget {
  const LookupTab({required this.preset, this.onBackHome, super.key});

  final DemoPreset preset;
  final VoidCallback? onBackHome;

  @override
  Widget build(BuildContext context) {
    if (preset.id == 'finflow') {
      return _FinflowLookupTab(preset: preset, onBackHome: onBackHome);
    }
    if (preset.id == 'clinical') {
      return const _NestfindLookupTab();
    }
    if (preset.id == 'night') {
      return const _NightLookupTab();
    }

    final chipColor = preset.scheme.primary.withValues(alpha: 0.12);

    return ListView(
      key: ValueKey('${preset.id}-lookup'),
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Tra cứu đa lối vào'),
        const SizedBox(height: 8),
        _SearchBox(preset: preset),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Mất ngủ', chipColor),
            _chip('Đau đầu', chipColor),
            _chip('Ho đêm', chipColor),
            _chip('Viêm xoang', chipColor),
            _chip('Mỏi cổ vai', chipColor),
          ],
        ),
        const SizedBox(height: 12),
        _FlowLine(preset: preset),
        const SizedBox(height: 12),
        _SimpleListTile(
          title: 'Bệnh: Mất ngủ -> Phác đồ an thần 8 phút',
          preset: preset,
          trailing: Icons.open_in_new,
        ),
        _SimpleListTile(
          title: 'Bệnh: Đau đầu -> Phác đồ giảm đau 6 phút',
          preset: preset,
          trailing: Icons.open_in_new,
        ),
        _SimpleListTile(
          title: 'Mở đồ hình tương tác: chạm để xem huyệt',
          preset: preset,
          trailing: Icons.face_6_outlined,
        ),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text),
    );
  }
}

class CommunityTab extends StatelessWidget {
  const CommunityTab({required this.preset, super.key});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    if (preset.id == 'finflow') {
      return _FinflowCommunityTab(preset: preset);
    }
    if (preset.id == 'clinical') {
      return const _NestfindCommunityTab();
    }
    if (preset.id == 'night') {
      return const _NightCommunityTab();
    }

    return ListView(
      key: ValueKey('${preset.id}-community'),
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Kết nối cộng đồng'),
        const SizedBox(height: 10),
        _PostCard(
          title: 'Hỏi đáp huyệt trị mất ngủ',
          desc: 'Người dùng hỏi cách kết hợp huyệt 26 + 124 trước khi ngủ.',
          preset: preset,
        ),
        _PostCard(
          title: 'Chia sẻ trải nghiệm phục hồi',
          desc: 'Sau 2 tuần theo phác đồ, triệu chứng ho giảm rõ.',
          preset: preset,
        ),
        _PostCard(
          title: 'Tìm chuyên gia theo khu vực',
          desc: 'Danh sách trợ giảng trực tuyến đã mở lịch tuần này.',
          preset: preset,
        ),
      ],
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({required this.preset, super.key});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    if (preset.id == 'finflow') {
      return _FinflowProfileTab(preset: preset);
    }
    if (preset.id == 'clinical') {
      return const _NestfindProfileTab();
    }
    if (preset.id == 'night') {
      return const _NightProfileTab();
    }

    return ListView(
      key: ValueKey('${preset.id}-profile'),
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Cá nhân / Cài đặt'),
        const SizedBox(height: 10),
        _SimpleListTile(title: 'Bệnh án & Nhật ký cá nhân', preset: preset),
        _SimpleListTile(title: 'Ghi chú & Lưu', preset: preset),
        _SimpleListTile(
          title: 'Nhắc nhở giờ làm: 07:00, 21:00',
          preset: preset,
        ),
        _SimpleListTile(
          title: 'Đồng bộ đám mây theo tài khoản',
          preset: preset,
        ),
        _SimpleListTile(
          title: 'Banner cảnh báo an toàn khi có nguy cơ',
          preset: preset,
          trailing: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}

class _NestBottomBar extends StatelessWidget {
  const _NestBottomBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NestNavItem(
                icon: Icons.home_filled,
                active: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NestNavItem(
                icon: Icons.favorite_border_rounded,
                active: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NestNavItem(
                icon: Icons.calendar_today_outlined,
                active: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NestNavItem(
                icon: Icons.search_rounded,
                active: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NestNavItem extends StatelessWidget {
  const _NestNavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 20,
        color: active ? Colors.white : const Color(0xFFC6C6C6),
      ),
    );
  }
}

class _NestfindHomeTab extends StatelessWidget {
  const _NestfindHomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('nestfind-home'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
      children: [
        const Center(
          child: Text(
            'DienChan',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: Color(0xFF121212),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: Color(0xFF6E7175)),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Bắt đầu tra cứu triệu chứng của bạn',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A8F95)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tìm kiếm gần đây',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _NestChip('Mất ngủ'),
            _NestChip('Đau đầu', active: true),
            _NestChip('Viêm xoang'),
            _NestChip('Ho đêm'),
            _NestChip('Huyệt 26'),
            _NestChip('Nhóm hỗ trợ'),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: const [
            _NestPropertyCard(
              title: 'Mất ngủ mãn',
              subtitle: '8 phút / phác đồ',
            ),
            _NestPropertyCard(
              title: 'Đau đầu căng',
              subtitle: '6 phút / phác đồ',
            ),
            _NestPropertyCard(title: 'Ho kéo dài', subtitle: '4 huyệt chính'),
            _NestPropertyCard(
              title: 'Viêm xoang',
              subtitle: '2 đồ hình hỗ trợ',
            ),
          ],
        ),
      ],
    );
  }
}

class _NestChip extends StatelessWidget {
  const _NestChip(this.text, {this.active = false});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E5E7)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: active ? Colors.white : const Color(0xFF23262A),
        ),
      ),
    );
  }
}

class _NestPropertyCard extends StatelessWidget {
  const _NestPropertyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD8E7F5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, color: Color(0xFF5C6C7B)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF787E85),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Mở',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NestfindLookupTab extends StatelessWidget {
  const _NestfindLookupTab();

  void _openVoiceSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _NestVoiceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('nestfind-lookup'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
      children: [
        const Text(
          'Tra cứu',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),
        ),
        const SizedBox(height: 10),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 18,
                color: Color(0xFF6E7175),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nhập triệu chứng, bệnh, huyệt...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8F95),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openVoiceSearch(context),
                icon: const Icon(Icons.mic_none_rounded, size: 19),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _NestChip('Mất ngủ', active: true),
            _NestChip('Đau đầu'),
            _NestChip('Viêm xoang'),
            _NestChip('Ho đêm'),
            _NestChip('Huyệt 26'),
          ],
        ),
        const SizedBox(height: 12),
        const _NestActivityItem(
          title: 'Mất ngủ',
          subtitle: 'Phác đồ an thần buổi tối',
          tail: '+8 phút',
          positive: true,
        ),
        const _NestActivityItem(
          title: 'Đau đầu dữ dội',
          subtitle: 'Phác đồ giảm đau khẩn',
          tail: '+6 phút',
          positive: true,
        ),
        const _NestActivityItem(
          title: 'Ho kéo dài',
          subtitle: 'Kích hoạt cảnh báo an toàn',
          tail: '-Lưu ý',
          positive: false,
        ),
      ],
    );
  }
}

class _NestVoiceSheet extends StatelessWidget {
  const _NestVoiceSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE7F4EC),
            child: Icon(
              Icons.mic_none_rounded,
              color: Color(0xFF1E4F38),
              size: 34,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Đang nghe để tra cứu...',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 4),
          Text(
            'Ví dụ: "Mất ngủ", "Đau đầu", "Huyệt 26"',
            style: TextStyle(color: Color(0xFF728076)),
          ),
        ],
      ),
    );
  }
}

class _NestActivityItem extends StatelessWidget {
  const _NestActivityItem({
    required this.title,
    required this.subtitle,
    required this.tail,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String tail;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1F2A23),
            child: Text(
              title.substring(0, 1),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF737A82),
                  ),
                ),
              ],
            ),
          ),
          Text(
            tail,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: positive
                  ? const Color(0xFF1D5C45)
                  : const Color(0xFFD24E49),
            ),
          ),
        ],
      ),
    );
  }
}

class _NestfindCommunityTab extends StatelessWidget {
  const _NestfindCommunityTab();

  void _openQrActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _QrCommunitySheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('nestfind-community'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Kết nối',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),
              ),
            ),
            GestureDetector(
              onTap: () => _openQrActions(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ConnectCard(
          isPrimary: true,
          title: 'Mã kết nối bạn bè',
          connectionId: 'ID-BAN-LEHOANGANH-5690',
          expiry: '07/30',
          status: 'Bạn bè: 128',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _ConnectionListPage(
                title: 'Danh sách bạn bè',
                accent: Color(0xFFD7F266),
                icon: Icons.person_outline_rounded,
                items: [
                  'Nguyễn Anh Tuấn · ID-BAN-TUAN-3021',
                  'Trần Minh Hà · ID-BAN-HA-7742',
                  'Lê Thanh Vy · ID-BAN-VY-6180',
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ConnectCard(
          isPrimary: false,
          title: 'Mã nhóm chuyên gia',
          connectionId: 'ID-NHOM-CHUYENGIA-3421',
          expiry: '12/28',
          status: 'Nhóm: 24',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _ConnectionListPage(
                title: 'Danh sách nhóm cộng đồng',
                accent: Color(0xFF1F4C39),
                icon: Icons.groups_2_outlined,
                items: [
                  'Nhóm Mất ngủ chủ động · ID-NHOM-MATNGU-01',
                  'Nhóm Đau đầu phản chiếu · ID-NHOM-DAUDAU-08',
                  'Nhóm Hỗ trợ người mới · ID-NHOM-MOI-15',
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NestfindProfileTab extends StatelessWidget {
  const _NestfindProfileTab();

  void _openQrActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _QrCommunitySheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('nestfind-profile'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
      children: [
        const Center(
          child: Text(
            'DienChan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111111),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 15),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Hồ Chí Minh, Việt Nam',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.notifications_none_rounded, size: 18),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _openQrActions(context),
              child: const Icon(Icons.qr_code_2_rounded, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: Color(0xFF6E7175)),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tìm hồ sơ, nhóm hoặc bạn bè...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8A8F95)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFE7F4EC),
          child: Icon(Icons.person_rounded, color: Color(0xFF1E4F38), size: 34),
        ),
        const SizedBox(height: 10),
        const Text(
          'Lê Hoàng Anh',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        const SizedBox(height: 2),
        const Text(
          'Học viên · Điều phối cộng đồng Diện Chẩn',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7D847F), fontSize: 12),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _NestMiniStat(value: '128', label: 'Bạn bè'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NestMiniStat(value: '24', label: 'Nhóm'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NestMiniStat(value: '4.9', label: 'Đánh giá'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileOptionCard(
          icon: Icons.qr_code_2_rounded,
          title: 'QR của tôi',
          subtitle: 'Bấm để hiển thị mã cho người khác quét',
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (_) =>
                  const Wrap(children: [_MyQrCard(isExpandedSheet: true)]),
            );
          },
        ),
        const _ProfileOptionCard(
          icon: Icons.edit_note_rounded,
          title: 'Chỉnh sửa hồ sơ',
          subtitle: 'Cập nhật thông tin cá nhân',
        ),
        const _ProfileOptionCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Bảo mật và riêng tư',
          subtitle: 'Mật khẩu, xác thực, sinh trắc học',
        ),
        const _ProfileOptionCard(
          icon: Icons.logout_rounded,
          title: 'Đăng xuất',
          subtitle: 'Thoát tài khoản hiện tại',
          danger: true,
        ),
      ],
    );
  }
}

class _NestMiniStat extends StatelessWidget {
  const _NestMiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6E7175)),
          ),
        ],
      ),
    );
  }
}

class _NightHomeTab extends StatelessWidget {
  const _NightHomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('night-home'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      children: [
        Text(
          'Diện Chẩn Đêm',
          style: TextStyle(
            color: Color(0xFFE8F2ED),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Theo dõi phác đồ và nhắc giờ buổi tối',
          style: TextStyle(color: Color(0xFF9FB2A8)),
        ),
        SizedBox(height: 12),
        _NightPanel(child: _NightStatRow()),
        SizedBox(height: 10),
        _NightPanel(
          child: _NightListItem(
            icon: Icons.self_improvement_rounded,
            title: 'Phác đồ an thần',
            subtitle: 'Huyệt 26 + 124 · 8 phút',
            tail: '21:00',
          ),
        ),
        SizedBox(height: 10),
        _NightPanel(
          child: _NightListItem(
            icon: Icons.warning_amber_rounded,
            title: 'Cảnh báo an toàn',
            subtitle: 'Nếu triệu chứng kéo dài, cần đi khám',
            tail: 'Lưu ý',
          ),
        ),
        SizedBox(height: 10),
        _NightPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin và tài liệu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              _NightListItem(
                icon: Icons.menu_book_rounded,
                title: 'Tài liệu 64 huyệt diện chẩn',
                subtitle: 'Mô tả vị trí, cách day ấn và lưu ý',
                tail: 'PDF',
              ),
              SizedBox(height: 8),
              _NightListItem(
                icon: Icons.fact_check_outlined,
                title: 'Quy trình tự chăm sóc 6 bước',
                subtitle: 'Làm ấm - dò điểm - day ấn - theo dõi',
                tail: 'Guide',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NightLookupTab extends StatelessWidget {
  const _NightLookupTab();

  void _openVoiceSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF26352F),
              child: Icon(
                Icons.mic_none_rounded,
                color: Color(0xFFA4D46E),
                size: 34,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Đang nghe để tra cứu...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('night-lookup'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      children: [
        const Text(
          'Tra cứu',
          style: TextStyle(
            color: Color(0xFFE8F2ED),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _NightPanel(
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF9FB2A8)),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nhập triệu chứng, bệnh, huyệt...',
                    hintStyle: TextStyle(color: Color(0xFF83958B)),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openVoiceSearch(context),
                icon: const Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFFA4D46E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _NightPanel(
          child: _NightListItem(
            icon: Icons.nightlight_round,
            title: 'Mất ngủ',
            subtitle: 'Phác đồ an thần buổi tối',
            tail: '+8 phút',
          ),
        ),
        const SizedBox(height: 8),
        const _NightPanel(
          child: _NightListItem(
            icon: Icons.psychology_alt_outlined,
            title: 'Đau đầu dữ dội',
            subtitle: 'Phác đồ giảm đau khẩn',
            tail: '+6 phút',
          ),
        ),
      ],
    );
  }
}

class _NightCommunityTab extends StatelessWidget {
  const _NightCommunityTab();

  void _openQrActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _QrCommunitySheet(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('night-community'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Kết nối',
                style: TextStyle(
                  color: Color(0xFFE8F2ED),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _openQrActions(context),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFFA4D46E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ConnectCard(
          isPrimary: true,
          title: 'Mã kết nối bạn bè',
          connectionId: 'ID-BAN-LEHOANGANH-5690',
          expiry: '07/30',
          status: 'Bạn bè: 128',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _ConnectionListPage(
                title: 'Danh sách bạn bè',
                accent: Color(0xFFD7F266),
                icon: Icons.person_outline_rounded,
                items: [
                  'Nguyễn Anh Tuấn · ID-BAN-TUAN-3021',
                  'Trần Minh Hà · ID-BAN-HA-7742',
                  'Lê Thanh Vy · ID-BAN-VY-6180',
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ConnectCard(
          isPrimary: false,
          title: 'Mã nhóm chuyên gia',
          connectionId: 'ID-NHOM-CHUYENGIA-3421',
          expiry: '12/28',
          status: 'Nhóm: 24',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _ConnectionListPage(
                title: 'Danh sách nhóm cộng đồng',
                accent: Color(0xFF1F4C39),
                icon: Icons.groups_2_outlined,
                items: [
                  'Nhóm Mất ngủ chủ động · ID-NHOM-MATNGU-01',
                  'Nhóm Đau đầu phản chiếu · ID-NHOM-DAUDAU-08',
                  'Nhóm Hỗ trợ người mới · ID-NHOM-MOI-15',
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NightProfileTab extends StatelessWidget {
  const _NightProfileTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('night-profile'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFF2A3A33),
          child: Icon(Icons.person_rounded, color: Color(0xFFA4D46E), size: 30),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lê Hoàng Anh',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFE8F2ED),
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Học viên · Điều phối cộng đồng Diện Chẩn',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9FB2A8), fontSize: 12),
        ),
        const SizedBox(height: 12),
        _ProfileOptionCard(
          icon: Icons.qr_code_2_rounded,
          title: 'QR của tôi',
          subtitle: 'Bấm để hiển thị mã cho người khác quét',
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (_) =>
                  const Wrap(children: [_MyQrCard(isExpandedSheet: true)]),
            );
          },
        ),
        const _ProfileOptionCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Bảo mật và riêng tư',
          subtitle: 'Mật khẩu, xác thực, sinh trắc học',
        ),
      ],
    );
  }
}

class _NightPanel extends StatelessWidget {
  const _NightPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2420),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _NightListItem extends StatelessWidget {
  const _NightListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFA4D46E), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9FB2A8),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          tail,
          style: const TextStyle(
            color: Color(0xFFA4D46E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NightStatRow extends StatelessWidget {
  const _NightStatRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _NightStat(value: '12', label: 'Phác đồ'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _NightStat(value: '64', label: 'Huyệt'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _NightStat(value: '03', label: 'Nhắc giờ'),
        ),
      ],
    );
  }
}

class _NightStat extends StatelessWidget {
  const _NightStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF24322C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFA4D46E),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9FB2A8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FinflowHomeTab extends StatelessWidget {
  const _FinflowHomeTab();

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('finflow-home'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFB55238),
              foregroundColor: Colors.white,
              child: Text('L'),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào', style: TextStyle(color: Color(0xFF8A6E5C))),
                  Text(
                    'Lê Hoàng Anh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openNotifications(context),
              child: ValueListenableBuilder<int>(
                valueListenable: notificationUnreadCount,
                builder: (context, unread, _) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2, right: 2),
                    child: Badge(
                      isLabelVisible: unread > 0,
                      backgroundColor: const Color(0xFFE53935),
                      label: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E4D4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Color(0xFFB55238),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _HomeBannerCarousel(),
        const SizedBox(height: 14),
        const _LegacyEntryPanel(),
        const SizedBox(height: 12),
        const _HomeServicePanel(),
      ],
    );
  }
}

class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  int _filter = 0; // 0 all, 1 unread, 2 read

  final List<_NotificationItem> _items = [
    const _NotificationItem(
      title: 'Phác đồ an thần buổi tối',
      subtitle: 'Huyệt 26 + 124',
      amount: '+8 phút',
      positive: true,
      unread: true,
    ),
    const _NotificationItem(
      title: 'Nhật ký giảm đau đầu',
      subtitle: 'Đã lưu bệnh án sáng nay',
      amount: '+1 bản ghi',
      positive: true,
      unread: true,
    ),
    const _NotificationItem(
      title: 'Cảnh báo an toàn',
      subtitle: 'Nếu đau kéo dài cần đi khám',
      amount: '-Lưu ý',
      positive: false,
      unread: true,
    ),
    const _NotificationItem(
      title: 'Nhắc giờ day huyệt',
      subtitle: 'Đã hoàn thành lịch 20:00',
      amount: 'Đã xem',
      positive: true,
      unread: false,
    ),
    const _NotificationItem(
      title: 'Cập nhật nhóm cộng đồng',
      subtitle: 'Nhóm Mất ngủ chủ động có bài mới',
      amount: 'Đã xem',
      positive: true,
      unread: false,
    ),
  ];

  List<_NotificationItem> get _visible {
    if (_filter == 1) return _items.where((e) => e.unread).toList();
    if (_filter == 2) return _items.where((e) => !e.unread).toList();
    return _items;
  }

  int get _unreadCount => _items.where((e) => e.unread).length;

  void _syncUnreadBadge() {
    notificationUnreadCount.value = _unreadCount;
  }

  void _markRead(int indexInVisible) {
    final item = _visible[indexInVisible];
    final realIndex = _items.indexOf(item);
    if (realIndex < 0 || !_items[realIndex].unread) return;
    setState(() {
      _items[realIndex] = _items[realIndex].copyWith(unread: false);
    });
    _syncUnreadBadge();
  }

  void _markAllRead() {
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(unread: false);
      }
    });
    _syncUnreadBadge();
  }

  @override
  void initState() {
    super.initState();
    _syncUnreadBadge();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _visible.where((e) => e.unread).toList();
    final read = _visible.where((e) => !e.unread).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C1A12),
        elevation: 0,
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: Color(0xFF1D5C45),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              _NotiFilterChip(
                label: 'Tất cả',
                selected: _filter == 0,
                onTap: () => setState(() => _filter = 0),
              ),
              const SizedBox(width: 8),
              _NotiFilterChip(
                label: 'Chưa đọc ($_unreadCount)',
                selected: _filter == 1,
                onTap: () => setState(() => _filter = 1),
              ),
              const SizedBox(width: 8),
              _NotiFilterChip(
                label: 'Đã đọc',
                selected: _filter == 2,
                onTap: () => setState(() => _filter = 2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_filter != 2) ...[
            const Text(
              'Chưa đọc',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (unread.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Không có thông báo chưa đọc',
                  style: TextStyle(color: Color(0xFF74867A), fontSize: 13),
                ),
              )
            else
              ...unread.asMap().entries.map((entry) {
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationTile(
                    item: item,
                    onTap: () => _markRead(_visible.indexOf(item)),
                  ),
                );
              }),
          ],
          if (_filter != 1) ...[
            if (_filter == 0) const SizedBox(height: 6),
            const Text(
              'Đã đọc',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (read.isEmpty)
              const Text(
                'Chưa có thông báo đã đọc',
                style: TextStyle(color: Color(0xFF74867A), fontSize: 13),
              )
            else
              ...read.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationTile(item: item),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.positive,
    required this.unread,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool positive;
  final bool unread;

  _NotificationItem copyWith({bool? unread}) {
    return _NotificationItem(
      title: title,
      subtitle: subtitle,
      amount: amount,
      positive: positive,
      unread: unread ?? this.unread,
    );
  }
}

class _NotiFilterChip extends StatelessWidget {
  const _NotiFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB55238) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFB55238) : const Color(0xFFE4D4C4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF8A6E5C),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, this.onTap});

  final _NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.unread ? const Color(0xFFEFF7F0) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.unread
                  ? const Color(0xFFBFD9C6)
                  : const Color(0xFFE8ECE9),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.positive
                      ? const Color(0xFFF4E4D4)
                      : const Color(0xFFFCEBEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.positive
                      ? Icons.arrow_upward_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: item.positive
                      ? const Color(0xFFB55238)
                      : const Color(0xFFD24E49),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (item.unread) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF74867A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.unread ? 'Chưa đọc' : 'Đã đọc',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.unread
                            ? const Color(0xFF1D5C45)
                            : const Color(0xFF8A9490),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item.amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: item.positive
                        ? const Color(0xFF1D5C45)
                        : const Color(0xFFD24E49),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel();

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  static const _banners = [
    (
      title: 'Khóa 48 · Offline',
      subtitle: 'Khai giảng 20/9 · 19:00–21:00',
      imageAsset: 'assets/images/course_poster.jpg',
      target: 'course',
    ),
    (
      title: 'Lớp học thực hành',
      subtitle: 'Cộng đồng học viên Diện Chẩn',
      imageAsset: 'assets/images/course_classroom.jpg',
      target: 'community',
    ),
    (
      title: 'Thầy Bùi Minh Tâm',
      subtitle: 'Chứng chỉ Massage Therapy · VCMT',
      imageAsset: 'assets/images/cert_bui_minh_tam.jpg',
      target: 'teacher',
    ),
  ];

  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openBanner(BuildContext context, String target) {
    switch (target) {
      case 'course':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _LegacyModulePage(module: dienChanModules[4]),
          ),
        );
      case 'community':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: finflowPreset.background,
              appBar: AppBar(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2C1A12),
                title: const Text(
                  'Kết nối',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              body: CommunityTab(preset: finflowPreset),
            ),
          ),
        );
      case 'teacher':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _IntroArticleDetailPage(article: _introArticles[2]),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, i) {
              final banner = _banners[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openBanner(context, banner.target),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            banner.imageAsset,
                            fit: BoxFit.cover,
                            alignment: i == 0
                                ? const Alignment(0.2, 0.05)
                                : Alignment.center,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x11000000), Color(0x99000000)],
                                stops: [0.42, 1],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  banner.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  banner.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFE8F2ED),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFB55238)
                    : const Color(0xFFE4D4C4),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HomeServicePanel extends StatelessWidget {
  const _HomeServicePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dịch vụ',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _LegacyModuleTile(module: dienChanModules[3]),
          const SizedBox(height: 8),
          _LegacyModuleTile(module: dienChanModules[4]),
          const SizedBox(height: 8),
          _LegacyActionTile(
            title: 'Giới thiệu',
            subtitle: 'Bài viết về Diện Chẩn',
            icon: Icons.menu_book_rounded,
            colors: const [Color(0xFFC24E1A), Color(0xFFE88940)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _IntroArticlesPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyActionTile extends StatelessWidget {
  const _LegacyActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8F7F2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroArticle {
  const _IntroArticle({
    required this.title,
    required this.imageAsset,
    required this.paragraphs,
    this.extraImageAssets = const [],
  });

  final String title;
  final String imageAsset;
  final List<String> extraImageAssets;
  final List<String> paragraphs;
}

const _introArticles = [
  _IntroArticle(
    title: 'Giới thiệu về Diện Chẩn',
    imageAsset: 'assets/images/intro_dien_chan_logo.jpg',
    paragraphs: [
      'Diện Chẩn Điều Khiển Liệu Pháp là một phương pháp chữa bệnh đột phá của Việt Nam, được nhà nghiên cứu Bùi Quốc Châu phát hiện ngày 26/03/1980 tại Sài Gòn.',
      'Suốt chiều dài lịch sử, Diện Chẩn Điều Khiển Liệu Pháp của nhà nghiên cứu Bùi Quốc Châu vẫn thường bị nhầm lẫn là một phương pháp kế thừa từ Đông Y hay châm cứu. Thực ra nền tảng của nó là sự kết hợp giữa tinh hoa y thuật Việt, triết lý Phật giáo và văn minh phương Đông, đặc biệt gắn với văn hóa dân gian và ngôn ngữ Việt.',
      'Đầu thập niên 1980, nhà nghiên cứu Bùi Quốc Châu đã kiểm chứng hiệu quả phương pháp khi thực hành trên người nghiện ma túy tại Trung tâm phục hồi Bình Triệu (TP.HCM).',
      'Diện Chẩn là phương pháp chẩn đoán và chữa trị trên diện và khắp toàn thân mà không dùng thuốc (Đông/Tây), máy móc hay châm kim. Người làm Diện Chẩn dùng các dụng cụ chuyên biệt như que dò, lăn, búa gõ... để tác động lên các điểm huyệt một cách an toàn, tiết kiệm.',
      'Diện Chẩn dựa trên hai thuyết chính: Thuyết Phản Chiếu và Thuyết Đồng Ứng.',
      'Thuyết Phản Chiếu cho rằng diện (gương mặt) là tấm gương phản chiếu trạng thái tâm lý và bệnh lý của con người qua sắc da, nốt ruồi, mụn...',
      'Thuyết Đồng Ứng nêu rằng những bộ phận có hình dạng hoặc tên gọi tương đồng trong cơ thể có sự liên hệ với nhau (ví dụ “sống mũi” và “sống lưng”).',
      'Gần 40 năm hình thành và phát triển, Diện Chẩn Điều Khiển Liệu Pháp của nhà sáng chế Bùi Quốc Châu hướng tới giúp người bệnh trở thành “lương y của chính mình” bằng cách tự chăm sóc sức khỏe hằng ngày.',
    ],
  ),
  _IntroArticle(
    title: 'Thầy Bùi Quốc Châu',
    imageAsset: 'assets/images/intro_bui_quoc_chau.jpg',
    paragraphs: [
      'Thầy Bùi Quốc Châu là nhà sáng lập phương pháp Diện Chẩn Điều Khiển Liệu Pháp – một hướng tiếp cận dưỡng sinh và chữa trị mang dấu ấn Việt Nam.',
      'Ông dành nhiều năm nghiên cứu, thực hành và truyền bá Diện Chẩn, xây dựng hệ thống điểm huyệt, đồ hình phản chiếu và quy trình tự chăm sóc an toàn cho cộng đồng.',
      'Triết lý của thầy nhấn mạnh tính thực tiễn: dễ học, dễ làm, có thể áp dụng hỗ trợ sức khỏe tại nhà với dụng cụ đơn giản, đồng thời luôn khuyến cáo khi triệu chứng kéo dài cần đến cơ sở y tế.',
    ],
  ),
  _IntroArticle(
    title: 'Thầy Bùi Minh Tâm',
    imageAsset: 'assets/images/intro_bui_minh_tam.jpg',
    extraImageAssets: ['assets/images/cert_bui_minh_tam.jpg'],
    paragraphs: [
      'Thầy Bùi Minh Tâm kế thừa và lan tỏa Diện Chẩn thực hành, giúp học viên tiếp cận phương pháp theo hướng dễ hiểu, dễ ứng dụng trong đời sống.',
      'Các bài giảng và hướng dẫn thực hành tập trung vào nhận diện dấu hiệu trên diện, chọn phác đồ phù hợp và thao tác dụng cụ đúng cách.',
      'Ngoài đào tạo, thầy còn gắn với cộng đồng học viên Diện Chẩn để chia sẻ kinh nghiệm tự chăm sóc và hỗ trợ lẫn nhau trong quá trình luyện tập.',
      'Tháng 6/2026, thầy hoàn thành workshop massage thực hành 14 giờ tại Vancouver College of Massage Therapy (VCMT), bổ sung nền tảng trị liệu bằng tay cho các buổi dạy Diện Chẩn.',
    ],
  ),
];

class _IntroArticlesPage extends StatelessWidget {
  const _IntroArticlesPage();

  static const _orange = Color(0xFFE85D1C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Giới thiệu về Diện Chẩn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: _introArticles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = _introArticles[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _IntroArticleDetailPage(article: article),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _orange, width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 168,
                      child: ColoredBox(
                        color: const Color(0xFFFFF8F3),
                        child: Image.asset(
                          article.imageAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      color: _orange,
                      child: Text(
                        article.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IntroArticleDetailPage extends StatelessWidget {
  const _IntroArticleDetailPage({required this.article});

  final _IntroArticle article;

  static const _orange = Color(0xFFE85D1C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: Text(
          article.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: Colors.white,
              child: Image.asset(article.imageAsset, fit: BoxFit.contain),
            ),
          ),
          ...article.extraImageAssets.map(
            (asset) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: Colors.white,
                  child: Image.asset(asset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...article.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                p,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF222222),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DienChanModule {
  const _DienChanModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

const dienChanModules = [
  _DienChanModule(
    title: 'Huyệt',
    subtitle: 'Tra cứu huyệt',
    icon: Icons.face_retouching_natural,
    colors: [Color(0xFFA65B38), Color(0xFFD4895A)],
  ),
  _DienChanModule(
    title: 'Phác Đồ',
    subtitle: 'Phác đồ điều trị bệnh',
    icon: Icons.assignment_turned_in_outlined,
    colors: [Color(0xFFB44A3C), Color(0xFFD77862)],
  ),
  _DienChanModule(
    title: 'Đồ Hình',
    subtitle: 'Tra cứu đồ hình',
    icon: Icons.image_search_rounded,
    colors: [Color(0xFF9C6B2E), Color(0xFFD4A054)],
  ),
  _DienChanModule(
    title: 'Dụng Cụ',
    subtitle: 'Mua sắm dụng cụ Diện Chẩn',
    icon: Icons.shopping_cart_outlined,
    colors: [Color(0xFFB56A32), Color(0xFFE08A4A)],
  ),
  _DienChanModule(
    title: 'Khóa Học Diện Chẩn',
    subtitle: 'Liên hệ đăng ký học',
    icon: Icons.school_outlined,
    colors: [Color(0xFFB55238), Color(0xFFE07B50)],
  ),
];

class _LegacyEntryPanel extends StatelessWidget {
  const _LegacyEntryPanel();

  void _openLookup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFFFF5EB),
          body: SafeArea(
            child: LookupTab(
              preset: finflowPreset,
              onBackHome: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  void _openCommunity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: finflowPreset.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2C1A12),
            title: const Text(
              'Kết nối',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: CommunityTab(preset: finflowPreset),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các chức năng chính',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _LegacyActionTile(
            title: 'Tra cứu',
            subtitle: 'Triệu chứng, bệnh và phác đồ',
            icon: Icons.manage_search_rounded,
            colors: const [Color(0xFF8C3D28), Color(0xFFC45C3A)],
            onTap: () => _openLookup(context),
          ),
          const SizedBox(height: 8),
          _LegacyActionTile(
            title: 'Kết nối',
            subtitle: 'Bạn bè và nhóm cộng đồng',
            icon: Icons.groups_2_outlined,
            colors: const [Color(0xFFC17A2D), Color(0xFFE0A04A)],
            onTap: () => _openCommunity(context),
          ),
          const SizedBox(height: 8),
          ...dienChanModules
              .where(
                (module) =>
                    module.title != 'Dụng Cụ' &&
                    module.title != 'Khóa Học Diện Chẩn',
              )
              .map(
                (module) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LegacyModuleTile(module: module),
                ),
              ),
        ],
      ),
    );
  }
}

class _LegacyModuleTile extends StatelessWidget {
  const _LegacyModuleTile({required this.module});

  final _DienChanModule module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _LegacyModulePage(module: module)),
      ),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: module.colors),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(module.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8F7F2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyModulePage extends StatelessWidget {
  const _LegacyModulePage({
    required this.module,
    this.startWithAllPoints = false,
  });

  final _DienChanModule module;
  final bool startWithAllPoints;

  @override
  Widget build(BuildContext context) {
    final isHuyet = module.title == 'Huyệt';
    Widget body;
    switch (module.title) {
      case 'Huyệt':
        body = _AcupointLookupPageBody(startWithAllPoints: startWithAllPoints);
        break;
      case 'Phác Đồ':
        body = const _ProtocolListPageBody();
        break;
      case 'Đồ Hình':
        body = const _ReflexMapListPageBody();
        break;
      case 'Dụng Cụ':
        body = const _ToolCatalogPageBody();
        break;
      default:
        body = const _CourseSignupPageBody();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE6),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(isHuyet ? 'Tra Huyệt' : module.title),
        backgroundColor: module.colors.first,
        actions: isHuyet
            ? null
            : [
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
      ),
      body: body,
    );
  }
}

class _AcupointLookupPageBody extends StatefulWidget {
  const _AcupointLookupPageBody({this.startWithAllPoints = false});

  final bool startWithAllPoints;

  @override
  State<_AcupointLookupPageBody> createState() =>
      _AcupointLookupPageBodyState();
}

class _AcupointLookupPageBodyState extends State<_AcupointLookupPageBody> {
  static const _accent = Color(0xFFA65B38);
  static const _diagrams = ['H. 1', 'H. 2', 'H. 3'];

  bool _showPoints = false;
  bool _showGrid = true;
  bool _showAllLabeled = false;
  int _diagramIndex = 0;
  String _query = '';
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    if (widget.startWithAllPoints || userFacePhotoBytes.value != null) {
      _showPoints = true;
      _showAllLabeled = true;
      _showGrid = true;
    }
  }

  List<_Acupoint> get _points => _dienChanAcupointCatalog;
  List<_Acupoint> get _matched {
    final q = _query.trim();
    if (q.isEmpty) return _points;
    return _points.where((p) => p.code.contains(q)).toList();
  }

  void _showAllOnFace() {
    setState(() {
      _query = '';
      _selectedCode = null;
      _showPoints = true;
      _showAllLabeled = true;
      _showGrid = true;
    });
  }

  void _openFindKeypad() {
    var buffer = _query;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void append(String value) {
              setSheetState(() => buffer = '$buffer$value');
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0D7DD),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            buffer.isEmpty ? 'Nhập số huyệt...' : buffer,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: buffer.isEmpty
                                  ? const Color(0xFF8A949A)
                                  : _accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 2.1,
                          children: [
                            for (final key in [
                              '1',
                              '2',
                              '3',
                              '4',
                              '5',
                              '6',
                              '7',
                              '8',
                              '9',
                              ',',
                              '0',
                              '⌫',
                            ])
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accent,
                                  side: const BorderSide(color: _accent),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  if (key == '⌫') {
                                    if (buffer.isEmpty) return;
                                    setSheetState(
                                      () => buffer = buffer.substring(
                                        0,
                                        buffer.length - 1,
                                      ),
                                    );
                                    return;
                                  }
                                  if (key == ',') return;
                                  append(key);
                                },
                                child: Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accent,
                                  side: const BorderSide(color: _accent),
                                ),
                                child: const Text('Đóng'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _query = buffer;
                                    _selectedCode = buffer.isEmpty
                                        ? null
                                        : buffer;
                                    _showPoints = true;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,
                                ),
                                child: const Text('Tìm'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setSheetState(() => buffer = ''),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accent,
                                  side: const BorderSide(color: _accent),
                                ),
                                child: const Text('Xóa'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.list_alt_rounded, color: _accent),
                title: const Text('Xem tất cả huyệt'),
                subtitle: Text('${_points.length} huyệt trên gương mặt'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAllOnFace();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.bookmark_add_outlined,
                  color: _accent,
                ),
                title: const Text('Thêm vào yêu thích'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined, color: _accent),
                title: const Text('Thêm ghi chú huyệt'),
                onTap: () => Navigator.pop(sheetContext),
              ),
              ListTile(
                leading: const Icon(Icons.assignment_add, color: _accent),
                title: const Text('Thêm vào phác đồ'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _Acupoint? selected;
    if (_selectedCode != null) {
      for (final p in _points) {
        if (p.code == _selectedCode) {
          selected = p;
          break;
        }
      }
    } else {
      final matched = _matched;
      if (matched.length == 1) selected = matched.first;
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accent.withValues(alpha: 0.25)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: ValueListenableBuilder<Uint8List?>(
                  valueListenable: userFacePhotoBytes,
                  builder: (context, faceBytes, _) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (faceBytes != null)
                          Image.memory(
                            faceBytes,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          )
                        else
                          Image.asset(
                            _diagramIndex == 1
                                ? 'assets/images/dienchan_face_side.png'
                                : 'assets/images/dienchan_face_front.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        CustomPaint(
                          painter: _FaceOverlayPainter(
                            showGrid: _showGrid,
                            showPoints: _showPoints,
                            showLabels: _showAllLabeled,
                            points: _points,
                            highlightCode: selected?.code,
                            useSideView: _diagramIndex == 1,
                          ),
                        ),
                        if (faceBytes != null)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  userFacePhotoBytes.value = null;
                                  setState(() {});
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Ảnh mẫu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFA65B38),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (userFacePhotoBytes.value != null)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đang dùng gương mặt thật · phủ lưới & huyệt trực quan',
                style: TextStyle(
                  color: Color(0xFFA65B38),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        if (_showAllLabeled)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đang hiển thị tất cả huyệt trên gương mặt',
                style: TextStyle(
                  color: Color(0xFFA65B38),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Huyệt ${selected.code} · ${selected.subtitle}',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            border: Border(top: BorderSide(color: _accent, width: 1.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _HuyetSquareButton(
                    icon: Icons.keyboard_double_arrow_left_rounded,
                    onTap: () => setState(() {
                      _diagramIndex =
                          (_diagramIndex - 1 + _diagrams.length) %
                          _diagrams.length;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _HuyetSquareButton(
                    icon: Icons.keyboard_double_arrow_right_rounded,
                    onTap: () => setState(() {
                      _diagramIndex = (_diagramIndex + 1) % _diagrams.length;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _HuyetSquareButton(
                    label: _diagrams[_diagramIndex],
                    onTap: () {},
                  ),
                  const Spacer(),
                  _HuyetSquareButton(
                    icon: _diagramIndex == 1
                        ? Icons.sentiment_satisfied_alt_outlined
                        : Icons.face_retouching_natural,
                    onTap: () => setState(() {
                      _diagramIndex = _diagramIndex == 1 ? 0 : 1;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _HuyetSquareButton(
                    icon: _showGrid
                        ? Icons.grid_off_rounded
                        : Icons.grid_on_rounded,
                    onTap: () => setState(() => _showGrid = !_showGrid),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _HuyetActionButton(
                      icon: Icons.center_focus_strong_rounded,
                      label: 'Tìm Huyệt',
                      onTap: () {
                        setState(() => _showAllLabeled = false);
                        _openFindKeypad();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HuyetActionButton(
                      label: 'Thêm...',
                      onTap: _openAddSheet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PointTone { blue, red, green }

class _Acupoint {
  const _Acupoint(this.code, this.pos, this.subtitle, this.tone);

  final String code;
  final Offset pos;
  final String subtitle;
  final _PointTone tone;

  /// Quy đổi sang mặt nghiêng (nhìn nghiêng trái: mũi bên trái khung, tai bên phải khung).
  ///
  /// Không giữ “trái/phải màn hình” như mặt trước: khi xoay nghiêng, điểm gần
  /// mép mặt (tai, quai hàm) đi về phía sau đầu → nằm bên phải ảnh nghiêng;
  /// điểm đường giữa (mũi, miệng) nằm gần phía trước → bên trái ảnh nghiêng.
  Offset get sidePos {
    final fromMid = (pos.dx - 0.5).abs().clamp(0.0, 0.5);
    // 0 giữa mặt → gần sống mũi (~0.24); 0.5 mép → gần tai (~0.72)
    final x = (0.24 + fromMid * 0.96).clamp(0.16, 0.80);
    final y = (0.12 + pos.dy * 0.78).clamp(0.12, 0.88);
    return Offset(x, y);
  }
}

/// Danh mục huyệt dùng chung cho Tra Huyệt + chi tiết bệnh.
const _dienChanAcupointCatalog = <_Acupoint>[
  _Acupoint(
    '0',
    Offset(0.50, 0.50),
    'Điểm gốc / cân bằng chung',
    _PointTone.green,
  ),
  _Acupoint('1', Offset(0.50, 0.56), 'Đầu mũi', _PointTone.green),
  _Acupoint('3', Offset(0.50, 0.42), 'Giữa hai mắt', _PointTone.blue),
  _Acupoint('6', Offset(0.48, 0.46), 'Gần sống mũi', _PointTone.blue),
  _Acupoint('7', Offset(0.50, 0.30), 'Giữa trán', _PointTone.blue),
  _Acupoint('8', Offset(0.50, 0.62), 'Nhân trung', _PointTone.red),
  _Acupoint('11', Offset(0.38, 0.48), 'Dưới mắt trái', _PointTone.blue),
  _Acupoint('12', Offset(0.62, 0.48), 'Dưới mắt phải', _PointTone.blue),
  _Acupoint('14', Offset(0.50, 0.72), 'Cằm giữa', _PointTone.red),
  _Acupoint('16', Offset(0.50, 0.76), 'Dưới cằm', _PointTone.blue),
  _Acupoint('17', Offset(0.34, 0.58), 'Khẩu góc trái', _PointTone.blue),
  _Acupoint('18', Offset(0.66, 0.58), 'Khẩu góc phải', _PointTone.blue),
  _Acupoint('19', Offset(0.40, 0.44), 'Hỗ trợ xoang mũi', _PointTone.blue),
  _Acupoint('22', Offset(0.45, 0.34), 'Trán trái', _PointTone.blue),
  _Acupoint('23', Offset(0.55, 0.34), 'Trán phải', _PointTone.blue),
  _Acupoint('26', Offset(0.50, 0.36), 'An thần, giữa trán', _PointTone.blue),
  _Acupoint('29', Offset(0.24, 0.44), 'Tai trước trái', _PointTone.red),
  _Acupoint('30', Offset(0.76, 0.44), 'Tai trước phải', _PointTone.red),
  _Acupoint('34', Offset(0.36, 0.38), 'Góc lông mày trái', _PointTone.blue),
  _Acupoint('37', Offset(0.30, 0.40), 'Thái dương trái', _PointTone.red),
  _Acupoint('38', Offset(0.70, 0.40), 'Thái dương phải', _PointTone.red),
  _Acupoint('39', Offset(0.32, 0.48), 'Gần góc hàm trái', _PointTone.blue),
  _Acupoint('41', Offset(0.33, 0.66), 'Hàm trái', _PointTone.blue),
  _Acupoint('42', Offset(0.67, 0.66), 'Hàm phải', _PointTone.blue),
  _Acupoint('50', Offset(0.28, 0.50), 'Gò má trái', _PointTone.blue),
  _Acupoint('51', Offset(0.72, 0.50), 'Gò má phải', _PointTone.blue),
  _Acupoint('55', Offset(0.46, 0.66), 'Môi trên trái', _PointTone.blue),
  _Acupoint('56', Offset(0.54, 0.66), 'Môi trên phải', _PointTone.blue),
  _Acupoint('60', Offset(0.42, 0.60), 'Má giữa trái', _PointTone.blue),
  _Acupoint('61', Offset(0.60, 0.44), 'Hỗ trợ xoang mũi', _PointTone.blue),
  _Acupoint('62', Offset(0.58, 0.60), 'Má giữa phải', _PointTone.blue),
  _Acupoint('65', Offset(0.42, 0.54), 'Cánh mũi trái', _PointTone.blue),
  _Acupoint('66', Offset(0.58, 0.54), 'Cánh mũi phải', _PointTone.blue),
  _Acupoint('73', Offset(0.50, 0.78), 'Cằm dưới', _PointTone.blue),
  _Acupoint('85', Offset(0.26, 0.58), 'Gần quai hàm trái', _PointTone.red),
  _Acupoint('87', Offset(0.74, 0.58), 'Gần quai hàm phải', _PointTone.red),
  _Acupoint('88', Offset(0.27, 0.34), 'Thái dương cao trái', _PointTone.blue),
  _Acupoint('89', Offset(0.73, 0.34), 'Thái dương cao phải', _PointTone.blue),
  _Acupoint('91', Offset(0.44, 0.28), 'Trán góc trái', _PointTone.blue),
  _Acupoint('92', Offset(0.56, 0.28), 'Trán góc phải', _PointTone.blue),
  _Acupoint('103', Offset(0.64, 0.38), 'Góc lông mày phải', _PointTone.blue),
  _Acupoint('105', Offset(0.40, 0.62), 'Má dưới trái', _PointTone.blue),
  _Acupoint('106', Offset(0.60, 0.62), 'Má dưới phải', _PointTone.blue),
  _Acupoint('113', Offset(0.48, 0.52), 'Sống mũi trái', _PointTone.blue),
  _Acupoint('114', Offset(0.52, 0.52), 'Sống mũi phải', _PointTone.blue),
  _Acupoint('124', Offset(0.50, 0.48), 'Điều hòa thần kinh', _PointTone.red),
  _Acupoint('126', Offset(0.36, 0.52), 'Gò má trong trái', _PointTone.blue),
  _Acupoint('127', Offset(0.64, 0.52), 'Gò má trong phải', _PointTone.blue),
  _Acupoint('143', Offset(0.31, 0.56), 'Má ngang trái', _PointTone.blue),
  _Acupoint('144', Offset(0.69, 0.56), 'Má ngang phải', _PointTone.blue),
  _Acupoint('156', Offset(0.45, 0.58), 'Gần nhân trung trái', _PointTone.blue),
  _Acupoint('160', Offset(0.50, 0.68), 'Môi dưới giữa', _PointTone.red),
  _Acupoint('175', Offset(0.43, 0.74), 'Cằm lệch trái', _PointTone.blue),
  _Acupoint('176', Offset(0.57, 0.74), 'Cằm lệch phải', _PointTone.blue),
  _Acupoint('180', Offset(0.52, 0.34), 'Trán giữa lệch phải', _PointTone.blue),
  _Acupoint('184', Offset(0.38, 0.70), 'Hàm dưới trái', _PointTone.blue),
  _Acupoint('201', Offset(0.22, 0.52), 'Gần tai trái', _PointTone.blue),
  _Acupoint('202', Offset(0.78, 0.52), 'Gần tai phải', _PointTone.blue),
  _Acupoint('209', Offset(0.44, 0.42), 'Gần gốc mũi trái', _PointTone.blue),
  _Acupoint('217', Offset(0.48, 0.32), 'Trán an thần', _PointTone.blue),
  _Acupoint('220', Offset(0.47, 0.40), 'Góc mắt trong trái', _PointTone.blue),
  _Acupoint('221', Offset(0.53, 0.40), 'Góc mắt trong phải', _PointTone.blue),
  _Acupoint('267', Offset(0.54, 0.46), 'Gần sống mũi phải', _PointTone.blue),
  _Acupoint('275', Offset(0.36, 0.46), 'Dưới ổ mắt trái', _PointTone.blue),
  _Acupoint('300', Offset(0.35, 0.30), 'Chân tóc trái', _PointTone.blue),
  _Acupoint('301', Offset(0.65, 0.30), 'Chân tóc phải', _PointTone.blue),
  _Acupoint('312', Offset(0.62, 0.70), 'Hàm dưới phải', _PointTone.blue),
  _Acupoint('342', Offset(0.50, 0.20), 'Đỉnh trán', _PointTone.blue),
  _Acupoint('467', Offset(0.56, 0.42), 'Gần gốc mũi phải', _PointTone.blue),
  _Acupoint('480', Offset(0.50, 0.24), 'Tham chiếu trán', _PointTone.blue),
  _Acupoint('491', Offset(0.46, 0.38), 'Gần lông mày giữa', _PointTone.blue),
];

_Acupoint? _acupointByCode(String code) {
  for (final p in _dienChanAcupointCatalog) {
    if (p.code == code) return p;
  }
  return null;
}

List<_Acupoint> _acupointsForCodes(Iterable<String> codes) {
  final result = <_Acupoint>[];
  for (final code in codes) {
    final known = _acupointByCode(code);
    result.add(
      known ??
          _Acupoint(
            code,
            const Offset(0.50, 0.50),
            'Huyệt $code',
            _PointTone.blue,
          ),
    );
  }
  return result;
}

class _HuyetSquareButton extends StatelessWidget {
  const _HuyetSquareButton({this.icon, this.label, required this.onTap});

  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: label == null ? 40 : 52,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFFA65B38),
          side: const BorderSide(color: Color(0xFFA65B38)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: icon != null
            ? Icon(icon, size: 20)
            : Text(
                label ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _HuyetActionButton extends StatelessWidget {
  const _HuyetActionButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFA65B38),
          side: const BorderSide(color: Color(0xFFA65B38), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  const _FaceOverlayPainter({
    required this.showGrid,
    required this.showPoints,
    required this.showLabels,
    required this.points,
    this.highlightCode,
    this.useSideView = false,
  });

  final bool showGrid;
  final bool showPoints;
  final bool showLabels;
  final List<_Acupoint> points;
  final String? highlightCode;
  final bool useSideView;

  Color _toneColor(_PointTone tone) {
    switch (tone) {
      case _PointTone.red:
        return const Color(0xFFE53E4E);
      case _PointTone.green:
        return const Color(0xFF2E9B57);
      case _PointTone.blue:
        return const Color(0xFF5DA9C4);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF7DB7CB)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    if (showGrid) {
      for (var i = 1; i < 14; i++) {
        final x = size.width * i / 14;
        canvas.drawLine(Offset(x, 10), Offset(x, size.height - 22), gridPaint);
      }
      for (var i = 1; i < 16; i++) {
        final y = size.height * i / 16;
        canvas.drawLine(Offset(14, y), Offset(size.width - 28, y), gridPaint);
      }

      final axisStyle = TextStyle(
        color: const Color(0xFFA65B38).withValues(alpha: 0.85),
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
      );
      const hLabels = [
        'L',
        'K',
        'H',
        'G',
        'E',
        'D',
        'C',
        'B',
        'A',
        '0',
        'A',
        'B',
        'C',
        'D',
        'E',
        'G',
        'H',
        'K',
        'L',
      ];
      for (var i = 0; i < hLabels.length; i++) {
        final tp = TextPainter(
          text: TextSpan(text: hLabels[i], style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = size.width * (i + 0.5) / hLabels.length - tp.width / 2;
        tp.paint(canvas, Offset(x, size.height - 14));
      }
      const vLabels = [
        'O',
        'I',
        'II',
        'III',
        'IV',
        'V',
        'VI',
        'VII',
        'VIII',
        'IX',
        'X',
        'XI',
        'XII',
      ];
      for (var i = 0; i < vLabels.length; i++) {
        final tp = TextPainter(
          text: TextSpan(text: vLabels[i], style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final y =
            size.height * (i + 0.7) / (vLabels.length + 1) - tp.height / 2;
        tp.paint(canvas, Offset(size.width - 24, y));
      }
    }

    if (!showPoints) return;

    final ringPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final point in points) {
      final pos = useSideView ? point.sidePos : point.pos;
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final isHighlight = highlightCode == point.code;
      final color = isHighlight
          ? const Color(0xFFE53E4E)
          : _toneColor(point.tone);
      final radius = isHighlight ? 4.8 : (showLabels ? 3.2 : 3.8);
      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(center, radius, ringPaint);

      if (showLabels || isHighlight) {
        final label = TextPainter(
          text: TextSpan(
            text: point.code,
            style: TextStyle(
              color: const Color(0xFF1A2A32),
              fontSize: showLabels ? 8.5 : 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(center.dx + 4.5, center.dy - label.height - 1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FaceOverlayPainter oldDelegate) {
    return oldDelegate.showGrid != showGrid ||
        oldDelegate.showPoints != showPoints ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.points != points ||
        oldDelegate.highlightCode != highlightCode ||
        oldDelegate.useSideView != useSideView;
  }
}

class _ProtocolListPageBody extends StatefulWidget {
  const _ProtocolListPageBody();

  @override
  State<_ProtocolListPageBody> createState() => _ProtocolListPageBodyState();
}

class _ProtocolListPageBodyState extends State<_ProtocolListPageBody> {
  String _filter = 'Tất cả';
  final _protocols = const [
    ('Bồi bổ, thông khí huyết', 'Cơ bản', '8 huyệt'),
    ('Bộ bổ âm huyết', 'Cơ bản', '6 huyệt'),
    ('Bộ giáng khí', 'Nâng Cao', '7 huyệt'),
    ('Bộ thăng khí', 'Nâng Cao', '9 huyệt'),
    ('Bộ điều hòa', 'Cơ bản', '5 huyệt'),
    ('Chống mệt', 'Cơ bản', '4 huyệt'),
    ('Chống co cơ', 'Nâng Cao', '6 huyệt'),
    ('Cấp cứu ngất xỉu', 'Nâng Cao', '3 huyệt'),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _protocols
        .where((p) => _filter == 'Tất cả' || p.$2 == _filter)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        const _LegacyHeaderCard(
          title: 'Phác Đồ',
          subtitle: 'Phác đồ điều trị bệnh',
          icon: Icons.assignment_turned_in_outlined,
          colors: [Color(0xFFB44A3C), Color(0xFFD77862)],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['Tất cả', 'Cơ bản', 'Nâng Cao'].map((filter) {
            return ChoiceChip(
              label: Text(filter),
              selected: _filter == filter,
              onSelected: (_) => setState(() => _filter = filter),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        ...visible.map(
          (p) => _LegacyInfoTile(
            title: p.$1,
            subtitle: '${p.$2} · ${p.$3}',
            trailing: 'Chi tiết',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ProtocolDetailPage(title: p.$1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProtocolDetailPage extends StatelessWidget {
  const _ProtocolDetailPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const steps = ['Huyệt 26', 'Huyệt 124', 'Huyệt 19', 'Huyệt 61'];
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF4),
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SafetyNoteCard(),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
            (entry) => _LegacyInfoTile(
              title: 'Bước ${entry.key + 1}: ${entry.value}',
              subtitle: 'Day ấn 30-60 giây, theo dõi cảm giác vùng mặt',
              trailing: 'Xem huyệt',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _LegacyModulePage(module: dienChanModules.first),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflexMapListPageBody extends StatelessWidget {
  const _ReflexMapListPageBody();

  static const _maps = [
    (
      title: 'Phản Chiếu Ngoại Vi Trắc Diện',
      asset: 'assets/images/do_hinh_trac_dien.png',
    ),
    (
      title: 'Phản Chiếu Ngoại Vi Trên Đầu (Z)',
      asset: 'assets/images/do_hinh_tren_dau.png',
    ),
    (
      title: 'Phản Chiếu Tai và Gáy',
      asset: 'assets/images/do_hinh_tai_gay.png',
    ),
    (
      title: 'Phản Chiếu Lưng Trên Mặt',
      asset: 'assets/images/do_hinh_lung_tren_mat.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: _maps
          .map(
            (map) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCE7E1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 168,
                    child: ColoredBox(
                      color: const Color(0xFFF7FBFA),
                      child: Image.asset(
                        map.asset,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFF71BFB5),
                    child: Text(
                      map.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ToolCatalogPageBody extends StatelessWidget {
  const _ToolCatalogPageBody();

  @override
  Widget build(BuildContext context) {
    const tools = [
      'Que dò + lăn cầu lạng đồng',
      'Que dò + lăn cầu lạng sừng',
      'Lăn cầu lạng 2 đầu',
      'Lăn hít nhỏ',
      'Cào mini',
      'Búa gõ diện chẩn',
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: tools.length,
      itemBuilder: (_, i) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE7E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Transform.rotate(
                    angle: i.isEven ? -0.25 : 0.25,
                    child: Container(
                      width: 96,
                      height: 14,
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? const Color(0xFF2E2E2E)
                            : const Color(0xFF8B5B35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                tools[i].toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseSignupPageBody extends StatelessWidget {
  const _CourseSignupPageBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/course_poster.jpg',
            fit: BoxFit.fitWidth,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Học Diện Chẩn – Chăm sức khỏe – Chủ động cuộc sống',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF7A1D1D),
          ),
        ),
        const SizedBox(height: 12),
        const _CourseSessionCard(
          month: '9',
          monthLabel: 'THÁNG',
          title: 'KHÓA 48 - OFFLINE',
          accent: Color(0xFFB42318),
          rows: [
            (Icons.event_outlined, 'Ngày khai giảng: 20/9'),
            (
              Icons.calendar_today_outlined,
              'Thời gian học: Thứ 2,3,4,5,6,7, CN',
            ),
            (Icons.schedule_outlined, 'Giờ học: 19:00 – 21:00'),
            (
              Icons.location_on_outlined,
              '16 Kỳ Con, Phường Cầu Kiệu (Quận Phú Nhuận cũ)',
            ),
            (Icons.payments_outlined, 'Học phí: 7 triệu'),
          ],
        ),
        const SizedBox(height: 10),
        const _CourseSessionCard(
          month: '11',
          monthLabel: 'THÁNG',
          title: 'KHÓA 49 - ONLINE',
          accent: Color(0xFF1D4E89),
          rows: [
            (Icons.event_outlined, 'Ngày khai giảng: Dự kiến đầu tháng'),
            (Icons.calendar_today_outlined, 'Thời gian học: Thứ 3,5,7'),
            (Icons.schedule_outlined, 'Giờ học: 20:30 – 22:30'),
            (Icons.payments_outlined, 'Học phí: 7 triệu'),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/course_classroom.jpg',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Buổi học thực hành tại Trung tâm Diện Chẩn Bùi Minh Tâm',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: Color(0xFF65736C)),
        ),
        const SizedBox(height: 12),
        _LegacyInfoTile(
          title: 'Giảng viên: Thầy Bùi Minh Tâm',
          subtitle: 'Trung Tâm Diện Chẩn Thực Hành Bùi Minh Tâm',
          trailing: 'Giới thiệu',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _IntroArticleDetailPage(article: _introArticles[2]),
            ),
          ),
        ),
        const _LegacyInfoTile(
          title: 'Điện thoại: 0903.888.397',
          subtitle: 'Facebook: Buiminhtam dien chan',
          trailing: 'Gọi',
        ),
        const _LegacyInfoTile(
          title: 'Trung Tâm Diện Chẩn Việt Y Đạo Bùi Quốc Châu',
          subtitle: '16 Kỳ Con, Phường Cầu Kiệu, TP. Hồ Chí Minh',
          trailing: 'Bản đồ',
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            labelText: 'Họ tên học viên',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã ghi nhận đăng ký khóa học')),
            );
          },
          icon: const Icon(Icons.send_rounded),
          label: const Text('Đăng ký khóa học'),
        ),
      ],
    );
  }
}

class _CourseSessionCard extends StatelessWidget {
  const _CourseSessionCard({
    required this.month,
    required this.monthLabel,
    required this.title,
    required this.accent,
    required this.rows,
  });

  final String month;
  final String monthLabel;
  final String title;
  final Color accent;
  final List<(IconData, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: accent,
            child: Row(
              children: [
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        month,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(row.$1, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            row.$2,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyHeaderCard extends StatelessWidget {
  const _LegacyHeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFEAF7F2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyInfoTile extends StatelessWidget {
  const _LegacyInfoTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          style: const TextStyle(
            color: Color(0xFF1D5C45),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SafetyNoteCard extends StatelessWidget {
  const _SafetyNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD58A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFC27A00)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nếu triệu chứng dữ dội hoặc kéo dài, cần liên hệ chuyên môn y tế.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF728076))),
    );
  }
}

class _FinflowLookupTab extends StatefulWidget {
  const _FinflowLookupTab({required this.preset, this.onBackHome});

  final DemoPreset preset;
  final VoidCallback? onBackHome;

  @override
  State<_FinflowLookupTab> createState() => _FinflowLookupTabState();
}

class _FinflowLookupTabState extends State<_FinflowLookupTab> {
  String? _selectedCategoryId;

  void _openVoiceSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 6),
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFE7F4EC),
                child: Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFF1E4F38),
                  size: 34,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Đang nghe để tra cứu...',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              SizedBox(height: 4),
              Text(
                'Ví dụ: "Mất ngủ", "Đau đầu", "Huyệt 26"',
                style: TextStyle(color: Color(0xFF728076)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final diseases = _selectedCategoryId == null
        ? _dienChanDiseases
        : _dienChanDiseases
              .where((d) => d.categoryId == _selectedCategoryId)
              .toList();

    return ListView(
      key: const ValueKey('finflow-lookup'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Row(
          children: [
            Material(
              color: const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return;
                  }
                  widget.onBackHome?.call();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Color(0xFF8A4B22),
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Tra cứu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF5C3317),
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E4),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 18,
                    color: Color(0xFF8A4B22),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: Color(0xFFE35B56),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0D2B0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFFB56B2E)),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập triệu chứng, bệnh, huyệt...',
                    hintStyle: TextStyle(color: Color(0xFFA88A6E)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tra cứu bằng giọng nói',
                onPressed: () => _openVoiceSearch(context),
                icon: const Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFFC45C26),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0C9A0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh mục phổ biến',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF7A3E16),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dienChanCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _dienChanCategories[index];
                    final selected = _selectedCategoryId == category.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = selected ? null : category.id;
                        });
                      },
                      child: Container(
                        width: 148,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: category.colors),
                          borderRadius: BorderRadius.circular(16),
                          border: selected
                              ? Border.all(
                                  color: const Color(0xFFFFE08A),
                                  width: 2.4,
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                category.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              category.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${category.count} công thức',
                              style: const TextStyle(
                                color: Color(0xFFFFF1E0),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8C9A8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedCategoryId == null
                        ? 'Khám phá'
                        : _dienChanCategories
                              .firstWhere((c) => c.id == _selectedCategoryId)
                              .title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF7A3E16),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${diseases.length} bệnh',
                    style: const TextStyle(
                      color: Color(0xFFA06A3C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...diseases.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DiseaseProtocolCard(
                    disease: entry.value,
                    colorIndex: entry.key,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiseaseCategory {
  const _DiseaseCategory({
    required this.id,
    required this.title,
    required this.count,
    required this.icon,
    required this.colors,
  });

  final String id;
  final String title;
  final int count;
  final IconData icon;
  final List<Color> colors;
}

class _DiseasePointDetail {
  const _DiseasePointDetail({
    required this.code,
    required this.contraindication,
    required this.effects,
  });

  final String code;
  final String contraindication;
  final List<String> effects;
}

class _DiseaseProtocol {
  const _DiseaseProtocol({
    required this.title,
    required this.categoryId,
    required this.categoryLabel,
    required this.points,
    required this.minutes,
    required this.details,
  });

  final String title;
  final String categoryId;
  final String categoryLabel;
  final List<String> points;
  final int minutes;
  final List<_DiseasePointDetail> details;
}

const _dienChanCategories = [
  _DiseaseCategory(
    id: 'tong-quat',
    title: 'Tổng quát',
    count: 6,
    icon: Icons.person_outline_rounded,
    colors: [Color(0xFFC45C26), Color(0xFFE08A4F)],
  ),
  _DiseaseCategory(
    id: 'co-xuong-khop',
    title: 'Hệ cơ xương khớp',
    count: 4,
    icon: Icons.accessibility_new_rounded,
    colors: [Color(0xFFB5483D), Color(0xFFD9766A)],
  ),
  _DiseaseCategory(
    id: 'da',
    title: 'Hệ da',
    count: 3,
    icon: Icons.spa_outlined,
    colors: [Color(0xFFD17A45), Color(0xFFE8A56B)],
  ),
  _DiseaseCategory(
    id: 'tmh',
    title: 'Tai mũi họng',
    count: 4,
    icon: Icons.hearing_rounded,
    colors: [Color(0xFFC4782A), Color(0xFFE0A04A)],
  ),
  _DiseaseCategory(
    id: 'ho-hap',
    title: 'Hệ hô hấp',
    count: 3,
    icon: Icons.air_rounded,
    colors: [Color(0xFFB85F2E), Color(0xFFD98B55)],
  ),
  _DiseaseCategory(
    id: 'nhan-khoa',
    title: 'Nhãn khoa',
    count: 3,
    icon: Icons.visibility_outlined,
    colors: [Color(0xFFC9A227), Color(0xFFE0C05A)],
  ),
  _DiseaseCategory(
    id: 'tieu-hoa',
    title: 'Hệ tiêu hóa',
    count: 4,
    icon: Icons.restaurant_rounded,
    colors: [Color(0xFFA86B2D), Color(0xFFC9944F)],
  ),
  _DiseaseCategory(
    id: 'than-kinh',
    title: 'Hệ thần kinh',
    count: 5,
    icon: Icons.psychology_alt_outlined,
    colors: [Color(0xFFA34B2E), Color(0xFFC7734F)],
  ),
  _DiseaseCategory(
    id: 'man-tinh',
    title: 'Bệnh mãn tính',
    count: 3,
    icon: Icons.monitor_heart_outlined,
    colors: [Color(0xFF8B5A2B), Color(0xFFB07A45)],
  ),
  _DiseaseCategory(
    id: 'tim-mach',
    title: 'Hệ tim mạch',
    count: 3,
    icon: Icons.favorite_outline_rounded,
    colors: [Color(0xFFC43D3D), Color(0xFFE06A5A)],
  ),
  _DiseaseCategory(
    id: 'tiet-nieu',
    title: 'Hệ tiết niệu sinh dục',
    count: 3,
    icon: Icons.water_drop_outlined,
    colors: [Color(0xFFB06A3C), Color(0xFFD0925F)],
  ),
];

const _dienChanDiseases = [
  _DiseaseProtocol(
    title: 'Giải phóng ứ trệ',
    categoryId: 'tong-quat',
    categoryLabel: 'Tổng quát',
    points: ['19', '14', '275', '61', '39', '26', '312', '184', '85', '87'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '19',
        contraindication: 'Huyết áp không ổn định, tránh day mạnh',
        effects: ['Điều khí', 'Giảm ứ trệ', 'Hỗ trợ lưu thông'],
      ),
      _DiseasePointDetail(
        code: '26',
        contraindication: 'Người huyết áp thấp nên day nhẹ',
        effects: ['An thần', 'Hạ áp nhẹ', 'Giảm căng thẳng'],
      ),
      _DiseasePointDetail(
        code: '61',
        contraindication: 'Vùng da viêm nhiễm tại chỗ',
        effects: ['Giảm đau', 'Thông kinh lạc', 'Hỗ trợ phục hồi'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Mệt mỏi toàn thân',
    categoryId: 'tong-quat',
    categoryLabel: 'Tổng quát',
    points: ['0', '22', '62', '1', '37', '50', '19'],
    minutes: 10,
    details: [
      _DiseasePointDetail(
        code: '0',
        contraindication: 'Không day khi sốt cao',
        effects: ['Tăng lực', 'Cân bằng chung', 'Hỗ trợ phục hồi'],
      ),
      _DiseasePointDetail(
        code: '37',
        contraindication: 'Tránh nếu vùng má bị tổn thương',
        effects: ['Bổ khí huyết', 'Giảm mệt', 'Ổn định tinh thần'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Đau cổ vai gáy',
    categoryId: 'co-xuong-khop',
    categoryLabel: 'Hệ cơ xương khớp',
    points: ['41', '87', '85', '60', '34', '61', '14', '16'],
    minutes: 9,
    details: [
      _DiseasePointDetail(
        code: '41',
        contraindication: 'Không day khi có chấn thương cấp',
        effects: ['Giảm đau', 'Nới cơ', 'Thông vùng cổ gáy'],
      ),
      _DiseasePointDetail(
        code: '85',
        contraindication: 'Da bị kích ứng tại điểm',
        effects: ['Giảm cứng cơ', 'Hỗ trợ vận động'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Đau khớp gối',
    categoryId: 'co-xuong-khop',
    categoryLabel: 'Hệ cơ xương khớp',
    points: ['50', '38', '156', '37', '39', '0', '61'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '50',
        contraindication: 'Viêm khớp cấp có sưng nóng đỏ',
        effects: ['Giảm đau khớp', 'Hỗ trợ lưu thông'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Mụn viêm',
    categoryId: 'da',
    categoryLabel: 'Hệ da',
    points: ['127', '85', '29', '38', '41', '50'],
    minutes: 7,
    details: [
      _DiseasePointDetail(
        code: '127',
        contraindication: 'Không day trực tiếp lên nốt mụn đang mưng',
        effects: ['Kháng viêm', 'Giải độc nhẹ', 'Làm sạch'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Nám da',
    categoryId: 'da',
    categoryLabel: 'Hệ da',
    points: ['19', '37', '50', '14', '0', '26'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '19',
        contraindication: 'Da nhạy cảm, day rất nhẹ',
        effects: ['Hỗ trợ sắc da', 'Điều hòa khí huyết mặt'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Viêm xoang',
    categoryId: 'tmh',
    categoryLabel: 'Tai mũi họng',
    points: ['209', '491', '467', '61', '38', '17'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '61',
        contraindication: 'Chảy máu mũi đang diễn tiến',
        effects: ['Thông xoang', 'Giảm nghẹt', 'Hỗ trợ hô hấp'],
      ),
      _DiseasePointDetail(
        code: '17',
        contraindication: 'Nhiễm trùng cấp vùng mũi họng',
        effects: ['Kháng viêm', 'Giảm đau xoang'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Ù tai cấp tính',
    categoryId: 'tmh',
    categoryLabel: 'Tai mũi họng',
    points: ['3', '61', '103', '124', '34', '16', '0'],
    minutes: 7,
    details: [
      _DiseasePointDetail(
        code: '3',
        contraindication: 'Chóng mặt nặng cần đi khám',
        effects: ['Giảm ù tai', 'Ổn định thăng bằng'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Ho kéo dài',
    categoryId: 'ho-hap',
    categoryLabel: 'Hệ hô hấp',
    points: ['37', '38', '41', '17', '50', '19'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '38',
        contraindication: 'Ho ra máu hoặc khó thở nặng',
        effects: ['Giảm ho', 'Tan đàm', 'Hỗ trợ phổi'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Viêm họng',
    categoryId: 'ho-hap',
    categoryLabel: 'Hệ hô hấp',
    points: ['17', '61', '37', '127', '85'],
    minutes: 6,
    details: [
      _DiseasePointDetail(
        code: '17',
        contraindication: 'Sốt cao trên 39°C',
        effects: ['Kháng viêm', 'Giảm đau họng'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Mỏi mắt',
    categoryId: 'nhan-khoa',
    categoryLabel: 'Nhãn khoa',
    points: ['1', '61', '3', '26', '14', '16'],
    minutes: 6,
    details: [
      _DiseasePointDetail(
        code: '1',
        contraindication: 'Viêm kết mạc cấp',
        effects: ['Giảm mỏi mắt', 'Làm dịu thị lực'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Đau đầu do mắt',
    categoryId: 'nhan-khoa',
    categoryLabel: 'Nhãn khoa',
    points: ['124', '34', '3', '61', '26'],
    minutes: 7,
    details: [
      _DiseasePointDetail(
        code: '124',
        contraindication: 'Đau đầu dữ dội đột ngột cần cấp cứu',
        effects: ['Giảm đau đầu', 'An thần nhẹ'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Đầy bụng khó tiêu',
    categoryId: 'tieu-hoa',
    categoryLabel: 'Hệ tiêu hóa',
    points: ['41', '50', '19', '39', '37'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '41',
        contraindication: 'Đau bụng dữ kèm nôn ói',
        effects: ['Hỗ trợ tiêu hóa', 'Giảm đầy hơi'],
      ),
      _DiseasePointDetail(
        code: '50',
        contraindication: 'Loét dạ dày đang chảy máu',
        effects: ['Điều vị', 'Ổn định tiêu hóa'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Rối loạn tiêu hóa',
    categoryId: 'tieu-hoa',
    categoryLabel: 'Hệ tiêu hóa',
    points: ['37', '39', '50', '19', '0', '14'],
    minutes: 9,
    details: [
      _DiseasePointDetail(
        code: '37',
        contraindication: 'Tiêu chảy cấp mất nước',
        effects: ['Điều hòa ruột', 'Giảm khó chịu'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Stress',
    categoryId: 'than-kinh',
    categoryLabel: 'Hệ thần kinh',
    points: ['17', '6', '19', '180', '26', '124'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '17',
        contraindication: 'Nhiễm trùng hoặc khối u ở dạ dày',
        effects: ['Kháng viêm', 'Chống dị ứng', 'Cầm máu', 'Tan đàm'],
      ),
      _DiseasePointDetail(
        code: '6',
        contraindication: 'Day nhẹ nếu da nhạy cảm',
        effects: ['An thần', 'Giảm căng thẳng'],
      ),
      _DiseasePointDetail(
        code: '19',
        contraindication: 'Kiểm tra chống chỉ định trước khi day',
        effects: ['Điều khí', 'Ổn định thần kinh'],
      ),
      _DiseasePointDetail(
        code: '180',
        contraindication: 'Không thay thế điều trị tâm lý chuyên khoa',
        effects: ['Thư giãn', 'Hỗ trợ giấc ngủ'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Mất ngủ',
    categoryId: 'than-kinh',
    categoryLabel: 'Hệ thần kinh',
    points: ['124', '34', '267', '217', '51', '26', '16'],
    minutes: 10,
    details: [
      _DiseasePointDetail(
        code: '124',
        contraindication: 'Không dùng thay thuốc khi mất ngủ bệnh lý nặng',
        effects: ['An thần', 'Hỗ trợ vào giấc'],
      ),
      _DiseasePointDetail(
        code: '34',
        contraindication: 'Day nhẹ trước khi ngủ',
        effects: ['Giảm kích thích', 'Ổn định thần kinh'],
      ),
      _DiseasePointDetail(
        code: '51',
        contraindication: 'Người huyết áp thấp nên theo dõi',
        effects: ['Hạ nhiệt nhẹ', 'Thư giãn'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Suy nhược thần kinh',
    categoryId: 'than-kinh',
    categoryLabel: 'Hệ thần kinh',
    points: ['127', '37', '1', '50', '73', '106', '103'],
    minutes: 12,
    details: [
      _DiseasePointDetail(
        code: '127',
        contraindication: 'Huyết áp cao: dùng huyệt hạ áp trước',
        effects: ['Bổ thần kinh', 'Giảm mệt trí óc'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Tiểu đường hỗ trợ',
    categoryId: 'man-tinh',
    categoryLabel: 'Bệnh mãn tính',
    points: ['19', '37', '50', '0', '26', '61'],
    minutes: 10,
    details: [
      _DiseasePointDetail(
        code: '19',
        contraindication: 'Không thay thế thuốc và chế độ điều trị của bác sĩ',
        effects: ['Hỗ trợ điều hòa', 'Giảm mệt'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Gout hỗ trợ',
    categoryId: 'man-tinh',
    categoryLabel: 'Bệnh mãn tính',
    points: ['41', '85', '50', '38', '61', '0'],
    minutes: 9,
    details: [
      _DiseasePointDetail(
        code: '41',
        contraindication: 'Cơn gout cấp sưng nóng đỏ: hạn chế day mạnh',
        effects: ['Giảm đau', 'Hỗ trợ lưu thông'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Cao huyết áp',
    categoryId: 'tim-mach',
    categoryLabel: 'Hệ tim mạch',
    points: ['26', '51', '156', '55', '14', '16', '8'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '26',
        contraindication: 'Theo dõi huyết áp; cấp cứu nếu quá cao',
        effects: ['Hỗ trợ hạ áp', 'An thần'],
      ),
      _DiseasePointDetail(
        code: '51',
        contraindication: 'Không bỏ thuốc huyết áp đang dùng',
        effects: ['Ổn định mạch', 'Giảm căng'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Hồi hộp đánh trống ngực',
    categoryId: 'tim-mach',
    categoryLabel: 'Hệ tim mạch',
    points: ['8', '60', '37', '39', '26', '124'],
    minutes: 7,
    details: [
      _DiseasePointDetail(
        code: '8',
        contraindication: 'Đau ngực lan tay trái cần khám ngay',
        effects: ['An thần', 'Ổn định nhịp'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Tiểu đêm nhiều lần',
    categoryId: 'tiet-nieu',
    categoryLabel: 'Hệ tiết niệu sinh dục',
    points: ['26', '61', '3', '51', '17', '0'],
    minutes: 8,
    details: [
      _DiseasePointDetail(
        code: '26',
        contraindication: 'Nhiễm khuẩn tiết niệu cấp cần điều trị y khoa',
        effects: ['Hỗ trợ thận', 'Giảm tiểu đêm'],
      ),
    ],
  ),
  _DiseaseProtocol(
    title: 'Đau bụng kinh',
    categoryId: 'tiet-nieu',
    categoryLabel: 'Hệ tiết niệu sinh dục',
    points: ['19', '37', '50', '39', '0', '14'],
    minutes: 9,
    details: [
      _DiseasePointDetail(
        code: '19',
        contraindication: 'Đau bất thường ngoài chu kỳ cần khám',
        effects: ['Giảm đau', 'Điều hòa khí huyết'],
      ),
    ],
  ),
];

class _DiseaseProtocolCard extends StatelessWidget {
  const _DiseaseProtocolCard({required this.disease, required this.colorIndex});

  final _DiseaseProtocol disease;
  final int colorIndex;

  static const _palettes = [
    (
      bg: Color(0xFFFFF0E6),
      border: Color(0xFFE8A06A),
      accent: Color(0xFFC45C26),
      pill: Color(0xFFFFE0C8),
    ),
    (
      bg: Color(0xFFFFEBE8),
      border: Color(0xFFE08A82),
      accent: Color(0xFFB5483D),
      pill: Color(0xFFFFD8D2),
    ),
    (
      bg: Color(0xFFFFF3E0),
      border: Color(0xFFE0B06A),
      accent: Color(0xFFC4782A),
      pill: Color(0xFFFFE8C4),
    ),
    (
      bg: Color(0xFFFFF8E4),
      border: Color(0xFFE0C05A),
      accent: Color(0xFFB89620),
      pill: Color(0xFFFFF0C0),
    ),
    (
      bg: Color(0xFFFFEFE6),
      border: Color(0xFFD9A078),
      accent: Color(0xFFA86B2D),
      pill: Color(0xFFFFE0CC),
    ),
    (
      bg: Color(0xFFFFECE4),
      border: Color(0xFFD98B6A),
      accent: Color(0xFFA34B2E),
      pill: Color(0xFFFFDCCF),
    ),
    (
      bg: Color(0xFFF8EEE4),
      border: Color(0xFFC9A07A),
      accent: Color(0xFF8B5A2B),
      pill: Color(0xFFF0DFCE),
    ),
    (
      bg: Color(0xFFFFE8E6),
      border: Color(0xFFE08A8A),
      accent: Color(0xFFC43D3D),
      pill: Color(0xFFFFD4D0),
    ),
    (
      bg: Color(0xFFFFF1E8),
      border: Color(0xFFD9A07A),
      accent: Color(0xFFB06A3C),
      pill: Color(0xFFFFE2D0),
    ),
    (
      bg: Color(0xFFFFF4EC),
      border: Color(0xFFE8A56B),
      accent: Color(0xFFD17A45),
      pill: Color(0xFFFFE6D2),
    ),
    (
      bg: Color(0xFFFFEDE4),
      border: Color(0xFFD98B55),
      accent: Color(0xFFB85F2E),
      pill: Color(0xFFFFDCC4),
    ),
  ];

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DiseaseDetailPage(disease: disease)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[colorIndex % _palettes.length];
    final visible = disease.points.take(8).join(' • ');
    final remaining = disease.points.length - 8;
    final extra = remaining > 0 ? ' ... và $remaining huyệt khác' : '';

    return Material(
      color: palette.bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTap(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                disease.title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                disease.categoryLabel,
                style: TextStyle(
                  color: palette.accent.withValues(alpha: 0.72),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: palette.pill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$visible$extra',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: palette.accent.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${disease.minutes} min',
                    style: TextStyle(
                      color: palette.accent.withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: palette.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiseaseDetailPage extends StatefulWidget {
  const _DiseaseDetailPage({required this.disease});

  final _DiseaseProtocol disease;

  @override
  State<_DiseaseDetailPage> createState() => _DiseaseDetailPageState();
}

class _DiseaseDetailPageState extends State<_DiseaseDetailPage> {
  String? _selectedCode;

  _DiseasePointDetail _detailFor(String code) {
    for (final d in widget.disease.details) {
      if (d.code == code) return d;
    }
    final point = _acupointByCode(code);
    return _DiseasePointDetail(
      code: code,
      contraindication:
          'Kiểm tra chống chỉ định của huyệt $code trước khi sử dụng',
      effects: [
        point?.subtitle ?? 'Huyệt $code trong phác đồ',
        'Day ấn nhẹ 30–60 giây mỗi điểm',
        'Theo dõi cảm giác vùng mặt',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final disease = widget.disease;
    final mapPoints = _acupointsForCodes(disease.points);
    final activeCode = _selectedCode;
    final detail = activeCode == null ? null : _detailFor(activeCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF11221A),
        title: Text(
          disease.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã bắt đầu phiên day huyệt “${disease.title}” (~${disease.minutes} phút)',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1D5C45),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Bắt đầu phiên',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2420),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/images/dienchan_face_front.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      CustomPaint(
                        painter: _FaceOverlayPainter(
                          showGrid: true,
                          showPoints: true,
                          showLabels: true,
                          points: mapPoints,
                          highlightCode: activeCode,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                        child: Image.asset(
                          'assets/images/dienchan_face_side.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      CustomPaint(
                        painter: _FaceOverlayPainter(
                          showGrid: true,
                          showPoints: true,
                          showLabels: true,
                          points: mapPoints,
                          highlightCode: activeCode,
                          useSideView: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PointChip(
                  label: 'Tất cả',
                  selected: _selectedCode == null,
                  onTap: () => setState(() => _selectedCode = null),
                ),
                ...disease.points.map(
                  (code) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _PointChip(
                      label: code,
                      selected: _selectedCode == code,
                      warn: disease.details.any((d) => d.code == code),
                      onTap: () => setState(() => _selectedCode = code),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0B46A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFC8781A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kiểm tra chống chỉ định của mỗi huyệt trước khi sử dụng. Diện Chẩn chỉ hỗ trợ, không thay thế khám chữa bệnh.',
                    style: TextStyle(height: 1.35, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (detail == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${disease.points.length} huyệt trong phác đồ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chọn từng mã huyệt phía trên để xem vị trí trên mặt và thông tin chi tiết.',
                    style: const TextStyle(
                      color: Color(0xFF728076),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: disease.points
                        .map(
                          (code) => ActionChip(
                            label: Text(code),
                            onPressed: () =>
                                setState(() => _selectedCode = code),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        detail.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _acupointByCode(detail.code)?.subtitle ??
                              'Huyệt ${detail.code}',
                          style: const TextStyle(
                            color: Color(0xFF728076),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _LegacyModulePage(
                                module: dienChanModules.first,
                                startWithAllPoints: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Xem'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF0B46A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chống chỉ định',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC8781A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(detail.contraindication),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tác dụng',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ...detail.effects.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(e)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointChip extends StatelessWidget {
  const _PointChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.warn = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFE8EEE9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1D5C45) : const Color(0xFFD5DDD7),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? const Color(0xFF1D5C45)
                    : const Color(0xFF33443B),
              ),
            ),
            if (warn) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: Color(0xFFC8781A),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinflowCommunityTab extends StatefulWidget {
  const _FinflowCommunityTab({required this.preset});

  final DemoPreset preset;

  @override
  State<_FinflowCommunityTab> createState() => _FinflowCommunityTabState();
}

class _FinflowCommunityTabState extends State<_FinflowCommunityTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_CommunityChatMessage> _messages = [
    const _CommunityChatMessage(
      author: 'Cộng đồng Diện Chẩn',
      body:
          'Chào mừng bạn đến khung chat chung. Mọi người có thể đặt câu hỏi, chia sẻ kinh nghiệm và trao đổi nhanh tại đây.',
      time: '09:20',
      isMine: false,
    ),
    const _CommunityChatMessage(
      author: 'Minh Tâm',
      body: 'Có ai có phác đồ nhẹ cho đau vai gáy buổi sáng không ạ?',
      time: '09:24',
      isMine: false,
    ),
    const _CommunityChatMessage(
      author: 'Bạn',
      body:
          'Bạn thử ghi lại vị trí đau và mức độ đau trước, rồi tra nhóm huyệt phản chiếu cổ vai gáy nhé.',
      time: '09:27',
      isMine: true,
    ),
    const _CommunityChatMessage(
      author: 'Hoàng Anh',
      body: 'Mình đã lưu lại, tối nay sẽ thử và cập nhật kết quả.',
      time: '09:31',
      isMine: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    setState(() {
      _messages.add(
        _CommunityChatMessage(
          author: 'Bạn',
          body: text,
          time:
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          isMine: true,
        ),
      );
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('finflow-community'),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF211610),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F266),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Color(0xFF213319),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat cộng đồng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mở cho tất cả người dùng',
                      style: TextStyle(
                        color: Color(0xFFD9CEC5),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E644D),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _CommunityChatBubble(message: _messages[index]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7DCD1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Nhắn tin vào cộng đồng...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: const Color(0xFFB55238),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _sendMessage,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityChatMessage {
  const _CommunityChatMessage({
    required this.author,
    required this.body,
    required this.time,
    required this.isMine,
  });

  final String author;
  final String body;
  final String time;
  final bool isMine;
}

class _CommunityChatBubble extends StatelessWidget {
  const _CommunityChatBubble({required this.message});

  final _CommunityChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bubbleColor = isMine ? const Color(0xFFB55238) : Colors.white;
    final textColor = isMine ? Colors.white : const Color(0xFF2C1A12);
    final mutedColor = isMine
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF8C7B70);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE9D8CA),
              child: Text(
                message.author.substring(0, 1),
                style: const TextStyle(
                  color: Color(0xFF7A3F2C),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 292),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMine) ...[
                    Text(
                      message.author,
                      style: const TextStyle(
                        color: Color(0xFF8B4A31),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message.body,
                    style: TextStyle(
                      color: textColor,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message.time,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({
    required this.isPrimary,
    required this.title,
    required this.connectionId,
    required this.expiry,
    required this.status,
    required this.onTap,
  });

  final bool isPrimary;
  final String title;
  final String connectionId;
  final String expiry;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isPrimary ? const Color(0xFF183C2B) : Colors.white;
    final mutedColor = isPrimary
        ? const Color(0xFF44613A)
        : const Color(0xFFD2E3DB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPrimary
                ? const [Color(0xFFD7F266), Color(0xFFC9EA35)]
                : const [Color(0xFF1F4C39), Color(0xFF2E644D)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 12)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: textColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'DIỆN CHẨN',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              connectionId,
              style: TextStyle(
                color: textColor,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Hiệu lực\n$expiry',
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionListPage extends StatelessWidget {
  const _ConnectionListPage({
    required this.title,
    required this.accent,
    required this.icon,
    required this.items,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: const Color(0xFFF6FAF4),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Icon(icon, size: 17, color: const Color(0xFF1E4F38)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FinflowProfileTab extends StatelessWidget {
  const _FinflowProfileTab({required this.preset});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('finflow-profile'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        const SizedBox(height: 6),
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFE7F4EC),
          child: CircleAvatar(
            radius: 31,
            backgroundColor: Color(0xFF2B5E47),
            child: Icon(Icons.person_rounded, size: 34, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Lê Hoàng Anh',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        const SizedBox(height: 3),
        const Text(
          'lehoanganh@email.com',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7D847F), fontSize: 12),
        ),
        const SizedBox(height: 12),
        const _ProfileStatStrip(),
        const SizedBox(height: 12),
        const _ProfileOptionCard(
          icon: Icons.edit_note_rounded,
          title: 'Chỉnh sửa hồ sơ',
          subtitle: 'Cập nhật thông tin cá nhân',
        ),
        const _ProfileOptionCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Bảo mật và riêng tư',
          subtitle: 'Mật khẩu, xác thực, sinh trắc học',
        ),
        const _ProfileOptionCard(
          icon: Icons.medication_liquid_outlined,
          title: 'Thông báo',
          subtitle: 'Quản lý nhắc giờ và cảnh báo',
        ),
        const _ProfileOptionCard(
          icon: Icons.support_agent_rounded,
          title: 'Trợ giúp và hỗ trợ',
          subtitle: 'Câu hỏi thường gặp và liên hệ',
        ),
        const _ProfileOptionCard(
          icon: Icons.logout_rounded,
          title: 'Đăng xuất',
          subtitle: 'Thoát tài khoản hiện tại',
          danger: true,
        ),
      ],
    );
  }
}

class _ProfileStatStrip extends StatelessWidget {
  const _ProfileStatStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF214A35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _ProfileStatItem(
              icon: Icons.self_improvement_rounded,
              value: '48',
              label: 'Buổi day huyệt',
            ),
          ),
          Expanded(
            child: _ProfileStatItem(
              icon: Icons.manage_search_rounded,
              value: '284',
              label: 'Lượt tra cứu',
            ),
          ),
          Expanded(
            child: _ProfileStatItem(
              icon: Icons.bookmark_rounded,
              value: '12',
              label: 'Phác đồ lưu',
            ),
          ),
        ],
      ),
    );
  }
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({this.isExpandedSheet = false});

  final bool isExpandedSheet;

  @override
  Widget build(BuildContext context) {
    if (isExpandedSheet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCDD3CD),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'QR của tôi',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 4),
              const Text(
                'Đưa mã này để người khác quét và kết nối cộng đồng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF7C8480),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FAF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE9E0)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 116,
                  color: Color(0xFF1E4F38),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ID: DC-LEHOANGANH-1024',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.4,
                  color: Color(0xFF2B5E47),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE9E0)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 56,
              color: Color(0xFF1E4F38),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR của tôi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                SizedBox(height: 3),
                Text(
                  'Đưa mã này để người khác quét và kết nối cộng đồng.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7C8480),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ID: DC-LEHOANGANH-1024',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: Color(0xFF2B5E47),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD7F266), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD7F266),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFA9C0B2), fontSize: 11),
        ),
      ],
    );
  }
}

class _ProfileOptionCard extends StatelessWidget {
  const _ProfileOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = danger
        ? const Color(0xFFE05A58)
        : const Color(0xFF17221C);
    final iconBg = danger ? const Color(0xFFFFEEEE) : const Color(0xFFF2F6EF);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 18, color: titleColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7C8480),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A9290)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.preset});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: preset.cardGradient),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            preset.subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preset.description,
            style: const TextStyle(color: Color(0xFFEAF3F0), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.preset});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    final isDark = preset.scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2420) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.mic_none),
          hintText: 'Nhập triệu chứng, huyệt, bệnh...',
        ),
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  const _FlowLine({required this.preset});

  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    final activeBg = preset.scheme.primary.withValues(alpha: 0.2);

    Widget step(String text, bool active) {
      return Expanded(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: preset.scheme.primary.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Row(
      children: [
        step('Triệu chứng', true),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right),
        const SizedBox(width: 6),
        step('Bệnh', false),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right),
        const SizedBox(width: 6),
        step('Phác đồ', false),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon, this.preset);

  final String label;
  final String value;
  final IconData icon;
  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    final isDark = preset.scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2420) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: preset.scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          Text(
            label,
            style: TextStyle(
              color: preset.scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.title,
    required this.desc,
    required this.preset,
  });

  final String title;
  final String desc;
  final DemoPreset preset;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: preset.scheme.brightness == Brightness.dark
            ? const Color(0xFF1A2420)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: preset.scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleListTile extends StatelessWidget {
  const _SimpleListTile({
    required this.title,
    required this.preset,
    this.trailing,
  });

  final String title;
  final DemoPreset preset;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: preset.scheme.brightness == Brightness.dark
            ? const Color(0xFF1A2420)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(trailing ?? Icons.chevron_right),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
    );
  }
}
