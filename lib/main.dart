import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NativeAPI resize lag',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
    home: const MyHomePage(title: 'NativeAPI resize lag'),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static const packageVersion = String.fromEnvironment(
    'NATIVEAPI_VERSION',
    defaultValue: 'see pubspec.yaml',
  );

  final Stopwatch _clock = Stopwatch()..start();
  Timer? _displayTimer;
  int? _windowId;
  nativeapi.ListenerId? _listenerId;
  int _counter = 0;
  int _nativeResizeCount = 0;
  int _flutterMetricsCount = 0;
  int? _lastNativeAtMs;
  int? _lastFlutterAtMs;
  int? _nativeGapMs;
  int? _flutterGapMs;
  int _maxNativeGapMs = 0;
  int _maxFlutterGapMs = 0;
  String _nativeSize = 'waiting for resize';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Keep instrumentation out of the resize callback's paint path.
    _displayTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (mounted) setState(() {});
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final window = nativeapi.WindowManager.instance.getCurrent();
      _windowId = window?.id;
      window?.dispose();
      _listenerId = nativeapi.WindowManager.instance.addListener((event) {
        if (event is! nativeapi.WindowResizedEvent ||
            event.windowId != _windowId) {
          return;
        }
        final now = _clock.elapsedMilliseconds;
        if (_lastNativeAtMs != null) {
          _nativeGapMs = now - _lastNativeAtMs!;
          if (_nativeGapMs! > _maxNativeGapMs) {
            _maxNativeGapMs = _nativeGapMs!;
          }
        }
        _lastNativeAtMs = now;
        _nativeResizeCount++;
        _nativeSize =
            '${event.newSize.width.toStringAsFixed(0)} × '
            '${event.newSize.height.toStringAsFixed(0)}';
      });
    });
  }

  @override
  void didChangeMetrics() {
    final now = _clock.elapsedMilliseconds;
    if (_lastFlutterAtMs != null) {
      _flutterGapMs = now - _lastFlutterAtMs!;
      if (_flutterGapMs! > _maxFlutterGapMs) {
        _maxFlutterGapMs = _flutterGapMs!;
      }
    }
    _lastFlutterAtMs = now;
    _flutterMetricsCount++;
  }

  @override
  void dispose() {
    if (_listenerId != null) {
      nativeapi.WindowManager.instance.removeListener(_listenerId!);
    }
    _displayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('nativeapi: $packageVersion'),
            Text('WindowManager current window: ${_windowId ?? 'none'}'),
            Text('Native resize events: $_nativeResizeCount'),
            Text('Native size: $_nativeSize'),
            Text(
              'Native event gap: ${_nativeGapMs ?? '-'} ms '
              '(max: $_maxNativeGapMs ms)',
            ),
            const SizedBox(height: 16),
            Text('Flutter metrics events: $_flutterMetricsCount'),
            Text(
              'Flutter viewport: ${viewport.width.toStringAsFixed(0)} × '
              '${viewport.height.toStringAsFixed(0)}',
            ),
            Text(
              'Flutter event gap: ${_flutterGapMs ?? '-'} ms '
              '(max: $_maxFlutterGapMs ms)',
            ),
            const SizedBox(height: 24),
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
