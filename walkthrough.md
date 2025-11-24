# Logger Implementation Walkthrough

I have added the `logger` package and configured it with `injectable` so you can use it throughout the app.

## Changes Made

1.  **Added Dependency**: Added `logger` to `pubspec.yaml`.
2.  **Registered Module**: Updated `lib/core/di/register_module.dart` to provide a `Logger` instance with `PrettyPrinter`.
3.  **Generated Code**: Ran `build_runner` to update dependency injection.

## How to Use

### 1. Injection in Classes (Recommended)

Simply add `Logger` to your class constructor. `injectable` will handle the rest.

```dart
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MyService {
  final Logger _logger;

  MyService(this._logger);

  void doSomething() {
    _logger.i('Doing something...');
    try {
      // ...
    } catch (e) {
      _logger.e('Error doing something', error: e);
    }
  }
}
```

### 2. Direct Access (If needed)

You can also access it directly via `getIt`, though constructor injection is preferred.

```dart
import 'package:logger/logger.dart';
import '../../core/di/injection.dart';

void someFunction() {
  final logger = getIt<Logger>();
  logger.d('Debug message');
}
```

## Configuration

The logger is configured in `lib/core/di/register_module.dart` with `PrettyPrinter`:

```dart
@lazySingleton
Logger get logger => Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);
```
