import Foundation
import SwiftData

// MARK: - StoreMetadata

/// The completion state of data migrations within the shared persistent store.
@Model
final class StoreMetadata {
    /// The singleton metadata key.
    @Attribute(.unique) var key: String
    /// The most recent data migration committed successfully.
    var dataMigrationVersion: Int

    /// Creates metadata for a store that has not yet migrated its data.
    init(key: String = "store", dataMigrationVersion: Int = 0) {
        self.key = key
        self.dataMigrationVersion = dataMigrationVersion
    }
}
