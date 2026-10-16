import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/font_scale_provider.dart';

Future<void> showFontScaleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _FontScaleSheet(),
  );
}

class _FontScaleSheet extends ConsumerWidget {
  const _FontScaleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(appFontScaleProvider);
    final notifier = ref.read(appFontScaleProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'حجم الخط',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'تحكم بحجم الخط في جميع شاشات التطبيق.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Slider(
              min: kMinFontScale,
              max: kMaxFontScale,
              divisions: ((kMaxFontScale - kMinFontScale) * 20).round(),
              value: scale,
              label: '${(scale * 100).round()}%',
              onChanged: (value) => notifier.setScale(value),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => notifier.setScale(kMinFontScale),
                  child: const Text('صغير'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => notifier.reset(),
                  child: const Text('افتراضي'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => notifier.setScale(kMaxFontScale),
                  child: const Text('كبير'),
                ),
                const Spacer(),
                Text(
                  '${(scale * 100).round()}%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
