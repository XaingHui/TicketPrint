import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../application/viewmodels/settings_view_model.dart';

import '../../presentation/widgets/themed_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsViewModel>();
    _nameController.text = settings.merchantName;
    _phoneController.text = settings.merchantPhone;
    _addressController.text = settings.merchantAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();

    return ThemedScaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, '商户信息 (用于票据打印)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '店铺名称', hintText: '例如：我的小店'),
                    onChanged: (v) => settings.merchantName = v, // Real-time update? Or save button? Real-time is simpler for local prefs.
                  ),
                  const Gap(16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: '联系电话', hintText: '选填，留空不显示'),
                    onChanged: (v) => settings.merchantPhone = v,
                  ),
                  const Gap(16),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: '店铺地址', hintText: '选填，留空不显示'),
                    onChanged: (v) => settings.merchantAddress = v,
                  ),
                ],
              ),
            ),
            ),


          const Gap(24),
          _buildSectionHeader(context, '存储位置'),
          Card(
            child: ListTile(
              title: const Text('默认保存文件夹'),
              subtitle: Text(settings.savePath ?? '默认 (每次询问)'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (settings.savePath != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: '清除默认路径',
                      onPressed: () => settings.clearSavePath(),
                    ),
                  TextButton(
                    onPressed: () => settings.pickSavePath(),
                    child: const Text('修改'),
                  ),
                ],
              ),
            ),
          ),
          
          const Gap(24),
          _buildSectionHeader(context, '界面外观'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('主题风格'),
                  const Gap(12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: AppTheme.values.map((theme) {
                      final isSelected = settings.currentThemeType == theme;
                      return GestureDetector(
                        onTap: () => settings.setTheme(theme),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.3),
                                  width: isSelected ? 3 : 1,
                                ),
                                gradient: _getThemeGradientPreview(theme),
                                color: _getThemeColorPreview(theme),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                ],
                              ),
                              child: isSelected 
                                ? Icon(Icons.check, color: theme == AppTheme.dark ? Colors.white : Colors.black54)
                                : null,
                            ),
                            const Gap(8),
                            Text(
                              _getThemeName(theme),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const Gap(24),
                  const Divider(),
                  const Gap(16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('字体大小'),
                      Text('${(settings.fontScale * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    ],
                  ),
                  Slider(
                    value: settings.fontScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${(settings.fontScale * 100).toInt()}%',
                    onChanged: (value) {
                      settings.fontScale = value;
                    },
                  ),
                  Center(child: Text("拖动滑块调整全局字号", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient? _getThemeGradientPreview(AppTheme theme) {
    switch (theme) {
      case AppTheme.candyPink:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEE1E8), Color(0xFFDFF2FF)],
        );
      case AppTheme.skyBlue:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81D4FA), Color(0xFFFFFFFF)],
        );
      default:
        return null; // Pure white or dark
    }
  }

  Color? _getThemeColorPreview(AppTheme theme) {
    switch (theme) {
      case AppTheme.pureWhite:
        return Colors.white;
      case AppTheme.dark:
        return const Color(0xFF1E1E1E);
      default:
        return null; // Uses gradient
    }
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.pureWhite: return '纯净白';
      case AppTheme.candyPink: return '梦幻粉';
      case AppTheme.skyBlue: return '天空蓝';
      case AppTheme.dark: return '极夜黑';
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
