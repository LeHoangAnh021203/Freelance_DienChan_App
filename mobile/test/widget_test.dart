import 'package:dien_chan_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App mở thẳng Mẫu A vào trang chủ', (tester) async {
    await tester.pumpWidget(const MultiDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Tra cứu'), findsWidgets);
    expect(find.text('Bản mẫu giao diện Diện Chẩn'), findsNothing);
    expect(find.text('Sử dụng app'), findsNothing);
  });
}
