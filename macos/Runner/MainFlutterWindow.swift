import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Agendity es una app de teléfono: en macOS (pruebas de integración y
    // desarrollo) la ventana abre con forma de teléfono, centrada.
    self.setContentSize(NSSize(width: 412, height: 880))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
