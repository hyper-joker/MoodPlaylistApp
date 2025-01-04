//CallbackHandler.dart
import 'package:flutter/material.dart';
import './AuthURL.dart';

class CallbackHandler extends StatefulWidget {
  const CallbackHandler({Key? key}) : super(key: key);

  @override
  State<CallbackHandler> createState() => _CallbackHandlerState();
}

class _CallbackHandlerState extends State<CallbackHandler> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    await SpotifyAuth().handleCallback(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}