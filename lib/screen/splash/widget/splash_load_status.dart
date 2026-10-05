import 'package:flutter/material.dart';

class SplashLoadStatus extends StatelessWidget {
  const SplashLoadStatus(
      {super.key, required this.error, required this.onRetry});
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const SizedBox(
          width: 32,
          height: 32,
          child:
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3));
    }
    return Column(
      children: [
        Text(
          error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Thử lại'),
        ),
      ],
    );
  }
}
