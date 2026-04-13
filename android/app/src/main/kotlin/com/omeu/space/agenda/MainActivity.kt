package com.omeu.space.agenda

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Main activity for AGENDA.
 *
 * Extends FlutterFragmentActivity (not FlutterActivity) because local_auth
 * requires a FragmentActivity context for biometric authentication (DATA-06).
 * Changing this after Phase 5 biometric code is written would require retesting
 * all fragment-dependent plugins. Do not revert to FlutterActivity.
 *
 * See: pub.dev/packages/local_auth README — "Android integration"
 * See: AGENDA CONTEXT.md D-19
 */
class MainActivity : FlutterFragmentActivity()
