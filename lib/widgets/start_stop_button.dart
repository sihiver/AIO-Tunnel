import 'package:flutter/material.dart';

enum ConnectionState {
  stopped,
  connecting,
  connected
}

// Tambahkan fungsi ini di luar kelas StartStopButton
Color getButtonColor(ConnectionState state) {
  switch (state) {
    case ConnectionState.stopped:
      return Colors.green;
    case ConnectionState.connecting:
      return Colors.orange;
    case ConnectionState.connected:
      return Colors.red;
  }
}

class StartStopButton extends StatelessWidget {
  final ConnectionState connectionState;
  final VoidCallback onPressed;

  const StartStopButton({
    super.key,
    required this.connectionState,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText;
    Color buttonColor;
    Color textColor;
    double elevation;

    switch (connectionState) {
      case ConnectionState.stopped:
        buttonText = 'Start';
        buttonColor = Colors.green;
        textColor = Colors.white;
        elevation = 4;
        break;
      case ConnectionState.connecting:
        buttonText = 'Connecting...';
        buttonColor = Colors.orange;
        textColor = Colors.white;
        elevation = 2;
        break;
      case ConnectionState.connected:
        buttonText = 'Stop';
        buttonColor = Colors.red;
        textColor = Colors.white;
        elevation = 4;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ElevatedButton(
          onPressed: connectionState == ConnectionState.connecting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            elevation: elevation,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Text(
              buttonText,
              key: ValueKey<String>(buttonText),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
