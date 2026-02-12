import 'package:flutter/services.dart';

import 'alert_feedback.dart';

class SystemAlertFeedback implements AlertFeedback {
  @override
  Future<void> alarm() {
    return SystemSound.play(SystemSoundType.alert);
  }

  @override
  Future<void> vibrate() {
    return HapticFeedback.vibrate();
  }
}
