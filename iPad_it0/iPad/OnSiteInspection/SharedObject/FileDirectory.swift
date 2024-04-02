import Foundation

/// アプリで利用するディレクトリを管理
final class FileDirectory {

    /// root ディレクトリ
    private static let rootDirectory: URL = {
        guard let applicationSupportDirectoryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("failed to get applicationSupportDirectory")
        }
        return applicationSupportDirectoryURL
    }()

    /// モデル層のルートディレクトリ
    static var modelFileDirectory: URL {
        let rootDirectory = self.rootDirectory
        var modelFileDirectory = rootDirectory.appendingPathComponent("model", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: modelFileDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            fatalError("failed to model file directry. dir: \(modelFileDirectory), error: \(error.localizedDescription)")
        }

        // バックアップ対象外とする
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try modelFileDirectory.setResourceValues(resourceValues)
        } catch {
            fatalError("failed to exclude from backup \((modelFileDirectory)). error: \(error.localizedDescription)")
        }

        return modelFileDirectory
    }

    static var cachesDirectory: URL {
        guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("failed to get cachesDirectory")
        }

        return cachesDirectory
    }
}

