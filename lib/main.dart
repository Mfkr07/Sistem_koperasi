import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/colors.dart';
import 'providers/app_state_provider.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider()..initApp(),
      child: MaterialApp(
        title: 'TPK Koperasi Karet KUD Berkat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: CarbonColors.primary,
            secondary: CarbonColors.surface2,
            surface: CarbonColors.surface1,
            error: CarbonColors.error,
          ),
          textTheme: GoogleFonts.ibmPlexSansTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: CarbonColors.canvas,
          dividerColor: CarbonColors.hairline,
        ),
        home: const ShellScreen(),
      ),
    );
  }
}
