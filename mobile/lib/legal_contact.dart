part of 'main.dart';

const _hotlineDisplay = '0903.888.397';
const _centerAddress = '16 Kỳ Con, Phường Cầu Kiệu, TP. Hồ Chí Minh';
const _disclaimerAcceptedKey = 'medical_disclaimer_v1';

const _medicalDisclaimer =
    'Nội dung trong ứng dụng (huyệt, đồ hình, phác đồ, hướng dẫn day ấn) chỉ '
    'nhằm mục đích tham khảo và học tập về phương pháp Diện Chẩn.\n\n'
    'Ứng dụng không phải thiết bị y tế, không chẩn đoán bệnh và không thay thế '
    'việc thăm khám, điều trị của bác sĩ. Không tự ý ngừng thuốc đang dùng.\n\n'
    'Nếu triệu chứng dữ dội, kéo dài hoặc có dấu hiệu nguy hiểm, hãy đến cơ sở '
    'y tế gần nhất.';

/// Privacy policy, terms and account deletion pages are served by the API host.
Uri _legalUri(String path) => Uri.parse('${_api.baseUrl}$path');

Future<void> _openExternal(BuildContext context, Uri uri) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uri.scheme == 'tel'
              ? 'Không mở được trình gọi điện. Vui lòng gọi $_hotlineDisplay.'
              : 'Không mở được liên kết.',
        ),
      ),
    );
  }
}

Future<void> _callHotline(BuildContext context) =>
    _openExternal(context, Uri(scheme: 'tel', path: '0903888397'));

Future<void> _openCenterMap(BuildContext context) => _openExternal(
  context,
  Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': _centerAddress,
  }),
);

Future<void> _showMedicalDisclaimer(
  BuildContext context, {
  bool firstLaunch = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !firstLaunch,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(
        Icons.health_and_safety_outlined,
        color: Color(0xFFB55238),
      ),
      title: const Text('Lưu ý sức khỏe'),
      content: const SingleChildScrollView(child: Text(_medicalDisclaimer)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tôi đã hiểu'),
        ),
      ],
    ),
  );
}

Future<void> _showMedicalDisclaimerIfNeeded(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  if (preferences.get(_disclaimerAcceptedKey) == true || !context.mounted) {
    return;
  }
  await _showMedicalDisclaimer(context, firstLaunch: true);
  await preferences.setBool(_disclaimerAcceptedKey, true);
}

/// Links required by the App Store / Google Play review guidelines.
class _LegalLinksCard extends StatelessWidget {
  const _LegalLinksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Lưu ý sức khỏe'),
            subtitle: const Text('Nội dung chỉ mang tính tham khảo'),
            onTap: () => _showMedicalDisclaimer(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Chính sách quyền riêng tư'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openExternal(context, _legalUri('/privacy')),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Điều khoản sử dụng'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _openExternal(context, _legalUri('/terms')),
          ),
          ListTile(
            leading: const Icon(Icons.call_outlined),
            title: const Text('Gọi hỗ trợ: $_hotlineDisplay'),
            onTap: () => _callHotline(context),
          ),
        ],
      ),
    );
  }
}

class _ReflexMapViewerPage extends StatelessWidget {
  const _ReflexMapViewerPage({required this.title, required this.asset});

  final String title;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(child: Image.asset(asset, fit: BoxFit.contain)),
      ),
    );
  }
}

void _showToolContactSheet(BuildContext context, String tool) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tool,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dụng cụ được trung tâm cung cấp trực tiếp. Gọi hotline để được '
              'tư vấn cách dùng, giá và đặt mua.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _callHotline(context);
              },
              icon: const Icon(Icons.call_rounded),
              label: const Text('Gọi $_hotlineDisplay'),
            ),
          ],
        ),
      ),
    ),
  );
}
