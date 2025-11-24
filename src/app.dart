import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';

class MyGateApp extends StatelessWidget {
  const MyGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'MyGate',
            theme: AppTheme.lightTheme,
            initialRoute: Routes.roleSelection,
            routes: Routes.getRoutes(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
