import 'dart:async';
import 'package:flutter/material.dart';

enum SplashStatus {
  connecting,
  connected,
  completed,
}

class SplashController extends ChangeNotifier {
  double _progress = 0.05;
  SplashStatus _status = SplashStatus.connecting;
  Timer? _timer;

  double get progress => _progress;
  SplashStatus get status => _status;
  bool get isConnected => _status == SplashStatus.connected || _status == SplashStatus.completed;

  void setStaticProgress(double progress) {
    _progress = progress.clamp(0.0, 1.0);
    _status = _progress >= 1.0 ? SplashStatus.connected : SplashStatus.connecting;
    notifyListeners();
  }

  void startInitialization({required VoidCallback onCompleted}) {
    const totalSteps = 40;
    const interval = Duration(milliseconds: 40);
    int step = 0;

    _timer = Timer.periodic(interval, (timer) {
      step++;
      _progress = (step / totalSteps).clamp(0.05, 1.0);
      notifyListeners();

      if (step >= totalSteps) {
        timer.cancel();
        _status = SplashStatus.connected;
        notifyListeners();

        Future.delayed(const Duration(milliseconds: 650), () {
          _status = SplashStatus.completed;
          notifyListeners();
          onCompleted();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
