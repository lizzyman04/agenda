import 'package:agenda/application/shared/locale/locale_cubit.dart';
import 'package:agenda/application/shared/locale/locale_state.dart';
import 'package:agenda/config/di/injection.dart';
import 'package:agenda/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Root application widget.
///
/// Provides [LocaleCubit] to the widget tree and drives [MaterialApp]
/// locale from cubit state (D-23).
///
/// Routing (go_router) is wired in Phase 5. For now, a placeholder
/// home widget is used.
class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>(
      create: (_) => getIt<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp(
            title: 'AGENDA',
            locale: localeState.locale,
            supportedLocales: LocaleCubit.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const Scaffold(
              body: Center(child: Text('AGENDA')),
            ),
          );
        },
      ),
    );
  }
}
