import 'package:adminpanel/core/const/supabase_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  const SupabaseService._();

  static Future<void> initialize() async {
    debugPrint('[Supabase] Initializing...');

    try {
      await Supabase.initialize(
        url: SupabaseConstants.url,
        publishableKey: SupabaseConstants.publishableKey,
      );

      // Accessing the client verifies that Supabase initialized successfully.
      client;
      debugPrint('[Supabase] Connected Successfully');
    } catch (error, stackTrace) {
      debugPrint('[Supabase] Initialization Failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
