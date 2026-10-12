import 'package:dien_chan_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Dữ liệu cục bộ sai kiểu không làm kẹt màn hình tải', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'profile_full_name': 123,
      'settings_reminders': 'invalid',
    });
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('App mở thẳng Mẫu A vào trang chủ', (tester) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Tra cứu'), findsWidgets);
    expect(find.text('Bản mẫu giao diện Diện Chẩn'), findsNothing);
    expect(find.text('Sử dụng app'), findsNothing);
    expect(find.text('Đăng ký / Đăng nhập'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Khách cần đăng nhập khi mở Kết nối', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CommunityTab(preset: finflowPreset)),
      ),
    );
    expect(find.text('Đăng ký / Đăng nhập'), findsOneWidget);
    expect(
      find.text('Đăng nhập để tham gia cộng đồng Diện Chẩn.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Đăng ký / Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text('Đăng nhập để tham gia cộng đồng Diện Chẩn.'),
      findsOneWidget,
    );
  });

  testWidgets('Hồ sơ khách có nút đăng nhập và không có đăng xuất', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileTab(preset: finflowPreset, onLogout: () async {}),
        ),
      ),
    );
    expect(find.text('Đăng ký / Đăng nhập'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsNothing);
  });

  Future<void> openProfile(WidgetTester tester, {String? avatar}) async {
    SharedPreferences.setMockInitialValues({
      'profile_full_name': 'Nguyễn An',
      'profile_phone': '0901234567',
      'profile_gmail': 'an@gmail.com',
      'profile_country': 'Việt Nam',
      if (avatar != null) 'profile_avatar': avatar,
    });
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
  }

  testWidgets('Sửa hồ sơ được lưu và cập nhật trên trang cá nhân', (
    tester,
  ) async {
    await openProfile(tester);
    await tester.tap(find.text('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Nguyễn Bình');
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Bình'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('profile_full_name'),
      'Nguyễn Bình',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cài đặt nhắc giờ được lưu và có thể tắt', (tester) async {
    await openProfile(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quản lý nhắc giờ trong ứng dụng'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString('settings_schedule'),
      contains('"enabled":true'),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString('settings_schedule'),
      contains('"enabled":false'),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Xóa dữ liệu cần xác nhận và chuyển về khách', (tester) async {
    await openProfile(tester);
    await tester.ensureVisible(find.text('Bảo mật và riêng tư'));
    await tester.tap(find.text('Bảo mật và riêng tư'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xóa dữ liệu cá nhân'));
    await tester.tap(find.text('Xóa dữ liệu cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString('profile_full_name'),
      'Nguyễn An',
    );
    await tester.tap(find.text('Xóa dữ liệu cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa dữ liệu'));
    await tester.pumpAndSettle();
    expect(find.text('Khách'), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ'), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getString('profile_full_name'),
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Bản nháp hỗ trợ được giữ khi mở lại màn hình', (tester) async {
    await openProfile(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trợ giúp và hỗ trợ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField),
      'Tôi cần hỗ trợ sử dụng camera.',
    );
    await tester.ensureVisible(find.text('Lưu bản nháp'));
    await tester.tap(find.text('Lưu bản nháp'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        'settings_support_draft',
      ),
      'Tôi cần hỗ trợ sử dụng camera.',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Trợ giúp và hỗ trợ'));
    await tester.tap(find.text('Trợ giúp và hỗ trợ'));
    await tester.pumpAndSettle();
    expect(find.text('Tôi cần hỗ trợ sử dụng camera.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Xem huyệt từ phác đồ mở đúng huyệt kèm nhãn nhận diện', (
    tester,
  ) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phác đồ điều trị bệnh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bồi bổ, thông khí huyết'));
    await tester.pumpAndSettle();
    expect(find.text('Xem huyệt'), findsWidgets);
    await tester.tap(find.text('Xem huyệt').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Huyệt 26'), findsWidgets);
    expect(find.textContaining('Giữa hai lông mày'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Khôi phục và xóa ảnh đại diện đã lưu', (tester) async {
    const avatar =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6XcAAAAASUVORK5CYII=';
    await openProfile(tester, avatar: avatar);
    expect(find.bySemanticsLabel('Ảnh đại diện'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ảnh đại diện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa ảnh đại diện'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Xóa ảnh'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('profile_avatar'),
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
