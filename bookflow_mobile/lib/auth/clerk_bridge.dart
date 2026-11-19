import 'package:clerk_flutter/clerk_flutter.dart';

// ALL Clerk SDK calls that talk to the (beta) clerk_flutter API live in this file.
// If a future clerk_flutter release renames something, this is the only file to fix.

/// Current Clerk session JWT, sent to the backend as `Authorization: Bearer <jwt>`.
Future<String?> clerkToken(ClerkAuthState auth) async {
  final token = await auth.sessionToken();
  return token.jwt;
}

Future<void> clerkSignOut(ClerkAuthState auth) => auth.signOut();
