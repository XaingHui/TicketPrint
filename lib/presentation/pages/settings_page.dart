import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../application/viewmodels/settings_view_model.dart';

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

    return Scaffold(
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
              trailing: TextButton(
                onPressed: () => settings.pickSavePath(),
                child: const Text('修改'),
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
                  const Gap(8),
                  SegmentedButton<String>(
                    segments: const [
                       ButtonSegment(value: 'default', label: Text('标准蓝')),
                       ButtonSegment(value: 'gentle', label: Text('舒适淡雅')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      settings.themeMode = newSelection.first;
                    },
                  ),
                  
                  const Gap(24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('字体大小'),
                      Text('${(settings.fontScale * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  const Center(child: Text("拖动滑块调整全局字号")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
