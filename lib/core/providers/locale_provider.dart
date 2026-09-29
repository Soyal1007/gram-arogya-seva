import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State provider for current app locale to trigger immediate UI rebuilds on language change.
final appLocaleProvider = StateProvider<Locale>((ref) => const Locale('en'));
