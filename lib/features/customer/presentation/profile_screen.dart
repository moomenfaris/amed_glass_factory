import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/font_scale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/font_scale_sheet.dart';
import '../../../core/widgets/theme_mode_sheet.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final fontScale = ref.watch(appFontScaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '-',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? '-'}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم المستخدم: ${user?.userId ?? user?.id ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الدور: ${user?.role ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Tile(
                  icon: Icons.language,
                  title: 'اللغة',
                  trailing: 'العربية',
                ),
                const Divider(height: 1, indent: 56),
                _Tile(
                  icon: Icons.dark_mode_outlined,
                  title: 'مظهر التطبيق',
                  trailing: themeMode == ThemeMode.dark ? 'داكن' : 'فاتح',
                  onTap: () => showThemeModeSheet(context),
                ),
                const Divider(height: 1, indent: 56),
                _Tile(
                  icon: Icons.format_size,
                  title: 'حجم الخط',
                  trailing: '${(fontScale * 100).round()}%',
                  onTap: () => showFontScaleSheet(context),
                ),
                const Divider(height: 1, indent: 56),
                _Tile(
                  icon: Icons.info_outline,
                  title: 'الإصدار',
                  trailing: '1.0.0',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  const _Tile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing == null
          ? null
          : Text(
              trailing!,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
      onTap: onTap,
    );
  }
}
