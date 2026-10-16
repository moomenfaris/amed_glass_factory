import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';

const double kMinFontScale = 0.85;
const double kDefaultFontScale = 1.0;
const double kMaxFontScale = 1.35;

final appFontScaleProvider = StateNotifierProvider<FontScaleNotifier, double>((
  ref,
) {
  return FontScaleNotifier();
});

class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(_readInitialScale());

  static double _readInitialScale() {
    final raw = LocalStorage.getString(LocalStorage.kFontScale);
    final parsed = double.tryParse(raw ?? '');
    if (parsed == null) return kDefaultFontScale;
    return parsed.clamp(kMinFontScale, kMaxFontScale).toDouble();
  }

  Future<void> setScale(double value) async {
    final next = value.clamp(kMinFontScale, kMaxFontScale).toDouble();
    state = next;
    await LocalStorage.setString(
      LocalStorage.kFontScale,
      next.toStringAsFixed(2),
    );
  }

  Future<void> reset() => setScale(kDefaultFontScale);
}
