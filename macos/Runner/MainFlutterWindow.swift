import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register all plugins for the newly spawned window engines
      RegisterGeneratedPlugins(registry: controller)
    }

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
