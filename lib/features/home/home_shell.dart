import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../admin/admin_screen.dart';
import '../auth/auth_controller.dart';
import '../menu/menu_screen.dart';
import '../orders/orders_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  late final bool _isAdmin;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    // HomeShell only exists while someone is signed in, so the role cannot change under it.
    _isAdmin = ref.read(authControllerProvider).valueOrNull?.isAdmin ?? false;
    _tabs = TabController(length: _isAdmin ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.shopName, style: figures(size: 22, weight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('ออกจากระบบ'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'เมนู'),
            const Tab(text: 'ออเดอร์ของฉัน'),
            if (_isAdmin) const Tab(text: 'หน้าร้าน'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          MenuScreen(onOrdered: () => _tabs.animateTo(1)),
          OrdersScreen(onGoMenu: () => _tabs.animateTo(0)),
          if (_isAdmin) const AdminScreen(),
        ],
      ),
    );
  }
}
