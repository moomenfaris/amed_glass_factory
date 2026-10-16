import 'package:flutter/material.dart';

import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/admin_drawer.dart';

class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const AppBarTitle('المخزن')),
      body: const Center(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          message: 'صفحة المخزن جاهزة للربط مع API',
        ),
      ),
    );
  }
}
