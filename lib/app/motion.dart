import 'package:flutter/widgets.dart';

/// Animation durations, scaled to zero when the system asks for no motion.
extension Motion on BuildContext {
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  Duration ms(int milliseconds) =>
      reduceMotion ? Duration.zero : Duration(milliseconds: milliseconds);
}
