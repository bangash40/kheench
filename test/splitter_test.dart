import 'package:flutter_test/flutter_test.dart';
import 'package:kheench/engine/splitter.dart';

Duration s(int seconds) => Duration(seconds: seconds);

void main() {
  test('3:42 in 60 s parts gives four parts, the last one shorter', () {
    final parts = splitRanges(Duration.zero, s(222), s(60));
    expect(parts, [
      (s(0), s(60)),
      (s(60), s(120)),
      (s(120), s(180)),
      (s(180), s(222)),
    ]);
  });

  test('trimmed start and end are respected', () {
    final parts = splitRanges(s(10), s(100), s(30));
    expect(parts.first.$1, s(10));
    expect(parts.last.$2, s(100));
    expect(parts, hasLength(3));
  });

  test('a last sliver under a second joins the previous part', () {
    final parts = splitRanges(
      Duration.zero,
      const Duration(milliseconds: 60500),
      s(30),
    );
    expect(parts, hasLength(2));
    expect(parts.last, (s(30), const Duration(milliseconds: 60500)));
  });

  test('a video shorter than one part stays whole', () {
    expect(splitRanges(Duration.zero, s(20), s(60)), [(s(0), s(20))]);
  });
}
