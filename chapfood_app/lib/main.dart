import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants/app_colors.dart';
import 'config/supabase_config.dart';
import 'screens/session_check_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ChapFoodApp());
}

class ChapFoodApp extends StatelessWidget {
  const ChapFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'ChapFood',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryRed,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.lightSurface,
              cardColor: AppColors.lightCard,
              dividerColor: AppColors.lightBorder,
              textTheme: const TextTheme(),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.getTextDark(context)),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.darkModeRed, // Jaune en mode sombre
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: AppColors.darkSurface,
              cardColor: AppColors.darkCard,
              dividerColor: AppColors.darkBorder,
              textTheme: ThemeData.dark().textTheme,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.textPrimary),
              ),
            ),
            home: const SessionCheckScreen(),
          );
        },
      ),
    );
  }
}

class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext context) create;
  final Widget child;

  const ChangeNotifierProvider({
    super.key,
    required this.create,
    required this.child,
  });

  @override
  State<ChangeNotifierProvider<T>> createState() =>
      _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.create(context);
  }

  @override
  Widget build(BuildContext context) {
    return InheritedProvider<T>(value: _value, child: widget.child);
  }
}

class Consumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const Consumer({super.key, required this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Provider.of<T>(context),
      builder: (context, child) =>
          builder(context, Provider.of<T>(context), child),
    );
  }
}

class Provider<T extends ChangeNotifier> {
  static T of<T extends ChangeNotifier>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedProvider<T>>()!
        .value;
  }
}

class InheritedProvider<T extends ChangeNotifier> extends InheritedWidget {
  final T value;

  const InheritedProvider({
    super.key,
    required this.value,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedProvider<T> oldWidget) {
    return value != oldWidget.value;
  }
}
