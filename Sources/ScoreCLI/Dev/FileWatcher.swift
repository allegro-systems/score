import Foundation

/// Watches directories for file changes using polling.
///
/// `FileWatcher` scans the specified directories at a regular interval and
/// invokes a callback when any file's modification date has changed.
/// A debounce window prevents rapid successive rebuilds.
final class FileWatcher: Sendable {

    /// The directories to watch.
    let directories: [String]

    /// The file extensions to monitor (e.g. `["swift"]`).
    let extensions: Set<String>

    /// The polling interval in seconds.
    let interval: TimeInterval

    /// The debounce window in seconds.
    let debounce: TimeInterval

    /// Creates a file watcher.
    ///
    /// - Parameters:
    ///   - directories: The directories to recursively scan.
    ///   - extensions: File extensions to watch. Defaults to Swift and resource files.
    ///   - interval: Polling interval in seconds. Defaults to 1.
    ///   - debounce: Debounce window in seconds. Defaults to 0.3.
    init(
        directories: [String],
        extensions: Set<String> = ["swift"],
        interval: TimeInterval = 1.0,
        debounce: TimeInterval = 0.3
    ) {
        self.directories = directories
        self.extensions = extensions
        self.interval = interval
        self.debounce = debounce
    }

    /// Starts watching for changes and calls the handler when files change.
    ///
    /// This method runs indefinitely until the task is cancelled.
    ///
    /// - Parameter onChange: Called with the list of changed file paths.
    func watch(onChange: @escaping @Sendable ([String]) -> Void) async {
        var snapshot = self.snapshot()

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { break }

            let current = self.snapshot()
            let changed = diff(old: snapshot, new: current)

            if !changed.isEmpty {
                try? await Task.sleep(for: .seconds(debounce))
                guard !Task.isCancelled else { break }

                let final = self.snapshot()
                let finalChanged = diff(old: snapshot, new: final)
                snapshot = final

                if !finalChanged.isEmpty {
                    onChange(finalChanged)
                }
            }
        }
    }

    /// Returns a snapshot of file modification times.
    ///
    /// Visible for testing via the internal access level.
    func snapshot() -> [String: Date] {
        var snapshot: [String: Date] = [:]
        let fm = FileManager.default

        for directory in directories {
            guard let enumerator = fm.enumerator(atPath: directory) else { continue }

            while let relativePath = enumerator.nextObject() as? String {
                let ext = (relativePath as NSString).pathExtension
                guard extensions.contains(ext) else { continue }

                let fullPath = "\(directory)/\(relativePath)"
                if let attrs = try? fm.attributesOfItem(atPath: fullPath),
                    let modified = attrs[.modificationDate] as? Date
                {
                    snapshot[fullPath] = modified
                }
            }
        }

        return snapshot
    }

    /// Returns paths that were added, removed, or modified between snapshots.
    func diff(old: [String: Date], new: [String: Date]) -> [String] {
        var changed: [String] = []

        for (path, date) in new {
            if let oldDate = old[path] {
                if date != oldDate {
                    changed.append(path)
                }
            } else {
                changed.append(path)
            }
        }

        for path in old.keys where new[path] == nil {
            changed.append(path)
        }

        return changed
    }
}
