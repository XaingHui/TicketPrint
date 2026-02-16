import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/viewmodels/settings_view_model.dart';

/// A wrapper around Scaffold that applies the current theme's background gradient.
class ThemedScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Key? scaffoldKey;
  final bool extendBodyBehindAppBar;

  const ThemedScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.scaffoldKey,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();
    final gradient = settingsVM.currentBackgroundGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white, // Fallback
        gradient: gradient,
      ),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent, // Make Scaffold transparent
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      ),
    );
  }
}
