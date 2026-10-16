import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';

Future<void> showThemeModeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ThemeModeSheet(),
  );
}

class _ThemeModeSheet extends ConsumerWidget {
  const _ThemeModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    final notifier = ref.read(appThemeModeProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مظهر التطبيق',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر مظهر التطبيق لجميع مستخدمي التطبيق.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: mode,
              title: const Text('فاتح'),
              secondary: const Icon(Icons.light_mode_outlined),
              onChanged: (value) {
                if (value != null) notifier.setMode(value);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: mode,
              title: const Text('داكن'),
              secondary: const Icon(Icons.dark_mode_outlined),
              onChanged: (value) {
                if (value != null) notifier.setMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
