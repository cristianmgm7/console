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
    for url in urls {
      // Handle carbonvoice:// URLs
      if url.scheme == "carbonvoice" {
        // Forward the URL to Flutter through a method channel
        if let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController {
          let methodChannel = FlutterMethodChannel(
            name: "com.carbonvoice.console/deep_linking",
            binaryMessenger: flutterViewController.engine.binaryMessenger
          )

          // Send the URL to Flutter
          methodChannel.invokeMethod("handleDeepLink", arguments: url.absoluteString)
        }
      }
    }
  }
}
