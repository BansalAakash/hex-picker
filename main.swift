import AppKit
import ScreenCaptureKit

final class App: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var swatch: NSView!
    var label: NSTextField!
    var statusItem: NSStatusItem!
    var content: SCShareableContent?
    var busy = false
    var hex = "#000000"

    func applicationDidFinishLaunching(_ n: Notification) {
        // Floating tooltip that follows the cursor
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 112, height: 30),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let bg = NSVisualEffectView(frame: panel.contentView!.bounds)
        bg.material = .hudWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 8
        bg.layer?.masksToBounds = true
        panel.contentView = bg

        swatch = NSView(frame: NSRect(x: 7, y: 7, width: 16, height: 16))
        swatch.wantsLayer = true
        swatch.layer?.cornerRadius = 4
        swatch.layer?.borderWidth = 1
        swatch.layer?.borderColor = NSColor.white.withAlphaComponent(0.5).cgColor
        bg.addSubview(swatch)

        label = NSTextField(labelWithString: hex)
        label.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        label.frame = NSRect(x: 30, y: 6, width: 80, height: 18)
        bg.addSubview(label)
        panel.orderFrontRegardless()

        // Menu bar: Copy + Quit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◉"
        let menu = NSMenu()
        menu.addItem(withTitle: "Copy Hex", action: #selector(copyHex), keyEquivalent: "c")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        refreshContent()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.refreshContent() }
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.tick() }
    }

    @objc func copyHex() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hex, forType: .string)
    }

    func refreshContent() {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { c, _ in
            DispatchQueue.main.async { self.content = c }
        }
    }

    func tick() {
        let m = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(m, $0.frame, false) }) else { return }

        // Position tooltip next to cursor, flipping near screen edges
        var o = NSPoint(x: m.x + 16, y: m.y - 16 - panel.frame.height)
        let f = screen.visibleFrame
        if o.x + panel.frame.width > f.maxX { o.x = m.x - 16 - panel.frame.width }
        if o.y < f.minY { o.y = m.y + 16 }
        panel.setFrameOrigin(o)

        guard !busy, let content,
              let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let display = content.displays.first(where: { $0.displayID == id }) else { return }

        // Convert to display-local, top-left-origin points
        let primaryH = NSScreen.screens[0].frame.height
        let b = CGDisplayBounds(id)
        let p = CGPoint(x: floor(m.x) - b.minX, y: floor(primaryH - m.y) - b.minY)

        let me = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
        let filter = SCContentFilter(display: display, excludingApplications: me, exceptingWindows: [])
        let cfg = SCStreamConfiguration()
        cfg.sourceRect = CGRect(x: p.x, y: p.y, width: 1, height: 1)
        let scale = Int(screen.backingScaleFactor)
        cfg.width = scale
        cfg.height = scale
        cfg.showsCursor = false
        cfg.colorSpaceName = CGColorSpace.sRGB

        busy = true
        SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg) { img, _ in
            let rgb = img.flatMap(Self.pixel)
            DispatchQueue.main.async {
                self.busy = false
                guard let (r, g, b) = rgb else { return }
                self.hex = String(format: "#%02X%02X%02X", r, g, b)
                self.label.stringValue = self.hex
                self.swatch.layer?.backgroundColor = CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
            }
        }
    }

    // Read the top-left pixel as sRGB
    static func pixel(_ img: CGImage) -> (Int, Int, Int)? {
        var px = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(img, in: CGRect(x: 0, y: 1 - img.height, width: img.width, height: img.height))
        return (Int(px[0]), Int(px[1]), Int(px[2]))
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
