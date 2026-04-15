import 'package:flutter_test/flutter_test.dart';
import 'package:camreport/utils/utils.dart';

void main() {
  test('formatNumber formats using Indonesian locale', () {
    expect(Utils.formatNumber(12500), '12.500');
  });
}
