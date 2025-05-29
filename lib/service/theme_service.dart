import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // PADRÃO INICIAL É CLARO
  static const String _themePreferenceKey = 'app_theme_mode_preference_v3';

  ThemeMode get currentThemeMode => _themeMode;

  // Cores base para o FindIt
  static const Color findItPrimaryBlue = Color(0xFF1D8BC9);
  static const Color findItPrimaryDarkBlue = Color(0xFF01121B); // Para o fim do gradiente dos botões

  // Cores para o Tema Claro (seguindo o padrão que vínhamos usando)
  static const Color lightPageBackground = Color(0xFFEFEFEF);
  static const Color lightAppBarBackground = Colors.white; // Ou EFEFEF se quiser tudo igual
  static const Color lightCardBackground = Colors.white;

  // Cores para o Tema Escuro (tons de cinza e preto)
  static const Color darkPageBackground = Color(0xFF121212); // Um preto suave (Material Design dark)
  static const Color darkAppBarBackground = Color(0xFF1E1E1E); // Um cinza bem escuro para AppBars e Cards
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static Color darkThemeAccentBlue = Colors.blue[300]!; // Um azul mais claro para contraste no escuro

  ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      primaryColor: findItPrimaryBlue,
      scaffoldBackgroundColor: lightPageBackground,
      cardColor: lightCardBackground,
      dividerColor: Colors.grey[300],
      hintColor: Colors.grey[600], // Para hints em TextFields
      colorScheme: ColorScheme.fromSeed(
        seedColor: findItPrimaryBlue,
        brightness: Brightness.light,
        primary: findItPrimaryBlue,
        onPrimary: Colors.white, // Texto sobre botões primários (se não for gradiente)
        secondary: findItPrimaryBlue,
        onSecondary: Colors.white,
        surface: lightCardBackground, // Cor de superfície para cards, dialogs
        onSurface: Colors.black87,   // Texto sobre superfícies claras
        background: lightPageBackground,
        onBackground: Colors.black87,
        error: Colors.redAccent.shade400,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightAppBarBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black54), // Ícones como "voltar"
        actionsIconTheme: const IconThemeData(color: Colors.black54), // Ícones de ação
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: lightCardBackground,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: lightCardBackground,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        contentTextStyle: TextStyle(fontSize: 16, color: Colors.grey[700]),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: findItPrimaryBlue, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      // Tema para ElevatedButtons que NÃO usam o _buildGradientButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: findItPrimaryBlue, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Para fillColor ter efeito
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 18), // Ajustado para labelText
        prefixIconColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.focused)) return findItPrimaryBlue;
          return Colors.grey[600]!;
        }),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: findItPrimaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.redAccent.shade200, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(30),
           borderSide: BorderSide(color: Colors.redAccent.shade400, width: 2.0),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: findItPrimaryBlue,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: lightCardBackground,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4, color: Colors.black87),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ).apply(
        bodyColor: Colors.black87, // Cor padrão para a maioria dos textos
        displayColor: Colors.black54, // Cor para textos menos proeminentes
      ),
    );
  }

  // Tema Escuro (Tons de Cinza e Preto)
  ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: darkThemeAccentBlue, // Um azul claro para contraste
      scaffoldBackgroundColor: darkPageBackground,
      cardColor: darkCardBackground,
      dividerColor: Colors.grey[800],
      hintColor: Colors.grey[500],
      colorScheme: ColorScheme.fromSeed(
        seedColor: findItPrimaryBlue, // O seed ainda pode ser seu azul principal
        brightness: Brightness.dark,
        primary: darkThemeAccentBlue, 
        onPrimary: Colors.black, // Texto sobre botões primários (se não for gradiente)
        secondary: darkThemeAccentBlue,
        onSecondary: Colors.black,
        surface: darkCardBackground,
        onSurface: Colors.white70,
        background: darkPageBackground,
        onBackground: Colors.white70,
        error: Colors.redAccent.shade100,
        onError: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkAppBarBackground, // AppBar escuro
        elevation: 0, // Ou 1 para uma leve separação
        iconTheme: const IconThemeData(color: Colors.white70),
        actionsIconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 1, // Menos elevação no escuro pode ficar bom
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkCardBackground,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[200]),
        contentTextStyle: TextStyle(fontSize: 16, color: Colors.grey[300]),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: darkThemeAccentBlue, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      // Tema para ElevatedButtons que NÃO usam o _buildGradientButton no modo escuro
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: darkThemeAccentBlue, 
            foregroundColor: Colors.black, // Texto escuro para contraste com botão azul claro
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Para fillColor ter efeito no modo escuro
        fillColor: Colors.grey[800]?.withOpacity(0.3), // Fundo sutil para os inputs
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
        prefixIconColor: MaterialStateColor.resolveWith((states) {
          if (states.contains(MaterialState.focused)) return darkThemeAccentBlue;
          return Colors.grey[500]!;
        }),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: darkThemeAccentBlue, width: 1.5),
        ),
         errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(30),
           borderSide: BorderSide(color: Colors.redAccent.shade200, width: 2.0),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: darkThemeAccentBlue,
        unselectedItemColor: Colors.grey[500],
        backgroundColor: darkAppBarBackground, // Mesmo fundo do AppBar escuro
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4, color: Colors.white70),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ).apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white60,
      ),
    );
  }

  ThemeNotifier() {
    _loadThemePreference();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _saveThemePreference(mode);
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString = prefs.getString(_themePreferenceKey) ?? 'light'; // PADRÃO INICIAL É 'light'

    switch (themeModeString) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    await prefs.setString(_themePreferenceKey, themeModeString);
  }
}