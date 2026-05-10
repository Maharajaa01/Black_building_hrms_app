import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bb_academy_hrms/app.dart';
import 'package:bb_academy_hrms/core/config/env.dart';

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://test.example.com
APP_ENV=dev
OFFICE_LATITUDE=0
OFFICE_LONGITUDE=0
OFFICE_RADIUS_METERS=200
''');
    Env.init();
  });

  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BBAcademyHRMSApp()),
    );
    await tester.pump();
  });
}
