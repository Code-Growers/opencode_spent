import Cocoa
import Darwin
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let bookmarkKey = "openspent.usageFolderBookmarks.v1"
  private var activeFolders: [String: URL] = [:]
  private var usageFolderChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: "openspent/local_usage_folders",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    usageFolderChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "homeDirectory":
        // NSHomeDirectory points to the app container when sandboxed.
        if let directory = getpwuid(getuid())?.pointee.pw_dir {
          result(String(cString: directory))
        } else { result(nil) }
      case "pickDirectory":
        self.pickUsageDirectory(result)
      case "restoreAccess":
        self.restoreUsageAccess(call.arguments as? [String] ?? [], result)
      case "releaseAccess":
        let arguments = call.arguments as? [String: [String]] ?? [:]
        self.releaseUsageAccess(arguments["directories"] ?? [], arguments["retained"] ?? [])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    super.awakeFromNib()
  }

  private func bookmarks() -> [String: Data] {
    return UserDefaults.standard.dictionary(forKey: bookmarkKey) as? [String: Data] ?? [:]
  }

  private func storeBookmark(_ url: URL, key: String) throws {
    let data = try url.bookmarkData(
      options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
      includingResourceValuesForKeys: nil, relativeTo: nil)
    var stored = bookmarks()
    stored[key] = data
    UserDefaults.standard.set(stored, forKey: bookmarkKey)
  }

  private func pickUsageDirectory(_ result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.beginSheetModal(for: self) { [weak self] response in
      guard response == .OK, let url = panel.url, let self = self else {
        result(nil); return
      }
      let path = url.standardizedFileURL.path
      let started = url.startAccessingSecurityScopedResource()
      do {
        try self.storeBookmark(url, key: path)
        if started {
          if self.activeFolders[path] == nil { self.activeFolders[path] = url }
          else { url.stopAccessingSecurityScopedResource() }
        }
        result(path)
      } catch {
        if started { url.stopAccessingSecurityScopedResource() }
        result(FlutterError(code: "folder_access", message: "Could not access local usage folder.", details: nil))
      }
    }
  }

  private func contains(_ root: String, _ path: String) -> Bool {
    return root == path || path.hasPrefix(root.hasSuffix("/") ? root : root + "/")
  }

  private func restoreUsageAccess(_ directories: [String], _ result: FlutterResult) {
    for (path, data) in bookmarks() where directories.contains(where: { contains(path, $0) }) {
      if activeFolders[path] != nil { continue }
      do {
        var stale = false
        let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope],
          relativeTo: nil, bookmarkDataIsStale: &stale)
        if url.startAccessingSecurityScopedResource() {
          activeFolders[path] = url
          if stale { try storeBookmark(url, key: path) }
        } else {
          result(FlutterError(code: "folder_access", message: "Reconnect the local usage folder.", details: nil))
          return
        }
      } catch {
        result(FlutterError(code: "folder_access", message: "Reconnect the local usage folder.", details: nil))
        return
      }
    }
    result(nil)
  }

  private func releaseUsageAccess(_ directories: [String], _ retained: [String]) {
    var stored = bookmarks()
    for path in Array(stored.keys) where directories.contains(where: { contains(path, $0) })
      && !retained.contains(where: { contains(path, $0) }) {
      activeFolders.removeValue(forKey: path)?.stopAccessingSecurityScopedResource()
      stored.removeValue(forKey: path)
    }
    UserDefaults.standard.set(stored, forKey: bookmarkKey)
  }

  deinit {
    for url in activeFolders.values { url.stopAccessingSecurityScopedResource() }
  }
}
