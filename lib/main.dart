import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/group_provider.dart';
import 'modules/statement_import/providers/statement_provider.dart';
import 'screens/home_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'themes/app_themes.dart';

class AppTheme {
  // Brand Colors
  static const Color mountainMeadow = Color(0xFF10B981); // Bright Green (Mountain Meadow-ish)
  static const Color woodsmoke = Color(0xFF18181B); // Dark Text
  static const Color slateBackground = Color(0xFFF8FAFC); // Clean White/Slate
  static const Color darkBackground = Color(0xFF0F172A);
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mountainMeadow,
      primary: mountainMeadow,
      secondary: const Color(0xFF3B82F6),
      surface: slateBackground,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: slateBackground,
    
    // Global Sharp Shapes
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(color: mountainMeadow),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: mountainMeadow, width: 2)),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent, 
    ),
    textTheme: GoogleFonts.interTextTheme(),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mountainMeadow,
      primary: mountainMeadow,
      secondary: const Color(0xFF60A5FA),
      surface: Colors.black, // Pure black
      onSurface: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black, // Pure black
    
    // Global Sharp Shapes (Dark)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
     inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
    ),
     dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.black, // Pure black dialogs
    ),
     bottomSheetTheme: const BottomSheetThemeData(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
       backgroundColor: Colors.black, // Pure black bottom sheets
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF0A0A0A), // Very dark grey for cards
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Pure black app bar
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 2,
       surfaceTintColor: Colors.transparent,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  );
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for edge-to-edge and hide notch
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  
  // Enable edge-to-edge mode (hides notch area)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()..loadGroups()),
        ChangeNotifierProvider(
            create: (_) => TransactionProvider()..fetchTransactions()),
        ChangeNotifierProvider(create: (_) => StatementProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final brightness = MediaQuery.of(context).platformBrightness;
          final theme = AppThemes.getTheme(themeProvider.selectedTheme, brightness);
          
          return MaterialApp(
            title: 'Finance Tracker Pro',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
            ],
            theme: theme.copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: theme.copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.isLoading) {
                  return const SplashScreen();
                }
                return const PinLockScreen(child: HomeScreen());
              },
            ),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern logo placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.mountainMeadow,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mountainMeadow.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),

            // Loading indicator with modern styling
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppTheme.mountainMeadow,
                strokeWidth: 3,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Loading your finances...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
