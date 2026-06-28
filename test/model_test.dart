import 'package:flutter_test/flutter_test.dart';
import 'package:unifind_flutter_app/models/report_model.dart';
import 'package:unifind_flutter_app/models/user_model.dart';

void main() {
  test('UserModel reads API values correctly', () {
    final user = UserModel.fromJson({
      'id': '7',
      'name': 'Test User',
      'email': 'test@example.com',
      'phone': '0123456789',
      'created_at': '2026-06-28 10:00:00',
    });

    expect(user.id, 7);
    expect(user.name, 'Test User');
    expect(user.email, 'test@example.com');
    expect(user.phone, '0123456789');
  });

  test('ReportModel reads API values correctly', () {
    final report = ReportModel.fromJson({
      'id': '3',
      'user_id': '7',
      'report_type': 'Lost',
      'title': 'Student Card',
      'category': 'Documents',
      'description': 'Blue student card holder',
      'location': 'Library',
      'report_date': '2026-06-28',
      'status': 'Unclaimed',
      'image': '',
      'created_at': '2026-06-28 10:00:00',
      'updated_at': '2026-06-28 10:00:00',
      'user_name': 'Test User',
      'user_email': 'test@example.com',
      'user_phone': '0123456789',
    });

    expect(report.id, 3);
    expect(report.userId, 7);
    expect(report.reportType, 'Lost');
    expect(report.status, 'Unclaimed');
    expect(report.userName, 'Test User');
  });
}
