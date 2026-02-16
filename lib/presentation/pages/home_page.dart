import 'package:flutter/material.dart';
import 'product_management_page.dart';
import 'invoice_creation_page.dart';
import 'invoice_history_page.dart';
import 'settings_page.dart';
import '../widgets/themed_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const InvoiceCreationPage(),
    const ProductManagementPage(),
    const InvoiceHistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: '选品开票',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2),
            label: '商品管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: '开票记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

