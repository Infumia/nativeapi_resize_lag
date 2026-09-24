# nativeapi_resize_lag

Minimal Windows Flutter app for comparing window resize behavior across
`nativeapi` versions. It keeps the default counter app and adds a small
diagnostic panel. The same Dart code works with 0.2.4, 0.2.5, 0.2.7, and 0.3.0.

## Reproduce

Use Flutter 3.47 or newer on Windows. Close each run before changing versions.
For each version, run these commands from this directory, replacing `0.2.5`
in both places:

```powershell
flutter pub add nativeapi:0.2.5 cnativeapi:0.2.5
flutter clean
flutter run -d windows --release --dart-define=NATIVEAPI_VERSION=0.2.5
```

Drag the right or bottom window edge back and forth continuously. Compare the
window's motion against the pointer and watch the diagnostic panel. The panel
shows `WindowManager` resize event count, reported native size, Flutter
metrics event count, viewport size, and the latest and largest time between
events. The panel refreshes only four times per second so it adds little work
to each resize event. The counter button verifies that this is otherwise a
normal Flutter application.

## Observed in the original application

- `nativeapi 0.2.4`: resizing is smooth.
- `nativeapi 0.2.5`, `0.2.7`, and `0.3.0`: resizing stalls and the window
  moves in jumps; GPU usage spikes during the drag.
- Both debug and release builds show the lag.
- A clean rebuild after changing the package version is necessary for a fair
  comparison.
