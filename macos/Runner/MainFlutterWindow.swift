import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(name: "com.example/quit", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "quit" {
        NSApplication.shared.terminate(nil)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    super.awakeFromNib()
  }
}
