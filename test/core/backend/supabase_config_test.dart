import 'package:pandarin/core/backend/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase client configuration is valid for the connected project', () {
    expect(SupabaseConfig.projectRef, 'hrlahralknhijnkypjix');
    expect(SupabaseConfig.url, startsWith('https://'));
    expect(SupabaseConfig.publishableKey, startsWith('sb_publishable_'));
    expect(SupabaseConfig.isConfigured, isTrue);
  });
}
