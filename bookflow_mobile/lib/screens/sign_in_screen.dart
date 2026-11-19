import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/motion.dart';

/// Opens the Clerk sign-in / sign-up flow. Used whenever a guest tries something
/// that needs an account. Once Clerk reports the user as signed in, every route
/// above the root is closed and the app swaps to the signed-in experience.
Future<void> requireSignIn(BuildContext context, {String? message}) async {
  await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => SignInScreen(message: message)));
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in or sign up')),
      body: SafeArea(
        child: ClerkAuthBuilder(
          signedInBuilder: (context, authState) => const _PopWhenSignedIn(),
          signedOutBuilder: (context, authState) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (message != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(message!, style: TextStyle(color: cs.onPrimaryContainer)),
                ),
              Row(
                children: [
                  Image.asset('assets/images/bookflow_mark.png', height: 44, filterQuality: FilterQuality.high),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to BookFlow',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text('Sign in to book, message and manage events.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const ClerkAuthentication(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopWhenSignedIn extends StatefulWidget {
  const _PopWhenSignedIn();
  @override
  State<_PopWhenSignedIn> createState() => _PopWhenSignedInState();
}

class _PopWhenSignedInState extends State<_PopWhenSignedIn> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}
