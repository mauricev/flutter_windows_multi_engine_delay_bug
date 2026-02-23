import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.firstOrNull == 'multi_window') {
    final windowId = args[1];
    final argument = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    final mainWindowId = argument['main_window_id'] as String;
    final title = argument['title'] as String? ?? 'Sub Window';

    await windowManager.ensureInitialized();
    runApp(
      SubWindowApp(
        windowId: windowId,
        mainWindowId: mainWindowId,
        title: title,
      ),
    );
  } else {
    runApp(const MainApp());
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static const _channel = MethodChannel('com.example/quit');
  String? _mainWindowId;

  @override
  void initState() {
    super.initState();
    _initMethodHandler();
  }

  Future<void> _initMethodHandler() async {
    final c = await WindowController.fromCurrentEngine();
    _mainWindowId = c.windowId;
    c.setWindowMethodHandler((call) async {
      if (call.method == 'quit') {
        debugPrint('Main app received quit request. Quitting...');
        await _channel.invokeMethod('quit');
      }
    });

    _createSubWindow();
  }

  Future<void> _createSubWindow() async {
    if (_mainWindowId == null) return;

    final window1 = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'main_window_id': _mainWindowId,
          'title': 'Sub Window 1',
        }),
      ),
    );
    window1.show();

    final window2 = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode({
          'main_window_id': _mainWindowId,
          'title': 'Sub Window 2',
        }),
      ),
    );
    window2.show();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Main Window',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Main Window')),
        body: const Center(
          child: Text('This is the main window. Close the sub-window to quit.'),
        ),
      ),
    );
  }
}

class SubWindowApp extends StatefulWidget {
  final String windowId;
  final String mainWindowId;
  final String title;
  const SubWindowApp({
    super.key,
    required this.windowId,
    required this.mainWindowId,
    required this.title,
  });

  @override
  State<SubWindowApp> createState() => _SubWindowAppState();
}

class _SubWindowAppState extends State<SubWindowApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.setPreventClose(true);
    windowManager.addListener(this);

    windowManager.setTitle(widget.title);
    windowManager.setSize(const Size(800, 600));
    windowManager.center();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    debugPrint(
      'Sub-window close button clicked. Sending quit to main window...',
    );
    final c = WindowController.fromWindowId(widget.mainWindowId);
    await c.invokeMethod('quit', {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('This is ${widget.title}.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  debugPrint(
                    'Sub-window explicit close button clicked. Sending quit to main window...',
                  );
                  final c = WindowController.fromWindowId(widget.mainWindowId);
                  await c.invokeMethod('quit', {});
                },
                child: const Text('Close Box (Quit via PostQuitMessage)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
