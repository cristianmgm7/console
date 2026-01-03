import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Handle custom URL scheme (carbonvoice://)
  override func application(_ application: NSApplication, open urls: [URL]) {
    print("🔗 AppDelegate received URLs: \(urls)")
    for url in urls {
      print("🔗 Processing URL: \(url.absoluteString), scheme: \(url.scheme ?? "nil")")
      // Handle carbonvoice:// URLs
      if url.scheme == "carbonvoice" {
        print("🔗 Valid carbonvoice:// URL detected, forwarding to Flutter")
        // Forward the URL to Flutter through a method channel
        if let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController {
          let methodChannel = FlutterMethodChannel(
            name: "com.carbonvoice.console/deep_linking",
            binaryMessenger: flutterViewController.engine.binaryMessenger
          )

          print("🔗 Invoking Flutter method channel with URL: \(url.absoluteString)")
          // Send the URL to Flutter
          methodChannel.invokeMethod("handleDeepLink", arguments: url.absoluteString) { result in
            if let error = result as? FlutterError {
              print("🔗 Error invoking method channel: \(error)")
            } else {
              print("🔗 Method channel invoked successfully, result: \(result ?? "nil")")
            }
          }
        } else {
          print("🔗 ERROR: FlutterViewController not found!")
        }
      } else {
        print("🔗 Ignoring URL with scheme: \(url.scheme ?? "nil")")
      }
    }
  }
}
