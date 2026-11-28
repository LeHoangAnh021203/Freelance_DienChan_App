part of 'main.dart';

const _hotlineDisplay = '0903.888.397';
const _centerAddress = '16 Kỳ Con, Phường Cầu Kiệu, TP. Hồ Chí Minh';
const _disclaimerAcceptedKey = 'medical_disclaimer_v1';

const _medicalDisclaimerVi =
    'Nội dung trong ứng dụng (huyệt, đồ hình, phác đồ, hướng dẫn day ấn) chỉ '
    'nhằm mục đích tham khảo và học tập về phương pháp Diện Chẩn.\n\n'
    'Ứng dụng không phải thiết bị y tế, không chẩn đoán bệnh và không thay thế '
    'việc thăm khám, điều trị của bác sĩ. Không tự ý ngừng thuốc đang dùng.\n\n'
    'Nếu triệu chứng dữ dội, kéo dài hoặc có dấu hiệu nguy hiểm, hãy đến cơ sở '
    'y tế gần nhất.';

const _medicalDisclaimerEn =
    'Content in this app (points, diagrams, protocols, pressing guidance) is '
    'for reference and learning about Dien Chan only.\n\n'
    'This app is not a medical device, does not diagnose conditions, and does '
    'not replace a doctor’s examination or treatment. Do not stop prescribed '
    'medication on your own.\n\n'
    'If symptoms are severe, persistent, or dangerous, seek nearby medical care.';

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
              ? tr(
                  'Không mở được trình gọi điện. Vui lòng gọi $_hotlineDisplay.',
                  'Could not open the phone app. Please call $_hotlineDisplay.',
                )
              : tr('Không mở được liên kết.', 'Could not open the link.'),
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
      title: Text(tr('Lưu ý sức khỏe', 'Health notice')),
      content: SingleChildScrollView(
        child: Text(tr(_medicalDisclaimerVi, _medicalDisclaimerEn)),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(tr('Tôi đã hiểu', 'I understand')),
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
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) {
        return Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: Text(tr('Lưu ý sức khỏe', 'Health notice')),
                subtitle: Text(
                  tr(
                    'Nội dung chỉ mang tính tham khảo',
                    'Reference content only',
                  ),
                ),
                onTap: () => _showMedicalDisclaimer(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(tr('Chính sách quyền riêng tư', 'Privacy policy')),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _openExternal(context, _legalUri('/privacy')),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(tr('Điều khoản sử dụng', 'Terms of use')),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _openExternal(context, _legalUri('/terms')),
              ),
              ListTile(
                leading: const Icon(Icons.call_outlined),
                title: Text(
                  tr(
                    'Gọi hỗ trợ: $_hotlineDisplay',
                    'Call support: $_hotlineDisplay',
                  ),
                ),
                onTap: () => _callHotline(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReflexMapViewerPage extends StatelessWidget {
  const _ReflexMapViewerPage({required this.map});

  final _ReflexMapItem map;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F2EE),
          appBar: AppBar(
            backgroundColor: const Color(0xFF71BFB5),
            foregroundColor: Colors.white,
            title: Text(
              tr('Thông tin đồ hình', 'Diagram information'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Text(
                map.title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(height: 1.2, color: const Color(0xFF71BFB5)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7DED9)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.asset(map.asset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 14),
              ...map.paragraphs.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
              ),
              Text(
                tr(
                  'Nội dung mang tính tham khảo học tập, không thay thế khám chữa bệnh.',
                  'Educational reference only; not a substitute for medical care.',
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Color(0xFF728076),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
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
            Text(
              tr(
                'Dụng cụ được trung tâm cung cấp trực tiếp. Gọi hotline để được '
                'tư vấn cách dùng, giá và đặt mua.',
                'Tools are supplied by the center. Call the hotline for usage '
                'tips, pricing, and orders.',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _callHotline(context);
              },
              icon: const Icon(Icons.call_rounded),
              label: Text(
                tr('Gọi $_hotlineDisplay', 'Call $_hotlineDisplay'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
