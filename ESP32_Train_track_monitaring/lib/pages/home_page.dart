import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loginpage/pages/arm_control_panel.dart';
import 'package:loginpage/pages/live_stream_view.dart';
import 'package:loginpage/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _liveStreamKey = GlobalKey<LiveStreamViewState>();
  bool _isStreaming = false;

  // ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    // Keep local button state in sync once the stream widget is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stream = _liveStreamKey.currentState;
      if (!mounted || stream == null) return;
      setState(() => _isStreaming = stream.isStreaming);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live stream area (embedded on Home page)
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LiveStreamView(
                key: _liveStreamKey,
                autoStart: false,
                height: 220,
              ),
            ),

            // Button below stream view; when clicked it starts the stream.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    final stream = _liveStreamKey.currentState;
                    if (stream == null) return;

                    if (_isStreaming) {
                      await stream.stop();
                    } else {
                      await stream.start();
                    }

                    if (!mounted) return;
                    setState(() {
                      _isStreaming = stream.isStreaming;
                    });
                  },
                  child: Text(_isStreaming ? 'Stop Live Stream' : 'Start Live Stream'),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Expanded(
              child: SingleChildScrollView(
                child: ArmControlPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
