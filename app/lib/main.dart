import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase is initialised lazily in bootstrapProvider rather than here, so a
  // cold start with no network still reaches a usable screen. Everything in
  // Mananu is local-first: a food diary that needs signal is a food diary people
  // abandon on the third day.
  runApp(const ProviderScope(child: MananuApp()));
}
