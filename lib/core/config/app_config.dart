/// Application configuration constants.
///
/// NOTE: In accordance with PR 05 Security Guidelines, no third-party API keys
/// (such as Google Gemini) or secrets may reside in this client codebase.
/// All AI queries are securely routed via Supabase Edge Functions.
class AppConfigVer1Ne {
  AppConfigVer1Ne._();

  /// Name of the Supabase Edge Function gateway for Gemini AI.
  static const geminiGatewayFunction = 'gemini-ai-gateway';
}

@Deprecated('Use AppConfigVer1Ne')
typedef AppConfig = AppConfigVer1Ne;
