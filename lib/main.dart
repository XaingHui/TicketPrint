import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_locator.dart';
import 'application/viewmodels/invoice_view_model.dart';
import 'application/viewmodels/invoice_history_view_model.dart';

import 'application/viewmodels/product_view_model.dart';
import 'application/viewmodels/settings_view_model.dart';
import 'presentation/pages/home_page.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入
  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<InvoiceViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<ProductViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<SettingsViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<InvoiceHistoryViewModel>()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsViewModel, child) {
          return MaterialApp(
            title: '票据打印',
            theme: settingsViewModel.currentTheme,
            home: const HomePage(),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'), // Chinese
            ],
          );
        },
      ),
    );
  }
}


class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ticket App Framework")),
      body: const Center(
        child: Text("框架搭建完成\n请运行 dart run build_runner build 生成代码"),
      ),
    );
  }
}
