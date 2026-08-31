import 'package:crypto_market/Bloc/bloc/cryptobloc_bloc.dart';
import 'package:crypto_market/Bloc/bloc/cryptobloc_event.dart';
import 'package:crypto_market/crypto_api.dart';
import 'package:crypto_market/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const CryptoApp());
}

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CryptoBloc(CryptoApi())
        ..add(LoadWatchlist())
        ..add(LoadCoins())
        ..add(LoadTrending()),

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Crypto Research',

        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xff0B0F19),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff6C63FF),
            brightness: Brightness.dark,
            surface: const Color(0xff0B0F19),
          ),

          useMaterial3: true,

          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),

          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xff0B0F19),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xff101521),
            indicatorColor: const Color(0xff6C5CE7).withValues(alpha: 0.25),
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff8B7CFF),
                );
              }
              return GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xff8B7CFF));
              }
              return const IconThemeData(color: Colors.grey);
            }),
          ),

          chipTheme: ChipThemeData(
            selectedColor: const Color(0xff6C5CE7),
            backgroundColor: const Color(0xff171D2B),
            labelStyle: GoogleFonts.inter(fontSize: 13),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        home: const MainPage(),
      ),
    );
  }
}
